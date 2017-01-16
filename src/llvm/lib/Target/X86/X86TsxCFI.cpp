#include "X86.h"
#include "X86Subtarget.h"
#include "X86InstrBuilder.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Support/raw_ostream.h"
#include "string.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/ToolOutputFile.h"

using namespace llvm;

// Command line options. One specifies the mode, the other if we are building statically.
static cl::opt<std::string> TsxCfiMode("tsx-cfi", cl::desc("Tsx CFI Mode"),
				       cl::value_desc("Mode of operation: rtm or hle"), cl::init(""));        

static cl::opt<bool>TsxCfiStatic("tsx-cfi-static", cl::Hidden, cl::desc("Disable nop emits for static linking"),
				     cl::init(false));  

// RTM
#define NEEDS_XBEGIN  0x0001
#define NEEDS_XEND    0x0002
#define DIRECT_CALL   0x0004
#define INDIRECT_CALL_REG 0x0008 
#define INDIRECT_CALL_MEM 0x0010
#define TAIL_CALL_REG 0x0020
#define TAIL_CALL_MEM 0x0040 
#define IS_RET        0x0080

// HLE
#define NEEDS_XACQUIRE NEEDS_XBEGIN
#define NEEDS_XRELEASE NEEDS_XEND



namespace {
  class TsxCfiRTM : public MachineFunctionPass {
  public:
    TsxCfiRTM() : MachineFunctionPass(ID) {}
    bool runOnMachineFunction(MachineFunction &MF) override;
    const char *getPassName() const override {return "TSX Control Flow Integrity with Restricted Transactional Memory";}
    static char ID;
  private:
    MachineBasicBlock* createFallbackMemBlock(MachineInstr *MI, MachineBasicBlock *jmpTargetMBB, MachineBasicBlock *callTargetMBB);
    void insertXBegin(MachineInstr *MI, MachineBasicBlock *MBB);
    void insertXEnd(MachineInstr *MI, MachineBasicBlock *MBB);
    const TargetInstrInfo *TII;
  };
  char TsxCfiRTM::ID = 0;
}

FunctionPass *llvm::createTsxCfiRTM() {
  return new TsxCfiRTM();
}

int getOpcodeProp(unsigned int Opcode){
  switch(Opcode){
    
  // case X86::CALL16r:
  // case X86::CALL16m:
  // case X86::CALL32r:
  // case X86::CALL32m:
  case X86::CALL64r:
    return NEEDS_XBEGIN | NEEDS_XEND | INDIRECT_CALL_REG;
  case X86::CALL64m:
    return NEEDS_XBEGIN | NEEDS_XEND | INDIRECT_CALL_MEM;
    
  case X86::CALLpcrel16:
  case X86::CALLpcrel32:
  case X86::CALL64pcrel32:
    return NEEDS_XEND | DIRECT_CALL ;
    
  case X86::RETL:
  case X86::RETQ:
  case X86::RETW:
    return NEEDS_XBEGIN | IS_RET;

  case X86::TAILJMPr64:
    return NEEDS_XBEGIN | TAIL_CALL_REG;
  case X86::TAILJMPm64:
    return NEEDS_XBEGIN | TAIL_CALL_MEM;
  case X86::TAILJMPd64:
    return DIRECT_CALL;
    
  default:
    return 0;
  }
}

void emitNop(MachineInstr *MI, MachineBasicBlock *MBB, int count){
  MachineInstrBuilder MIB;
  const TargetInstrInfo *TII = MBB->getParent()->getSubtarget().getInstrInfo();
  while(count>0){
    MIB = BuildMI(*MBB, MI, MI->getDebugLoc(), TII->get(X86::NOOP));
    count--;
  }
}

bool contains(std::vector<llvm::MachineInstr*> v, MachineInstr* mbb){
  return std::find(std::begin(v), std::end(v), mbb) != std::end(v);
}

