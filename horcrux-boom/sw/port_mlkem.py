#!/usr/bin/env python3
"""Port the HORCRUX (CV32E40PX, RV32) ML-KEM sources to BOOM + HORCRUX-on-RoCC (RV64).

usage: port_mlkem.py <src dir> <dst dir>

Mechanical changes only, every one listed here:
  - ".insn r 0x3b, 0x7, F, ..."   -> "hx_r F, ..."     (HORCRUX R-type,  macro in horcrux_rocc.h)
  - ".insn r 0x6b, f3, f2, ..."   -> "hx_r4 f3, f2, ..." (HORCRUX R4-type, macro in horcrux_rocc.h)
  - *.S: saving/restoring ra and s-registers with sw/lw -> sd/ld and a doubled stack frame (RV64 registers
    are 64 bits; the 32-bit state words are still moved with lw/sw).
The script fails if any HORCRUX .insn is left or if an .insn has an unexpected form.
"""
import os, re, shutil, sys

src, dst = sys.argv[1], sys.argv[2]
os.makedirs(dst, exist_ok=True)
R = re.compile(r'\.insn\s+r\s+0x3b\s*,\s*0x7\s*,\s*')
R4 = re.compile(r'\.insn\s+r\s+0x6b\s*,\s*')
SAVE = re.compile(r'^(\s*)(sw|lw)(\s+)(ra|s\d+)(\s*),(\s*)(\d+)\(sp\)', re.M)
FRAME = re.compile(r'^(\s*addi\s+sp\s*,\s*sp\s*,\s*)(-?)(\d+)', re.M)
n = {'r': 0, 'r4': 0, 'save': 0, 'frame': 0}
for f in sorted(os.listdir(src)):
    p = os.path.join(src, f)
    if not os.path.isfile(p):
        continue
    if not f.endswith(('.c', '.h', '.S')):
        shutil.copy(p, dst)
        continue
    t = open(p).read()
    t, k = R.subn('hx_r ', t); n['r'] += k
    t, k = R4.subn('hx_r4 ', t); n['r4'] += k
    if f.endswith('.S'):
        t, k = SAVE.subn(lambda m: f"{m[1]}{'sd' if m[2] == 'sw' else 'ld'}{m[3]}{m[4]}{m[5]},{m[6]}{2 * int(m[7])}(sp)", t)
        n['save'] += k
        t, k = FRAME.subn(lambda m: f"{m[1]}{m[2]}{2 * int(m[3])}", t); n['frame'] += k
    left = re.findall(r'\.insn[^\n"]*', t)
    bad = [l for l in left if re.search(r'0x3b|0x6b', l)]
    assert not bad, f'{f}: unported HORCRUX instruction(s): {bad}'
    open(os.path.join(dst, f), 'w').write(t)
print(f'ported {src} -> {dst}: {n}')
