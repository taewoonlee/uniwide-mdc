#!/bin/bash

NODES="ctrl01 ctrl02 ctrl03 cmp01 cmp02 cmp03 cmp04 cmp05 cmp06 cmp07 cmp08 cmp09 cmp10"

for NODE in $NODES
do
    echo
    echo "============================================================"
    echo " NODE : $NODE"
    echo "============================================================"

    ssh -o BatchMode=yes -o ConnectTimeout=5 root@$NODE '

        echo "----- HOSTNAME -----"
        hostname

        echo "----- OS -----"
        cat /etc/rocky-release

        echo "----- KERNEL -----"
        uname -r

        echo "----- CPU -----"
        nproc
        lscpu | grep -E "^Model name:|^Socket\(s\):|^Core\(s\) per socket:"

        echo "----- MEMORY -----"
        free -h

        echo "----- DISK -----"
        lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS

        echo "----- NETWORK -----"
        ip -br addr

        echo "----- ROUTE -----"
        ip route

        echo "----- DEFAULT INTERFACE -----"
        ip route | awk "/^default/ {print}"

        echo "----- DNS -----"
        cat /etc/resolv.conf

        echo "----- NTP -----"
        timedatectl | grep -E \
        "Time zone|System clock synchronized|NTP service"

        echo "----- CHRONY -----"
        chronyc tracking 2>/dev/null | grep -E \
        "Stratum|System time|Leap status" || true

        echo "----- SELINUX -----"
        getenforce

        echo "----- FIREWALLD -----"
        systemctl is-active firewalld || true

        echo "----- SWAP -----"
        swapon --show

        echo "----- PYTHON -----"
        python3 --version

        echo "----- NIC LINK -----"
        for IF in $(ls /sys/class/net | grep -v lo); do
            echo "### $IF"
            ip -br addr show "$IF"
            ethtool "$IF" 2>/dev/null |
                grep -E "Speed:|Duplex:|Link detected:" || true
        done
    '
done