// 0:  ff d0                   call   rax
// 2:  41 ff d7                call   r15
// 5:  ff 10                   call   QWORD PTR [rax]
// 7:  41 ff 13                call   QWORD PTR [r11]
// a:  ff 50 04                call   QWORD PTR [rax+0x4]
// d:  41 ff 53 04             call   QWORD PTR [r11+0x4]
// 11: ff 14 08                call   QWORD PTR [rax+rcx*1]
// 14: ff 54 c8 18             call   QWORD PTR [rax+rcx*8+0x18]
// 18: 42 ff 54 21 18          call   QWORD PTR [rcx+r12*1+0x18]
// 1d: 43 ff 54 23 18          call   QWORD PTR [r11+r12*1+0x18]

void TsxCfiRTM::insertXEnd(MachineInstr *MI, MachineBasicBlock *MBB){
  MachineInstrBuilder MIB;    
  MIB = BuildMI(*MBB, MI, MBB->begin()->getDebugLoc(), TII->get(X86::XEND));
}

MachineBasicBlock* createMBBandInsertAfter(MachineBasicBlock *InsertPoint){
  MachineFunction *MF = InsertPoint->getParent();
  MachineBasicBlock *newMBB = MF->CreateMachineBasicBlock();
  MF->insert(InsertPoint->getIterator(), newMBB);
  newMBB->moveAfter(InsertPoint);
  InsertPoint->addSuccessor(newMBB);
  newMBB->transferSuccessorsAndUpdatePHIs(InsertPoint);
  return newMBB;
}

