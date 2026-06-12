#!/bin/bash
# ============================================================
# TARDIS — System Info Dashboard (Doctor Who Theme)
# Hybrid bash + Python  —  perfect Unicode alignment via wcswidth
# ============================================================

exec python3 << 'PYEOF'
import os, sys, subprocess, re
from datetime import datetime
from wcwidth import wcswidth

# ── ANSI ──
C  = '\033[0;36m'
G  = '\033[0;32m'
Y  = '\033[1;33m'
B  = '\033[1m'
N  = '\033[0m'

def col(text, *codes):
    return ''.join(codes) + text + N

def run(*args, fallback='', t=3):
    try: return subprocess.run(args, capture_output=True, text=True, timeout=t).stdout.strip()
    except: return fallback

def rp(path, fb=''):
    try:
        with open(path) as f: return f.read().strip()
    except: return fb

def dw(s):
    """Display width (wcswidth), falls back to len()."""
    w = wcswidth(s)
    return w if w > 0 else len(s)

def pad(s, w):
    """Right-pad to w display columns."""
    return s + ' ' * max(0, w - dw(s))

# ═════════════════════════════════════════  DATA  ═════════════════════════════════════════

os_pretty = run('bash','-c','. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME"') or 'N/A'
kernel = os.uname().release
uptime = run('uptime','-p').replace('up ','') or 'N/A'
bv_m = re.search(r'(\d+\.\d+)', run('bash','--version'))
shell = f"bash {bv_m.group(1)}" if bv_m else 'N/A'

cpu_raw = rp('/proc/cpuinfo')
cpu = next((l.split(':')[1].strip()[:40] for l in cpu_raw.split('\n') if 'model name' in l), 'N/A')

mem_txt = rp('/proc/meminfo')
tm = am = 0
for l in mem_txt.split('\n'):
    if 'MemTotal' in l:      tm = int(l.split()[1]) // 1024
    if 'MemAvailable' in l:  am = int(l.split()[1]) // 1024
um = tm - am
rpct = round(um * 100 / tm) if tm else 0
ram_s = f"{um/1024:.1f}GB / {tm/1024:.1f}GB ({rpct}%)"

df_l = run('df','-h','/').split('\n')
disk_s = 'N/A'
if len(df_l) >= 2:
    p = df_l[1].split()
    if len(p) >= 5: disk_s = f"{p[2]} / {p[1]} ({p[4]})"

gpu = 'N/A'
gr = run('nvidia-smi','--query-gpu=name,memory.total','--format=csv,noheader')
if gr:
    nm = re.sub(r'(NVIDIA|GeForce|Corporation)\s*','',gr.split(',')[0]).strip()
    nm = re.sub(r'\s+',' ',nm)
    vm = re.search(r'(\d+)\s*MiB',gr)
    vr = round(int(vm.group(1))/1024) if vm else 0
    gpu = f"{nm} ({vr}GB)"
else:
    for l in run('lspci').split('\n'):
        if re.search(r'vga|3d|display',l,re.I):
            br = re.search(r'\[(.*?)\]',l)
            gpu = br.group(1) if br else l.split(': ',1)[-1].split('(')[0].strip()
            break

ip_l = '—'
m = re.search(r'src (\S+)', run('ip','route','get','1.2.3.4'))
if m: ip_l = m.group(1)
ip_p = run('curl','-s','--max-time','2','ipv4.icanhazip.com') or run('curl','-s','--max-time','2','api.ipify.org') or '—'
ip6 = '—'
m = re.search(r'inet6 (\S+)', run('ip','-6','addr','show','scope','global'))
if m: ip6 = m.group(1)

ps = run('ps','aux')
proc_total = len(ps.split('\n')) - 1 if ps else 0
pl = ps.split('\n')[1:] if ps else []
def sps(ki, rss_idx=None):
    v = []
    for l in pl:
        a = l.split(None,11)
        if len(a) < 11: continue
        try:
            val = float(a[ki])
            if rss_idx is not None:
                rss_str = a[rss_idx] if len(a) > rss_idx else '0'
                rss_val = int(rss_str) if rss_str.isdigit() else 0
                v.append((val, a, rss_val))
            else:
                v.append((val, a))
        except:
            pass
    v.sort(key=lambda x: x[0], reverse=True)
    return v

