#!/bin/bash
# ============================================================
# TARDIS — System Info Dashboard (Doctor Who Theme)
# ============================================================
# Usage:  source tardis.sh   or   bash tardis.sh
# ============================================================

# ── Colors ──
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD=$(tput bold)
NC='\033[0m'

# ── Terminal ──
art_col=28

# Print art + data
pline() {
    local art="$1" data="$2"
    printf "%-${art_col}s %b\n" "$art" "$data"
}

show_sep() {
    local art="$1"
    printf "%-${art_col}s ${CYAN}────────────────────────────────────${NC}\n" "$art"
}

# ── System Info ────────────────────────────────────────────
os=$(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME" || awk -F= '/PRETTY_NAME/{print $2}' /etc/*release 2>/dev/null | head -1 | tr -d '"')
[ -z "$os" ] && os="N/A"
kernel=$(uname -r)
uptime=$(uptime -p 2>/dev/null | sed 's/up //' || uptime 2>/dev/null | awk '{print $3,$4}' | tr -d ',' || echo "N/A")
bash_ver=$(bash --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
shell="${SHELL##*/} $bash_ver"

# CPU
cpu=$(cat /proc/cpuinfo 2>/dev/null | grep "model name" | head -1 | cut -d: -f2 | xargs | cut -c1-40)
[ -z "$cpu" ] && cpu="N/A"

# RAM
ram_total=$(free -m 2>/dev/null | awk 'NR==2{print $2}')
ram_used=$(free -m 2>/dev/null | awk 'NR==2{print $3}')
ram_pct=$(free -m 2>/dev/null | awk 'NR==2{printf "%.0f", $3*100/$2}')
ram_gb_used=$(awk "BEGIN {printf \"%.1f\", ${ram_used:-0}/1024}")
ram_gb_total=$(awk "BEGIN {printf \"%.1f\", ${ram_total:-0}/1024}")

# Disk
disk_used=$(df -h / 2>/dev/null | awk 'NR==2{print $3}')
disk_free=$(df -h / 2>/dev/null | awk 'NR==2{print $4}')
disk_total=$(df -h / 2>/dev/null | awk 'NR==2{print $2}')
disk_pct=$(df -h / 2>/dev/null | awk 'NR==2{print $5}')

# GPU (original method)
gpu=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -1 | sed 's/.*: //' | sed 's/(.*//' | xargs | cut -c1-48)
[ -z "$gpu" ] && gpu="N/A"

# Architecture
arch=$(uname -m)

# ── Network ────────────────────────────────────────────────
# Original method (works)
ip_local=$(ip route get 1.2.3.4 2>/dev/null | awk '{print $7}')
[ -z "$ip_local" ] && ip_local=$(ip route get 1 2>/dev/null | grep -oP 'src \K[\d.]+' | head -1)
[ -z "$ip_local" ] && ip_local="—"

ip_public=$(curl -s --max-time 2 ifconfig.me 2>/dev/null || echo "—")

ipv6_global=$(ip -6 addr show scope global 2>/dev/null | grep -oP 'inet6 \K[0-9a-f:]+' | head -1)
[ -z "$ipv6_global" ] && ipv6_global="—"

# Internet
if ping -c 1 -W 1 8.8.8.8 &>/dev/null; then
    online="${GREEN}✔${NC}"
else
    online="${YELLOW}✘${NC}"
fi

# ── Processes ──────────────────────────────────────────────
proc_total=$(ps -A 2>/dev/null | wc -l)

# Top processes (original method: RSS sort)
mem_top=$(ps aux --sort -rss 2>/dev/null | awk 'NR==2{printf "%s|%.1f", $11, $6/1024}' | xargs basename 2>/dev/null)
mem_proc=$(echo "$mem_top" | cut -d'|' -f1)
mem_mb=$(echo "$mem_top" | cut -d'|' -f2)
[ -z "$mem_proc" ] && mem_proc="—" && mem_mb="0"

cpu_line=$(ps aux --sort -pcpu 2>/dev/null | awk 'NR==2{printf "%s|%.1f", $11, $3}')
cpu_proc=$(echo "$cpu_line" | cut -d'|' -f1 | xargs basename 2>/dev/null)
cpu_pct=$(echo "$cpu_line" | cut -d'|' -f2)
[ -z "$cpu_proc" ] && cpu_proc="—" && cpu_pct="0"

# CPU load average
load_1=$(cut -d' ' -f1 /proc/loadavg 2>/dev/null)

# Disk I/O or just skip
# Uptime seconds for display
up_sec=$(awk '{print int($1)}' /proc/uptime 2>/dev/null)

# ── OUTPUT ─────────────────────────────────────────────────
clear

# ── Header
pline "。★  ˚ •    -   ˚ •。★˚˛˚" "${BOLD}${CYAN}👤 ${USER}${NC} ${BOLD}@${NC} ${GREEN}${BOLD}${HOSTNAME}${NC}"

# ── System
pline "    _______|@|_________" ""
show_sep "   ---------------------"
pline "  ||  POLICE ---- BOX  ||" "  ${CYAN}OS${NC}       ${GREEN}$os${NC}"
pline "  -----------------------C" "  ${CYAN}Kernel${NC}   ${GREEN}$kernel${NC}"
pline "  |  ______  |  ______  |É" "  ${CYAN}Uptime${NC}   ${GREEN}$uptime${NC}"
pline "  |  |####|  |  |####|  |S" "  ${CYAN}Shell${NC}    ${GREEN}$shell${NC}"

# ── Hardware
show_sep "  |  |####|  |  |####|  |A"
pline "  |  |####|  |  |####|  |R" "  ${CYAN}CPU${NC}      ${GREEN}$cpu${NC}"
pline "% |  ------  |  ------  |˚" "  ${CYAN}RAM${NC}      ${GREEN}${ram_gb_used}GB${NC} / ${ram_gb_total}GB ${YELLOW}(${ram_pct}%)${NC}"
pline "  |  |BAD |  |  |    |  |˚" "  ${CYAN}GPU${NC}      ${GREEN}$gpu${NC}"
pline "  |  |WOLF|  |  |    |  |"  "  ${CYAN}Disk${NC}     ${GREEN}$disk_used${NC} / $disk_total ${YELLOW}($disk_pct)${NC}"
pline "  |  ------  |O ------  |"  "  ${CYAN}Arch${NC}     ${GREEN}$arch${NC}"

# ── Network
show_sep "  |  ------  |° ------  |"
pline "♥ |  |    |  |  |    |  |"  "  ${CYAN}Local${NC}    ${GREEN}$ip_local${NC}"
pline "L |  |    |  |  |    |  |•˛" "  ${CYAN}Public${NC}   ${GREEN}$ip_public${NC}"
pline "A |  ------  |  ------  |。" "  ${CYAN}IPv6${NC}     ${GREEN}${ipv6_global}${NC}"
pline "U |  ------  |  ------  |•" "  ${CYAN}Online${NC}   $online"

# ── Processes
show_sep "♥ |  |    |  |  |    |  |˚•"
pline "˚ |  |    |  |  |    |  |•˚" "  ${CYAN}Procs${NC}    ${GREEN}$proc_total${NC}"
pline "  |  ------  |  ------  |"   "  ${CYAN}CPU Top${NC}  ${GREEN}$cpu_proc${NC} ${YELLOW}(${cpu_pct}%)${NC}"
pline " _|_____________________|_"  "  ${CYAN}RAM Top${NC}  ${GREEN}$mem_proc${NC} ${YELLOW}(${mem_mb} MB)${NC}"
pline " |_______________________|"  "  ${CYAN}Load${NC}     ${GREEN}$load_1${NC}"

# ── Footer
echo ""
printf "  ${CYAN}%s${NC}\n" "$(date "+%A %d/%m/%Y — %H:%M")"
echo ""