MachineBasicBlock* TsxCfiRTM::createFallbackMemBlock(MachineInstr *MI, MachineBasicBlock *jmpTargetMBBxBegin, MachineBasicBlock *jmpTargetMBBcall){
  MachineBasicBlock *MBB = MI->getParent();
  MachineFunction *MF = MBB->getParent();
  MachineInstrBuilder MIB;
  MachineBasicBlock *newMBB = createMBBandInsertAfter(&*std::prev(MF->end()));
  MachineBasicBlock *gotMBB = createMBBandInsertAfter(newMBB);
  MachineBasicBlock *validMBB = createMBBandInsertAfter(gotMBB);
  MachineBasicBlock *anotherMBB = createMBBandInsertAfter(validMBB);
  DebugLoc DL = MI->getDebugLoc();
  newMBB->addSuccessor(jmpTargetMBBxBegin);  
  newMBB->addSuccessor(gotMBB);
  gotMBB->addSuccessor(validMBB);
  validMBB->addSuccessor(anotherMBB);    
  MachineInstr *castMIB;
  MachineInstr *FirstInst = newMBB->begin();

  // Push R10, restore RAX
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::PUSH64r), X86::R10);
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::MOV64rr), X86::RAX).addReg(X86::R11);

  // ## Check if [mem] == xend ##

  // mov rax, target
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::MOV64rm), X86::RAX);
  for (const MachineOperand &MO : MI->operands()) { // Copy all the operands
    MIB.addOperand(MO);
  }

  castMIB=MIB;
  if(castMIB->getOperand(1).getReg()==X86::RSP) castMIB->getOperand(4).setImm(castMIB->getOperand(4).getImm()+8);
  // mov rax, [rax]
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::MOV64rm), X86::RAX);
  addRegOffset(MIB, X86::RAX, false, 0);

  // and rax, 0xffffff
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::AND64ri32), X86::RAX).addImm(0xffffff);

  // cmp rax, 0xd5010f
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::CMP64ri32), X86::RAX).addImm(0xd5010f);

  // jne next_check
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::JNE_1)).addMBB(gotMBB);

  // ## Otherwise, add 3 and jump ##
  // Restore RAX
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::MOV64rr), X86::RAX).addReg(X86::R11);
  // mov r11, target
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::MOV64rm), X86::R11);
  for (const MachineOperand &MO : MI->operands()) { // Copy all the operands
    MIB.addOperand(MO);
  }
  castMIB=MIB;
  if(castMIB->getOperand(1).getReg()==X86::RSP) castMIB->getOperand(4).setImm(castMIB->getOperand(4).getImm()+8);

  // add r11, 3
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::ADD64ri8), X86::R11).addReg(X86::R11).addImm(3);  
  // jmp target
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::JMP64r)).addReg(X86::R11);
  

  // ## Check if got unresolved ##
  FirstInst = gotMBB->begin();
  // mov rax, r11 ; restore rax
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::MOV64rr), X86::RAX).addReg(X86::R11);

  // mov rax, target
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::MOV64rm), X86::RAX);
  for (const MachineOperand &MO : MI->operands()) { // Copy all the operands
    MIB.addOperand(MO);
  }
  castMIB=MIB;
  if(castMIB->getOperand(1).getReg()==X86::RSP) castMIB->getOperand(4).setImm(castMIB->getOperand(4).getImm()+8);

  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::MOV64rr), X86::R10).addReg(X86::RAX);
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::ADD64ri32), X86::R10).addReg(X86::R10).addImm(6);
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::MOV32rm), X86::EAX);
  addRegOffset(MIB, X86::RAX, false, 2);
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::ADD64rr), X86::RAX).addReg(X86::RAX).addReg(X86::R10);
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::MOV64rm), X86::EAX);
  addRegOffset(MIB, X86::RAX, false, 0);

  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::CMP64rr), X86::RAX).addReg(X86::R10);
  // jne next_check
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::JNE_1)).addMBB(validMBB);
  // ## Otherwise, jump ##
  // Restore RAX
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::MOV64rr), X86::RAX).addReg(X86::R11);
  // jmp target
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::JMP64m));
  for (const MachineOperand &MO : MI->operands()) { // Copy all the operands
    MIB.addOperand(MO);
  }

  // #### VALID MBB #####
  FirstInst = validMBB->begin();

  // Save RAX in r10 (now rax points to the resolved function)
  MIB = BuildMI(*validMBB, FirstInst, DL, TII->get(X86::MOV64rr), X86::R10).addReg(X86::RAX);

  // ## Check if got resolved ## 
  MIB = BuildMI(*validMBB, FirstInst, DL, TII->get(X86::MOV64rm), X86::RAX);
  if(TsxCfiStatic){ // if RELRO we check the resolved function -3 points to xend
    // add r11, 3
    addRegOffset(MIB, X86::RAX, false, -3);
  }
  else{
    addRegOffset(MIB, X86::RAX, false, 0);
  }

  // and rax, 0xffffff
  MIB = BuildMI(*validMBB, FirstInst, DL, TII->get(X86::AND64ri32), X86::RAX).addImm(0xffffff);
  MIB = BuildMI(*validMBB, FirstInst, DL, TII->get(X86::CMP64ri32), X86::RAX).addImm(0xd5010f);

  // jne violation
  MIB = BuildMI(*validMBB, FirstInst, DL, TII->get(X86::JNE_1)).addExternalSymbol("__tsx_cfi_violation");

  // // Restore RAX
  MIB = BuildMI(*validMBB, FirstInst, DL, TII->get(X86::MOV64rr), X86::RAX).addReg(X86::R11);

  // // mov r11, target
  MIB = BuildMI(*validMBB, FirstInst, DL, TII->get(X86::MOV64rr), X86::R11).addReg(X86::R10);
  if(!TsxCfiStatic){ // if not RELRO we add 3 so we skip the xend
    // add r11, 3
    MIB = BuildMI(*validMBB, FirstInst, DL, TII->get(X86::ADD64ri8), X86::R11).addReg(X86::R11).addImm(3);
  }
  // jmp target
  MIB = BuildMI(*validMBB, FirstInst, DL, TII->get(X86::JMP64r)).addReg(X86::R11);
  return newMBB;
}

