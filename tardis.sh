#!/bin/bash
# ============================================================
# TARDIS - System Info Dashboard (Doctor Who Theme)
# ============================================================
# Usage: source tardis.sh  or  bash tardis.sh
# ============================================================



# ── Colors ──
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD=$(tput bold)
NC='\033[0m'
NORMAL=$(tput sgr0)

# ── Terminal dimensions ──
term_width=$(tput cols)
art_col=28  # Width reserved for ASCII art column
[[ $term_width -lt 60 ]] && art_col=20

# ── Helper: print art + data ──
pline() {
    local art="$1"
    local data="$2"
    printf "%-${art_col}s %b\n" "$art" "$data"
}

# ── Gather system info ──
os=$(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME" || echo "N/A")
kernel=$(uname -r)
uptime=$(uptime -p 2>/dev/null | sed 's/up //' || echo "N/A")
bash_ver=$(bash --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
shell="${SHELL##*/} $bash_ver"
user="${USER}"
host="${HOSTNAME}"

# CPU
cpu=$(cat /proc/cpuinfo 2>/dev/null | grep "model name" | head -1 | cut -d: -f2 | xargs | cut -c1-40 || echo "N/A")
[ -z "$cpu" ] && cpu="N/A"

# RAM
ram_total=$(free -m 2>/dev/null | awk 'NR==2{print $2}')
ram_used=$(free -m 2>/dev/null | awk 'NR==2{print $3}')
ram_pct=$(free -m 2>/dev/null | awk 'NR==2{printf "%.1f", $3*100/$2}')
ram_gb_total=$(awk "BEGIN {printf \"%.1f\", $ram_total/1024}")
ram_gb_used=$(awk "BEGIN {printf \"%.1f\", $ram_used/1024}")

# Disk
disk_used=$(df -h / 2>/dev/null | awk 'NR==2{print $3}')
disk_free=$(df -h / 2>/dev/null | awk 'NR==2{print $4}')
disk_total=$(df -h / 2>/dev/null | awk 'NR==2{print $2}')
disk_pct=$(df -h / 2>/dev/null | awk 'NR==2{print $5}')

# GPU
gpu=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -1 | rev | cut -d: -f1 | rev | xargs | sed 's/(.*//' | xargs | cut -c1-48)
[ -z "$gpu" ] && gpu="N/A"

# Network
ip_local=$(ip route get 1 2>/dev/null | grep -oP 'src \K[\d.]+' | head -1)
ip_public=$(curl -s --max-time 3 ifconfig.me 2>/dev/null || echo "—")
ipv6_global=$(ip -6 addr show scope global 2>/dev/null | grep -oP 'inet6 \K[0-9a-f:]+(?=/)' | head -1)

# Processes
proc_total=$(ps -A 2>/dev/null | wc -l)
cpu_load=$(LC_ALL=C top -bn1 2>/dev/null | grep 'Cpu(s)' | awk '{print $2}' | cut -d. -f1)
[ -z "$cpu_load" ] && cpu_load="—"
cpu_load="${cpu_load}%"

# Top memory process
top_mem_proc=$(ps aux --sort=-%mem 2>/dev/null | awk 'NR==2{print $11}' | xargs basename 2>/dev/null)
top_mem_pct=$(ps aux --sort=-%mem 2>/dev/null | awk 'NR==2{printf "%.1f", $4}')
[ -z "$top_mem_proc" ] && top_mem_proc="—"
[ -z "$top_mem_pct" ] && top_mem_pct="0.0"

# Top CPU process
top_cpu_proc=$(ps aux --sort=-%cpu 2>/dev/null | awk 'NR==2{print $11}' | xargs basename 2>/dev/null)
top_cpu_pct=$(ps aux --sort=-%cpu 2>/dev/null | awk 'NR==2{printf "%.1f", $3}')
[ -z "$top_cpu_proc" ] && top_cpu_proc="—"
[ -z "$top_cpu_pct" ] && top_cpu_pct="0.0"

# Check internet
if ping -c 1 -W 1 google.com &>/dev/null; then
    internet="✅ Online"
else
    internet="⚠️  Offline"
fi

# ── Architecture ──
arch=$(uname -m)

# ══════════════════════════════════════════════════════════════
#  OUTPUT
# ══════════════════════════════════════════════════════════════

# ─── Art lines and their corresponding data ───
# Line 0: Header row
pline "。★  ˚ •    -   ˚ •。★˚˛˚" "${BOLD}${CYAN}👤 ${user}${NC} ${BOLD}@${NC} ${GREEN}${BOLD}${host}${NC}  ${YELLOW}($internet)${NC}"

# Line 1-5: System section
pline "    _______|@|_________" ""
pline "   ---------------------" "${BOLD}${YELLOW}📦  S Y S T E M${NC}"
pline "  ||  POLICE ---- BOX  ||" "  ${CYAN}OS:${NC}      ${GREEN}$os${NC}"
pline "  -----------------------C" "  ${CYAN}Kernel:${NC}  ${GREEN}$kernel${NC}"
pline "  |  ______  |  ______  |É" "  ${CYAN}Uptime:${NC}  ${GREEN}$uptime${NC}"

# Line 6-10: Hardware section
pline "  |  |####|  |  |####|  |S" "  ${CYAN}Shell:${NC}   ${GREEN}$shell${NC}"
pline "  |  |####|  |  |####|  |A" "${BOLD}${YELLOW}⚙️   H A R D W A R E${NC}"
pline "  |  |####|  |  |####|  |R" "  ${CYAN}CPU:${NC}     ${GREEN}$cpu${NC}"
pline "% |  ------  |  ------  |˚" "  ${CYAN}RAM:${NC}     ${GREEN}${ram_gb_used}GB${NC} / ${ram_gb_total}GB ${YELLOW}(${ram_pct}%)${NC}"
pline "  |  |BAD |  |  |    |  |˚" "  ${CYAN}GPU:${NC}     ${GREEN}$gpu${NC}"

# Line 11-14: Storage + Architecture
pline "  |  |WOLF|  |  |    |  |" "  ${CYAN}Disk:${NC}    ${GREEN}$disk_used${NC} usado / ${GREEN}$disk_free${NC} libre ${YELLOW}($disk_pct)${NC}"
pline "  |  ------  |O ------  |" "  ${CYAN}Arch:${NC}    ${GREEN}$arch${NC}"
pline "  |  ------  |° ------  |" "${BOLD}${YELLOW}🌐  N E T W O R K${NC}"
pline "♥ |  |    |  |  |    |  |" "  ${CYAN}Local:${NC}   ${GREEN}$ip_local${NC}"

# Line 15-18: Network + Processes
pline "L |  |    |  |  |    |  |•˛" "  ${CYAN}Public:${NC}  ${GREEN}$ip_public${NC}"
pline "A |  ------  |  ------  |。" "  ${CYAN}IPv6:${NC}    ${GREEN}${ipv6_global:----}${NC}"
pline "U |  ------  |  ------  |•" "  ${CYAN}Status:${NC}  ${GREEN}$internet${NC}"
pline "♥ |  |    |  |  |    |  |˚•" "${BOLD}${YELLOW}🔥  P R O C E S S E S${NC}"

# Line 19-22: Processes detail
pline "˚ |  |    |  |  |    |  |•˚" "  ${CYAN}Total:${NC}   ${GREEN}$proc_total${NC} ${CYAN}procesos${NC}"
pline "  |  ------  |  ------  |" "  ${CYAN}CPU Top:${NC} ${GREEN}$top_cpu_proc${NC} ${YELLOW}($top_cpu_pct%)${NC}"
pline " _|_____________________|_" "  ${CYAN}RAM Top:${NC} ${GREEN}$top_mem_proc${NC} ${YELLOW}($top_mem_pct%)${NC}"
pline " |_______________________|" "  ${CYAN}CPU Load:${NC} ${GREEN}$cpu_load${NC}"

# ── Footer ──
echo ""
echo -e "  ${BOLD}${CYAN}⏱️  $(date "+%A, %d de %B de %Y — %H:%M:%S")${NC}"
echo ""
