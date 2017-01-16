import os, sys,re

def patch_asm(infile,outfile,rtm=True):
    tsx_ret = ('\tmovq %rax,%r11\n'
               '\txBegin __tsx_cfi_fb_rtm_ret\n'
               ) if rtm else\
              ('\t movq $0x80808080, %r11\n'
               '\t xAcquire \n lock addl $0x80808080, -0x8(%rsp)\n'
               '\t xtest\n'
               '\t je __tsx_cfi_fb_hle_ret\n'
              )
    tsx_call_after = '\txEnd\n' if rtm else '\txRelease \n lock subl $0x80808080, -0x10(%rsp)\n'
    tsx_func_entry = '\txEnd\n' if rtm else '\txRelease \n lock subl $0x80808080, -0x8(%rsp)\n'

    offset = 3  if rtm else 10

    rcall_reg = re.compile('\s+call\s\*%(r\w{1,2})')
    rcall     = re.compile('call\s\w+\n')
    rret      = re.compile('ret\s')
    rglobal   = re.compile('\s*\.type\s+(\w+),@function')
    rlabel    = re.compile('(\w+):(\s(.+)\n|\n)')


    funcs = []

    rf = open(infile,'r');
    if infile == outfile:
        wf = open('tmpfile','w')
    else:
        wf = open(outfile,'w');

    lines = rf.readlines()
    for i in range(len(lines)):
        l = lines[i]
        if rlabel.match(l):
            m = rlabel.match(l)
            label = m.groups()[0]
            other = m.groups()[1]
            wf.write(label+':\n')
            # comment for ret-only

            if label in funcs and i < (len(lines) - 1):
                nextf = rlabel.match(lines[i+1])
                if nextf and nextf.groups(0)[0] in funcs:
                    continue
                wf.write(tsx_func_entry)
                
            if other == '\n':
                continue
            l = other

        if rglobal.search(l):
            m = rglobal.match(l)
            f = m.groups()[0]
            funcs.append(f)
            
        if rret.search(l):
            wf.write(tsx_ret)

        if rcall_reg.search(l):
            reg = rcall_reg.match(l).groups()[0]
            savereg = '%r10' if reg == '%r11' else '%r11'
            tsx_call_reg = ('\tmovq %%rax,%s\n'
                            '\txBegin __tsx_cfi_fb_rtm_call_%s\n'
                           %(savereg, reg)) if rtm else\
                           (
                            '\t xAcquire \n lock addl $0x80808080, -0x10(%%rsp)\n'
                            '\t xtest\n'
                            '\t jne .+20\n'
                            '\t movl $0x80808080, %%r11d\n'
                            '\t lea  (%%rip), %%r10\n'
                            '\t jmp __tsx_cfi_fb_hle_call_%s\n'
                           % reg )
                           
            wf.write(tsx_call_reg)

        if rcall.search(l) and not rcall_reg.search(l):
            l = "%s + %d\n" %(l.strip(), offset)

        wf.write(l)

        if rcall.search(l):
            wf.write(tsx_call_after)

    rf.close()
    wf.close()
    if infile==outfile:
       os.rename('tmpfile',infile)

def main():
    if 'TSXCFI_MODE' in os.environ and os.environ['TSXCFI_MODE']=='rtm':
        mode = True
    elif 'TSXCFI_MODE' in os.environ and os.environ['TSXCFI_MODE']=='hle':
        mode = False
    else:
        print "Could not find environment-variable TSXCFI_MODE. Please set it to 'rtm' or 'hle'."
        exit()

    for i in range(1, len(sys.argv)):
        print "[+] Patching assembly of %s" % sys.argv[i]
        
        patch_asm(sys.argv[i],sys.argv[i],rtm=mode)


if __name__ == "__main__":
    main()