const char *RegisterToString(unsigned int Reg){
  switch(Reg){
    case X86::RAX:
      return "rax";
    case X86::RBX:
      return "rbx";
    case X86::RCX:
      return "rcx";
    case X86::RDX:
      return "rdx";
    case X86::RSI:
      return "rsi";
    case X86::RDI:
      return "rdi";
    case X86::RBP:
      return "rbp";
    case X86::RSP:
      return "rsp";
    case X86::R8:
      return "r8";
    case X86::R9:
      return "r9";
    case X86::R12:
      return "r12";
    case X86::R13:
      return "r13";
    case X86::R14:
      return "r14";
    case X86::R15:
      return "r15";
    default:
      assert(false && "Can not convert register to string.");
      return 0;
  }
}
void TsxCfiRTM::insertXBegin(MachineInstr *MI, MachineBasicBlock *MBB){
  MachineFunction *MF = MBB->getParent();
  MachineInstrBuilder MIB;
  char symbol[50] = {0};
  MachineBasicBlock *fbMBB;
  int RetValReg = X86::R11; // Where we save eax
  int RipReg = X86::R10;    // Where we put the address of the instruction after the call
  int prop = getOpcodeProp(MI->getOpcode());
  DebugLoc DL = MI->getDebugLoc();
  
  MIB = BuildMI(*MBB, MI, DL, TII->get(X86::MOV64rr), RetValReg).addReg(X86::RAX);

  if(prop & IS_RET){
    strcpy(symbol,"__tsx_cfi_fb_rtm_ret");
  }
  else if(prop & INDIRECT_CALL_REG){
    strcpy(symbol,"__tsx_cfi_fb_rtm_call_");    
    strcat(symbol,RegisterToString(MI->getOperand(0).getReg()));
  }
  else if(prop & TAIL_CALL_REG){
    strcpy(symbol,"__tsx_cfi_fb_rtm_jmp_");
    strcat(symbol,RegisterToString(MI->getOperand(0).getReg()));
  }
  else if(prop & (INDIRECT_CALL_MEM | TAIL_CALL_MEM)){
    int FirstReg = MI->getOperand(0).getReg();
    int SecondReg = MI->getOperand(2).getReg();
    // errs() << "MI: " << *MI;
    assert(FirstReg != X86::R11 && SecondReg != X86::R11 && "Snap, indirect call with R10 or R11");

    // Here we splice MBB where the call is. So the callMBB can be the target of the fallback-path
    MachineBasicBlock *callMBB = MF->CreateMachineBasicBlock();
    MF->insert(MBB->getIterator(), callMBB);
    callMBB->moveAfter(MBB);
    MBB->addSuccessor(callMBB);
    callMBB->splice(callMBB->begin(), MBB, MI, MBB->end());

    MachineBasicBlock *newMBB = MF->CreateMachineBasicBlock();
    MF->insert(callMBB->getIterator(), newMBB);
    callMBB->moveAfter(newMBB);
    newMBB->addSuccessor(callMBB);

    // Here we create a newMBB (in between callMBB and MBB) where there will be the xbegin.
    fbMBB = createFallbackMemBlock(MI, newMBB, callMBB);
    MBB = newMBB;
    MI = MBB->begin();
  }

  // lea ripReg, [%rip]0
  if((prop & (INDIRECT_CALL_REG | INDIRECT_CALL_MEM) )){
    MIB = BuildMI(*MBB, MI, DL, TII->get(X86::LEA64r), RipReg);
    addRegOffset(MIB, X86::RIP, false, 0);
  }
  
  MIB = BuildMI(*MBB, MI, DL, TII->get(X86::XBEGIN_4));
  if(strcmp(symbol,"") != 0){
    char *dupsymbol=strdup(symbol);
    MIB.addExternalSymbol(dupsymbol);
  }
  else{
    MIB.addMBB(fbMBB);
  }
  // MF->dump();
}



