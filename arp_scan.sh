{\rtf1\ansi\ansicpg1251\cocoartf2868
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 #!/bin/bash\
\
PREFIX="$1"\
INTERFACE="$2"\
SUBNET="$3"\
HOST="$4"\
ARPING_BIN="$\{ARPING_BIN:-arping\}"\
\
usage() \{\
    cat <<USAGE\
Usage:\
  $0 PREFIX INTERFACE [SUBNET] [HOST]\
\
Arguments:\
  PREFIX     first two octets of IPv4 address, example: 192.168\
  INTERFACE  network interface, example: eth0\
  SUBNET     optional third octet (0-255)\
  HOST       optional fourth octet (0-255)\
\
Modes:\
  PREFIX + INTERFACE                 -> scan all subnets and hosts for PREFIX\
  PREFIX + INTERFACE + SUBNET        -> scan all hosts in one subnet\
  PREFIX + INTERFACE + SUBNET + HOST -> scan one IP address\
USAGE\
\}\
\
is_root() \{\
    [[ "$EUID" -eq 0 ]]\
\}\
\
validate_prefix() \{\
    local value="$1"\
    [[ "$value" =~ ^([0-9]\{1,3\})\\.([0-9]\{1,3\})$ ]] || return 1\
\
    local o1="$\{BASH_REMATCH[1]\}"\
    local o2="$\{BASH_REMATCH[2]\}"\
\
    (( o1 >= 0 && o1 <= 255 && o2 >= 0 && o2 <= 255 ))\
\}\
\
validate_octet() \{\
    local value="$1"\
    [[ "$value" =~ ^[0-9]\{1,3\}$ ]] || return 1\
    (( value >= 0 && value <= 255 ))\
\}\
\
scan_ip() \{\
    local subnet="$1"\
    local host="$2"\
    local ip="$\{PREFIX\}.$\{subnet\}.$\{host\}"\
\
    echo "[*] IP: $\{ip\}"\
    "$ARPING_BIN" -c 3 -i "$INTERFACE" "$ip" 2>/dev/null\
\}\
\
scan_host_range() \{\
    local subnet="$1"\
    local host_start="$2"\
    local host_end="$3"\
    local host\
\
    for (( host=host_start; host<=host_end; host++ )); do\
        scan_ip "$subnet" "$host"\
    done\
\}\
\
scan_subnet_range() \{\
    local subnet_start="$1"\
    local subnet_end="$2"\
    local subnet\
\
    for (( subnet=subnet_start; subnet<=subnet_end; subnet++ )); do\
        scan_host_range "$subnet" 0 255\
    done\
\}\
\
main() \{\
    if [[ -z "$PREFIX" || -z "$INTERFACE" ]]; then\
        echo "PREFIX and INTERFACE are required positional arguments."\
        usage\
        exit 1\
    fi\
\
    validate_prefix "$PREFIX" || \{\
        echo "Invalid PREFIX: '$PREFIX'. Expected format: X.X where each octet is 0-255."\
        exit 1\
    \}\
\
    [[ "$INTERFACE" =~ ^[a-zA-Z0-9_.:-]+$ ]] || \{\
        echo "Invalid INTERFACE: '$INTERFACE'."\
        exit 1\
    \}\
\
    if [[ -n "$SUBNET" ]]; then\
        validate_octet "$SUBNET" || \{\
            echo "Invalid SUBNET: '$SUBNET'. Expected integer 0-255."\
            exit 1\
        \}\
    fi\
\
    if [[ -n "$HOST" ]]; then\
        validate_octet "$HOST" || \{\
            echo "Invalid HOST: '$HOST'. Expected integer 0-255."\
            exit 1\
        \}\
    fi\
\
    if [[ -z "$SUBNET" && -n "$HOST" ]]; then\
        echo "HOST cannot be passed without SUBNET."\
        exit 1\
    fi\
\
    command -v "$ARPING_BIN" >/dev/null 2>&1 || \{\
        echo "Command '$ARPING_BIN' not found. Install arping or set ARPING_BIN to an alternative executable."\
        exit 1\
    \}\
\
    is_root || \{\
        echo "This script must be run with elevated privileges (root/sudo)."\
        exit 1\
    \}\
\
    if [[ -n "$SUBNET" && -n "$HOST" ]]; then\
        scan_ip "$SUBNET" "$HOST"\
    elif [[ -n "$SUBNET" ]]; then\
        scan_host_range "$SUBNET" 0 255\
    else\
        scan_subnet_range 0 255\
    fi\
\}\
\
main "$@"}