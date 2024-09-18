#!/bin/bash

CYAN="\e[96m"
GREEN="\e[92m"
YELLOW="\e[93m"
RED="\e[91m"
MAGENTA="\e[95m"
NC="\e[0m"

if [ "$EUID" -ne 0 ]; then
    echo -e "\n ${RED}This script must be run as root.${NC}"
    exit 1
fi

cpu_level() {
    cpu_support_info=$(/usr/bin/awk -f <(wget -qO - https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/checkcpu.sh))
    if [[ $cpu_support_info == "CPU supports x86-64-v"* ]]; then
        cpu_support_level=${cpu_support_info#CPU supports x86-64-v}
        echo -e "${MAGENTA}Current CPU Level:${GREEN} x86-64 Level $cpu_support_level${NC}"
        return $cpu_support_level
    else
        echo -e "${RED}OS or CPU level is not supported by the XanMod kernel and cannot be installed.${NC}"
        return 0
    fi
}

install_xanmod() {
    cpu_support_info=$(/usr/bin/awk -f <(wget -qO - https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/checkcpu.sh))

    if [[ $cpu_support_info == "CPU supports x86-64-v"* ]]; then
        cpu_support_level=${cpu_support_info#CPU supports x86-64-v}
        echo -e "${CYAN}Current CPU Level: x86-64 Level $cpu_support_level${NC}"
    else
        echo -e "${RED}OS or CPU level is not supported by the XanMod kernel and cannot be installed.${NC}"
        return 1
    fi

    wget -qO - https://gitlab.com/afrd.gpg | sudo gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
    echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list

    temp_folder=$(mktemp -d)
    cd $temp_folder

    case $cpu_support_level in
        1)
            apt-get update
            apt-get install linux-xanmod-x64v1 -y
            ;;
        2)
            apt-get update
            apt-get install linux-xanmod-x64v2 -y
            ;;
        3)
            apt-get update
            apt-get install linux-xanmod-x64v3 -y
            ;;
        4)
            apt-get update
            apt-get install linux-xanmod-x64v4 -y
            ;;
        *)
            echo -e "${RED}Your CPU is not supported by the XanMod kernel and cannot be installed.${NC}"
            return 1
            ;;
    esac

    echo -e "${GREEN}The XanMod kernel has been installed successfully.${NC}"

    echo -e "${GREEN}       GRUB boot updating ${NC}"
    update-grub
    echo -e "${GREEN}The GRUB boot configuration has been updated.${NC}"
}

bbrv3() {
    echo -e "${YELLOW}Backing up original kernel parameter configuration... ${NC}"
    cp /etc/sysctl.conf /etc/sysctl.conf.bak
    echo -e "${YELLOW}Optimizing kernel parameters for better network performance... ${NC}"

    cat <<EOL >> /etc/sysctl.conf
# BBRv3 Optimization for Better Network Performance
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
EOL

    sysctl -p
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Kernel parameter optimization for better network performance was successful.${NC}"
    else
        echo -e "${RED}Kernel parameter optimization failed. Restoring the original configuration...${NC}"
        mv /etc/sysctl.conf.bak /etc/sysctl.conf
    fi
}

# Automatically run the first menu option
install_xanmod
bbrv3