bool TsxCfiRTM::runOnMachineFunction(MachineFunction &MF) {
  MachineFunction::iterator MBB, MBBE;
  MachineBasicBlock::iterator MBBI, MBBIE;
  MachineInstr *MI;
  int OpcodeProp;
  TII = MF.getSubtarget().getInstrInfo();
  MachineInstrBuilder MIB;    

  MachineBasicBlock *FirstBB = (MachineBasicBlock*)MF.begin();

  // Skipping empty MBBs..
  while(FirstBB->empty()){
    FirstBB = std::next(FirstBB);
  }

  // Don't instrument dummy.
  if(strcmp(MF.getName().str().c_str(),"dummy") == 0){
    errs() << "Not instrumenting dummy!\n";
    return false;;
  }
  
  // Instrumenting the entry point of every function with xend
  MachineInstr *FirstInstr = (MachineInstr*)FirstBB->begin();
  insertXEnd(FirstInstr,FirstBB);

  for (MBB = MF.begin(), MBBE = MF.end(); MBB != MBBE; ++MBB){
    // errs() << *MBB;
    for (MBBI = MBB->begin(), MBBIE = MBB->end(); MBBI != MBBIE; ++MBBI) {
      // errs() << "MI: " << *MBBI;
      MI = MBBI;
      OpcodeProp = getOpcodeProp(MI->getOpcode());

      if(OpcodeProp & NEEDS_XEND)
        insertXEnd(std::next(MBBI), &*MBB);
       
      if(OpcodeProp & NEEDS_XBEGIN){
        insertXBegin(MBBI, &*MBB);
        MBB = MI->getParent()->getIterator();
        MBBIE = MBB->end();
        MBBE = MF.end();
      }
      if(OpcodeProp & DIRECT_CALL){
        if(!TsxCfiStatic)
          emitNop(MI,&*MBB,16); // Leave some space for mov + xbegin.
        MI->getOperand(0).setOffset(3);
      }
    }
  }

  return true;
}

namespace {
  class TsxCfiHLE : public MachineFunctionPass {
  public:
    TsxCfiHLE() : MachineFunctionPass(ID) {}
    bool runOnMachineFunction(MachineFunction &MF) override;
    const char *getPassName() const override {return "TSX Control Flow Integrity with Hardware Lock Elision";}
    static char ID;
  private:
    void insertXAcquire(MachineInstr *MI, MachineBasicBlock *MBB, int StackPointerOffset);
    void insertXRelease(MachineInstr *MI, MachineBasicBlock *MBB, int StackPointerOffset);
    MachineBasicBlock *createFallbackMemBlock(MachineInstr *MI, MachineBasicBlock *jmpTargetMBB);
    const TargetInstrInfo *TII;
  };
  char TsxCfiHLE::ID = 0;
}

FunctionPass *llvm::createTsxCfiHLE() {
  return new TsxCfiHLE();
}

// shl    r11, 0x28
// mov    r10, 0x
// add    r11, r10
// cmp    r11, [r14]
// jne    __tsx_cfi_violation
// jmp r14

