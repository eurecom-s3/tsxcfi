import sys, re, struct, os

import elftools as e

from capstone import *

from elftools.elf.elffile import ELFFile
from elftools.elf.sections import SymbolTableSection




def overwrite_address(f,address,data):
    f.seek(address)
    f.write(data)

def read_address(f,address,count):
    f.seek(address)
    return f.read(count)

def retrieve_symbols(elf):
    present_funcs = {}
    shared_funcs = {}
    fallback_call = None
    fallback_jmp = None

    sym_sec = elf.get_section_by_name('.symtab')

    for symbol in sym_sec.iter_symbols():

        # import IPython
        # IPython.embed()

        if symbol['st_info']['type'] == 'STT_FUNC':
            if symbol['st_shndx'] == 'SHN_UNDEF':
                shared_funcs[symbol.name] = (symbol['st_value'], symbol['st_size'])
            else:
                present_funcs[symbol['st_value']] = (symbol.name, symbol['st_size'])
        if symbol['st_info']['type'] == 'STT_NOTYPE' and symbol.name == '__tsx_cfi_fb_rtm_got' or symbol.name == '__tsx_cfi_fb_hle_got':
                fallback_call = symbol['st_value']
        if symbol['st_info']['type'] == 'STT_NOTYPE' and symbol.name == '__tsx_cfi_fb_rtm_jmp_got' or symbol.name == '__tsx_cfi_fb_hle_jmp_got':
                fallback_jmp = symbol['st_value']

    return present_funcs, shared_funcs, fallback_call, fallback_jmp

def is_hex(i):
    try:
        int(i,16)
        return True
    except ValueError:
        return False

def patch_file(infile, rtm=True):
    md = Cs(CS_ARCH_X86, CS_MODE_64)
    nop_cnt         = 16 if rtm else 33  #number of reserved bytes for our patching
    call_offset     = 3  if rtm else 10 #offset to the "original" call destination
    cfi_prologue    = ('\x49\x89\xc3' #mov r11, rax
                        '\x4c\x8d\x15\x0b\x00\x00\x00' #lea r10, rip+11
                        '\xc7\xf8\x00\x00\x00\x00' #xbegin 6
                        '\xe8\x00\x00\x00\x00' #call 5
                      ) if rtm else \
                       ('\xf2\xf0\x81\x44\x24\xf0\x80\x80\x80\x80'   #xacquire lock add [rsp-16]
                       '\x0f\x01\xd6' #xtest
                       '\x75\x12'     #jne + 0xc
                       '\x41\xbb\x80\x80\x80\x80'  #mov    r11,i0x80808080
                       '\x4c\x8d\x15\x0a\x00\x00\x00' #lea r10, rip+31
                       '\xe9\x00\x00\x00\x00' #jmp fallback
                       )

    jmp = '\xeb' + chr(nop_cnt-2)
    try:
        f = open(infile,'r+b')
    except:
        sys.exit(-1)
    elf = ELFFile(f)
    present_funcs, shared_funcs, fallback_call, fallback_jmp = retrieve_symbols(elf)

    text_sec = elf.get_section_by_name('.text')
    code = text_sec.data()
    p_offset = text_sec['sh_offset']
    v_offset = text_sec['sh_addr']

    plt_sec = elf.get_section_by_name('.plt')
        
    plt_p_offset = plt_sec['sh_offset'] if plt_sec else 0
    plt_v_offset = plt_sec['sh_addr'] if plt_sec else 0
    plt_size     = plt_sec['sh_size'] if plt_sec else 0

    plt_got_sec = elf.get_section_by_name('.plt.got')
    plt_got_size= plt_got_sec['sh_size'] if plt_got_sec else 0
    
    #assumption: plt.got is always directly after .plt
    plt_size += plt_got_size


    for func in present_funcs:
        start = func - v_offset
        end = start + present_funcs[func][1]
        c = code[start:end] 

        nops = 0    
        lea = False
        lea_ins = None
        transaction = False
        for i in md.disasm(c,func):
            if i.mnemonic == 'lea':
                lea_ins = i
                lea = True       
                nops = 0
                continue
            elif i.mnemonic == 'xbegin' or i.mnemonic == 'xtest':
                transaction = True
                continue
            elif lea == True and i.mnemonic == 'call' and transaction:
                patch = struct.pack("<I",i.address + i.size - lea_ins.address - lea_ins.size)
                address = lea_ins.address - v_offset + p_offset + 3
                overwrite_address(f, address, patch)
                transaction = False
                lea = False
            elif nops == nop_cnt and i.mnemonic == 'nop':
                continue

            elif nops == nop_cnt and (i.mnemonic == 'call' or i.mnemonic == 'jmp'):
                fallback = fallback_call
                if i.mnemonic == 'jmp':
                    fallback = fallback_jmp
                nops = 0
                target = int(i.op_str,16)
                
                address = i.address - nop_cnt - v_offset + p_offset
                if target - call_offset in present_funcs: 
                    patch = jmp 
                else: 
                    plt_address = target - plt_v_offset + plt_p_offset - call_offset +2 

                    if i.size == 5: 
                        c_bytes = read_address(f,address + nop_cnt +1 ,4)
                        c_patch = struct.pack("<I", struct.unpack("<I",c_bytes)[0] -call_offset)
                    elif i.size == 2:
                        c_bytes = read_address(f,address + nop_cnt +1 ,1)
                        c_patch = struct.pack("<B", struct.unpack("<B",c_bytes)[0] -call_offset)
                    fb_patch = struct.pack("<i", fallback - address - nop_cnt - v_offset + p_offset)
                    patch = cfi_prologue[:12] + fb_patch + chr(i.bytes[0]) + c_patch if rtm else\
                            cfi_prologue[:29] + fb_patch + chr(i.bytes[0]) + c_patch
                overwrite_address(f, address, patch)
                transaction = False
            elif (i.mnemonic == 'call' or i.mnemonic == 'jmp') and is_hex(i.op_str) and int(i.op_str,16) >= plt_v_offset and int(i.op_str,16) < plt_size + plt_v_offset + call_offset:
                address = i.address - v_offset + p_offset
                if i.size == 5: 
                    c_bytes = read_address(f,address  +1 ,4)
                    c_patch = struct.pack("<I", struct.unpack("<I",c_bytes)[0] -call_offset)
                elif i.size == 2:
                    c_bytes = read_address(f,address + nop_cnt +1 ,1)
                    c_patch = struct.pack("<B", struct.unpack("<B",c_bytes)[0] -call_offset)
                patch = chr(i.bytes[0]) + c_patch
                overwrite_address(f, address, patch)
                transaction = False
            elif transaction and (i.mnemonic == 'ret' or i.mnemonic =='xend' or i.mnemonic =='lock sub'):
                transaction = False

            elif i.mnemonic == 'nop':
                nops +=1
                lea = False
                continue
            if i.mnemonic == 'jmp':
                continue
            nops = 0
            lea=False

def main():
    if 'TSXCFI_MODE' in os.environ and os.environ['TSXCFI_MODE']=='rtm':
        mode = True
    elif 'TSXCFI_MODE' in os.environ and os.environ['TSXCFI_MODE']=='hle':
        mode = False
    elif 'TSXCFI_MODE' in os.environ and os.environ['TSXCFI_MODE']=='native':
        exit()
    else:
        print "Could not find environment-variable TSXCFI_MODE. Please set it to 'rtm' or 'hle'." 
        exit()

    for i in range(1, len(sys.argv)):
        patch_file(sys.argv[i], rtm=mode)


if __name__ == "__main__":
    main()