def pname(a):
    """Extract process basename from ps aux split array."""
    if len(a) > 11:  # COMMAND has spaces → full command at [11]
        return os.path.basename(a[10])
    return os.path.basename(a[10]) if len(a) >= 11 else '—'

ct = sps(2); mt = sps(3, rss_idx=5)
c1n = pname(ct[0][1]) if len(ct)>0 else '—'
c1p = f"{ct[0][0]:.1f}" if len(ct)>0 else '0'
c2n = pname(ct[1][1]) if len(ct)>1 else '—'
c2p = f"{ct[1][0]:.1f}" if len(ct)>1 else '0'
m1n = pname(mt[0][1]) if len(mt)>0 else '—'
m1m = str(round(mt[0][2]/1024)) if len(mt)>0 else '0'
m2n = pname(mt[1][1]) if len(mt)>1 else '—'
m2m = str(round(mt[1][2]/1024)) if len(mt)>1 else '0'

usr = os.environ.get('USER','?')
hst = os.uname().nodename

# ═════════════════════════════════════════  BUILD LINES  ═════════════════════════════════════════
# Original TARDIS police box ASCII art, with @→🌀 in the lamp
# Python uses wcswidth to pad every art line to the same display width

dt = datetime.now().strftime('%A %d/%m/%Y — %H:%M')

lines = [
    # ── Header ──
    ("。★  ˚ •    -   ˚ •。★˚˛˚",  col('👤 '+usr,B,C)+' '+B+'🌀'+N+' '+col(hst,B,G)),
    # ── System ──
    ("    _______|🌀|_________",   f"🖥️  {col('OS',C)}      {col(os_pretty,G)}"),
    ("   ---------------------",  f"🐧  {col('Kernel',C)}  {col(kernel,G)}"),
    ("  ||  POLICE ---- BOX  ||", f"⏱️   {col('Uptime',C)}  {col(uptime,G)}"),
    ("  -----------------------C",f"📦  {col('Shell',C)}   {col(shell,G)}"),
    # ── Hardware ──
    ("  |  ______  |  ______  |É",f"🔧  {col('CPU',C)}     {col(cpu,G)}"),
    ("  |  |####|  |  |####|  |S",f"🧠  {col('RAM',C)}     {col(ram_s,G)}"),
    ("  |  |####|  |  |####|  |A",f"🎮  {col('GPU',C)}     {col(gpu,G)}"),
    ("  |  |####|  |  |####|  |R",f"💾  {col('Disk',C)}    {col(disk_s,G)}"),
    # ── CPU top 2 merged (on divider that had Arch) ──
    ("% |  ------  |  ------  |˚", f"🔥  {col('CPU',C)}     {col(c1n,G)} {col(f'({c1p}%)',Y)}  {col(c2n,G)} {col(f'({c2p}%)',Y)}"),
    # ── Network ──
    ("  |  |BAD |  |  |    |  |˚",f"🌐  {col('Local',C)}   {col(ip_l,G)}"),
    ("  |  |WOLF|  |  |    |  |", f"🌍  {col('Public',C)}  {col(ip_p,G)}"),
    ("  |  ------  |O ------  |", f"📡  {col('IPv6',C)}    {col(ip6,G)}"),
    # ── Procs ──
    ("  |  ------  |° ------  |", f"📊  {col('Procs',C)}   {col(str(proc_total),G)}"),
    # ── RAM top 2 merged (on heart door that had CPU#1) ──
    ("♥ |  |    |  |  |    |  |", f"💣  {col('RAM',C)}     {col(m1n,G)} {col(f'({m1m}MB)',Y)}  {col(m2n,G)} {col(f'({m2m}MB)',Y)}"),
    # ── Art-only lines (complete TARDIS) ──
    ("L |  |    |  |  |    |  |•˛",""),
    ("A |  ------  |  ------  |。",""),
    ("U |  ------  |  ------  |•", ""),
    # ── Date on last door (had Load) ──
    ("♥ |  |    |  |  |    |  |˚•", f"  {col(dt,C)}"),
    # ── Base ──
    (" _|_____________________|_", ""),
]

# ═════════════════════════════════════════  OUTPUT  ═════════════════════════════════════════

# Calculate max display width across all art strings
art_widths = [dw(a) for a, _ in lines]
max_art = max(art_widths) if art_widths else 28

print('\033[2J\033[H', end='')
for art, data in lines:
    if data:
        print(f"  {pad(art, max_art)}  {data}")
    else:
        print(f"  {pad(art, max_art)}")
PYEOF