MachineBasicBlock* TsxCfiHLE::createFallbackMemBlock(MachineInstr *MI, MachineBasicBlock *jmpTargetMBB){
  MachineBasicBlock *MBB = MI->getParent();
  MachineFunction *MF = MBB->getParent();
  MachineInstrBuilder MIB;
  MachineBasicBlock *newMBB = createMBBandInsertAfter(&*std::prev(MF->end()));
  MachineBasicBlock *gotMBB = createMBBandInsertAfter(newMBB);
  MachineBasicBlock *validMBB = createMBBandInsertAfter(gotMBB);
  DebugLoc DL = MI->getDebugLoc();

  newMBB->addSuccessor(jmpTargetMBB);  
  newMBB->addSuccessor(gotMBB);
  gotMBB->addSuccessor(validMBB);    

  MachineInstr *FirstInst = newMBB->begin();

  // R11 <- label, R10 scratch register.
  // Load in R11 what we expect to find at the target site (xrelease label)
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::SHL64ri), X86::R11).addReg(X86::R11).addImm(0x20);
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::MOV32ri), X86::R10).addImm(0xf8246c81);
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::ADD64rr), X86::R11).addReg(X86::R11).addReg(X86::R10);

  // Move in r10 the target of the indirect transfer.
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::MOV64rm), X86::R10);
  for (const MachineOperand &MO : MI->operands()) { // Copy all the operands
    MIB.addOperand(MO);
  }
  // Dereference the target
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::MOV64rm)).addReg(X86::R10);
  addRegOffset(MIB, X86::R10, false, 2);

  // Compare dereferenced target and expected target
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::CMP64rr), X86::R10).addReg(X86::R11);

  // jne gotMBB
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::JNE_1)).addMBB(gotMBB);

  // Otherwise is a bening tranfer, so jmp back to the call instruction
  MIB = BuildMI(*newMBB, FirstInst, DL, TII->get(X86::JMP_1)).addMBB(jmpTargetMBB);

  FirstInst = gotMBB->begin();
  // Save RAX
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::PUSH64r), X86::RAX);

  // Mov in RAX the target 
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::MOV64rm), X86::RAX);
  for (const MachineOperand &MO : MI->operands()) { // Copy all the operands
    MIB.addOperand(MO);
  }
  // Here we assume the target of the control flow transfer is done via plt and got.
  // This first check if the entry is unresolved.
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::MOV64rr), X86::R10).addReg(X86::RAX);
  // Add +6 to R10, so now it points to the instruction after jmp [] in plt.
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::ADD64ri32), X86::R10).addReg(X86::R10).addImm(6);
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::MOV32rm), X86::EAX);
  addRegOffset(MIB, X86::RAX, false, 2);
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::ADD64rr), X86::RAX).addReg(X86::RAX).addReg(X86::R10);
  // Now in rax we have the address of the got entry.
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::MOV64rm), X86::EAX);
  addRegOffset(MIB, X86::RAX, false, 0);
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::CMP64rr), X86::RAX).addReg(X86::R10);
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::JE_1)).addMBB(validMBB);

  // Otherwise 
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::MOV64rm), X86::RAX);
  if(TsxCfiStatic){ // if RELRO we add -10, because the linker resolves + 10
    addRegOffset(MIB, X86::RAX, false, -10 + 2);
  }
  else{
    addRegOffset(MIB, X86::RAX, false, 2);
  }
  // R11 == expected target
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::CMP64rr), X86::RAX).addReg(X86::R11);

  //jne violation
  MIB = BuildMI(*gotMBB, FirstInst, DL, TII->get(X86::JNE_1)).addExternalSymbol("__tsx_cfi_violation");

  FirstInst = validMBB->begin();
  // Restore RAX
  MIB = BuildMI(*validMBB, FirstInst, DL, TII->get(X86::POP64r), X86::RAX);

  // jmp target
  MIB = BuildMI(*validMBB, FirstInst, DL, TII->get(X86::JMP_1)).addMBB(jmpTargetMBB);

  return newMBB;
}

/*

 -----        ---------
| ... |      |  ...    |
| ... |      |  xacq   | MBB
| ... |  =>  |  JE+5   | MBB
| ... |      | xtestBB | xtestMBB
| ... |      | je +XX  | xtestMBB
| ... |      | r10/r11 | xtestMBB
| ... |      | jmp fb  | xtestMBB
| ret |<- MI |   ret   | newMBB
 -----        --------

If we are handling a call, there's also a lea.
If we are handling a call mem, "jmp fb" became "jmp fbMBB" where fbMBB is at the end of the function
*/
void TsxCfiHLE::insertXAcquire(MachineInstr *MI, MachineBasicBlock *MBB, int StackPointerOffset){
  // errs() << "[~] Inserting XAcquire in: " << *MBB;
  MachineInstrBuilder MIB;
  MachineFunction *MF = MBB->getParent();
  DebugLoc DL;
  char symbol[50] = {0};
  MachineBasicBlock *fbMBB;
  uint32_t FakeLabel = 0x80808080;
  unsigned prop = getOpcodeProp(MI->getOpcode());
  int LabelReg = X86::R11;  // Where we save label
  int RipReg = X86::R10;    // Where we put the address of the instruction after the call
  // MF->dump();
  // Creating a newMBB, initialized with MBB[MI:], and inserted after MBB.
  // Creating empty fbbMBB, and inserted after newMBB, before MBB.
  MachineBasicBlock *newMBB = MF->CreateMachineBasicBlock();
  MachineBasicBlock *xtestMBB = MF->CreateMachineBasicBlock();
  MF->insert(MBB->getIterator(), newMBB);
  MF->insert(MBB->getIterator(), xtestMBB);

  newMBB->moveAfter(MBB);
  xtestMBB->moveAfter(MBB);

  MBB->addSuccessor(newMBB);
  MBB->addSuccessor(xtestMBB);    
  newMBB->splice(newMBB->begin(), MBB, MI, MBB->end());

  newMBB->transferSuccessorsAndUpdatePHIs(MBB);

  // xacquire + xtest + je ret
  DL = MF->begin()->begin()->getDebugLoc();
  MIB = BuildMI(*MBB, MBB->end(), DL, TII->get(X86::XACQUIRE_PREFIX));
  MIB = BuildMI(*MBB, MBB->end(), DL, TII->get(X86::LOCK_PREFIX));
  MIB = BuildMI(*MBB, MBB->end(), DL, TII->get(X86::ADD32mi));
  addRegOffset(MIB, X86::RSP, false, StackPointerOffset);
  MIB.addImm(FakeLabel);
  MIB = BuildMI(*MBB, MBB->end(), DL, TII->get(X86::XTEST));
  MIB = BuildMI(*MBB, MBB->end(), DL, TII->get(X86::JNE_1)).addMBB(newMBB);
  
  // mov r10, target + mov r11, label + jmp cfi_fb_hle{ret,reg_mem}
  MachineBasicBlock::iterator InsertPoint = xtestMBB->begin();
  MIB = BuildMI(*xtestMBB, InsertPoint, DL, TII->get(X86::MOV32ri), LabelReg).addImm(FakeLabel);
  // errs() << "DEBUGG: " << *MI;
  if(prop & IS_RET)
    strcpy(symbol,"__tsx_cfi_fb_hle_ret");
  else if(prop & INDIRECT_CALL_REG){
    strcpy(symbol,"__tsx_cfi_fb_hle_call_");
    strcat(symbol,RegisterToString(MI->getOperand(0).getReg()));
    MIB = BuildMI(*xtestMBB, InsertPoint, DL, TII->get(X86::LEA64r), RipReg);
    addRegOffset(MIB, X86::RIP, false, 0);
  }
  else if(prop & TAIL_CALL_REG){
    strcpy(symbol,"__tsx_cfi_fb_hle_jmp_");
    strcat(symbol,RegisterToString(MI->getOperand(0).getReg()));
  }
  else if(prop & (INDIRECT_CALL_MEM | TAIL_CALL_MEM)){
    fbMBB = createFallbackMemBlock(MI, newMBB);
  }


  // jmp fallback_path
  MIB = BuildMI(*xtestMBB, InsertPoint, DL, TII->get(X86::JMP_1));

  if(strcmp(symbol,"") != 0){
    char *dupsymbol=strdup(symbol);
    MIB.addExternalSymbol(dupsymbol);
  }
  else{
    assert(fbMBB != NULL && "HLE: adding an non allocated mbb?!");
    MIB.addMBB(fbMBB);
  }
}

// xrelease lock sub[rsp] , 0xcf1bee
void TsxCfiHLE::insertXRelease(MachineInstr *MI, MachineBasicBlock *MBB, int StackPointerOffset){
  MachineInstrBuilder MIB;

  MIB = BuildMI(*MBB, MI, MBB->begin()->getDebugLoc(), TII->get(X86::XRELEASE_PREFIX));
  MIB = BuildMI(*MBB, MI, MBB->begin()->getDebugLoc(), TII->get(X86::LOCK_PREFIX));
  MIB = BuildMI(*MBB, MI, MBB->begin()->getDebugLoc(), TII->get(X86::SUB32mi));
  addRegOffset(MIB, X86::RSP, false, StackPointerOffset);
  MIB.addImm(0x80808080);
}

bool TsxCfiHLE::runOnMachineFunction(MachineFunction &MF) {
  MachineFunction::iterator MBB, MBBE;
  MachineBasicBlock::iterator MBBI, MBBIE;
  MachineInstr *MI;
  int OpcodeProp;
  TII = MF.getSubtarget().getInstrInfo();
  MachineInstrBuilder MIB;    
  MachineBasicBlock *FirstBB = (MachineBasicBlock*)MF.begin();
  std::vector<llvm::MachineInstr*> XAcquiredInstr;

  // Don't instrument dummy.
  if(strcmp(MF.getName().str().c_str(),"dummy") == 0){
    errs() << "Not instrumenting dummy!\n";
    return false;;
  }

  // Skipping empty MBBs..
  while(FirstBB->empty()){
    FirstBB = std::next(FirstBB);
  }

  MachineInstr *FirstInstr = (MachineInstr*)FirstBB->begin();
  insertXRelease(FirstInstr,FirstBB,-8);

  for (MBB = MF.begin(), MBBE = MF.end(); MBB != MBBE; ++MBB){
    // errs() << *MBB;
    for (MBBI = MBB->begin(), MBBIE = MBB->end(); MBBI != MBBIE; ++MBBI) {
      // errs() << "I: \t" << *MBBI;
      MI = MBBI;
      
      if(contains(XAcquiredInstr,MI)){
        continue;
      }

      OpcodeProp = getOpcodeProp(MI->getOpcode());
      // errs() << "needs_xacq : \n" << (OpcodeProp & NEEDS_XACQUIRE);
      // errs() << "needs_xrel : \n" << (OpcodeProp & NEEDS_XRELEASE);
      if(OpcodeProp & NEEDS_XRELEASE)
      	insertXRelease(std::next(MBBI), &*MBB,-16);

      if(OpcodeProp & NEEDS_XACQUIRE){
        XAcquiredInstr.push_back(MI);
        if(OpcodeProp & (IS_RET | TAIL_CALL_MEM | TAIL_CALL_REG))
          insertXAcquire(MBBI, &*MBB,-8);
        else
          insertXAcquire(MBBI, &*MBB,-16);
        break;
      }
      
      if(OpcodeProp & DIRECT_CALL){
        if(!TsxCfiStatic)
          emitNop(MI,&*MBB,33); // Leave some space for mov + xbegin.
        MI->getOperand(0).setOffset(10);
      }
    }
  }
  return true;
}


// Dummy pass
namespace {
  class TsxCfiNATIVE : public MachineFunctionPass {
  public:
    TsxCfiNATIVE() : MachineFunctionPass(ID) {}
    bool runOnMachineFunction(MachineFunction &MF)override {return true;};
    const char *getPassName() const override {return "No tsx cfi";}
    static char ID;
  private:
  };
  char TsxCfiNATIVE::ID = 0;
}

FunctionPass *llvm::createTsxCfiNATIVE() {
  return new TsxCfiNATIVE();
}


FunctionPass *llvm::createTsxCfiWrapper() {
  std::transform(TsxCfiMode.begin(), TsxCfiMode.end(), TsxCfiMode.begin(), ::tolower);
  errs() << "[+] MODE: " << TsxCfiMode << "\n";
  if(TsxCfiMode == "hle")
    return new TsxCfiHLE::TsxCfiHLE();
  if(TsxCfiMode == "rtm")
    return new TsxCfiRTM::TsxCfiRTM();

  errs()<<"\n########################### NO TSX SPECIFIED, GOING FOR NATIVE ###########################\n";
  return new TsxCfiNATIVE::TsxCfiNATIVE();
}

static RegisterPass<TsxCfiRTM> X("tsxcfirtmpass", "TSX CFI RTM Pass");
static RegisterPass<TsxCfiHLE> Y("tsxcfihlepass", "TSX CFI HLE Pass");
static RegisterPass<TsxCfiNATIVE> Z("tsxcfinativepass", "TSX CFI NATIVE Pass");
