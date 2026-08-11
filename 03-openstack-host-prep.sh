#!/bin/bash
set -Eeuo pipefail

# ==========================================================
# MDC OpenStack 2025.1 Host Preparation
# Target OS : Rocky Linux 9.6
# Target    : ctrl01~03, cmp01~10
# ==========================================================

if [[ "$(id -u)" -ne 0 ]]; then
    echo "[ERROR] root 계정으로 실행해야 합니다."
    exit 1
fi

echo "======================================================"
echo " MDC OPENSTACK HOST PREPARATION"
echo " Hostname : $(hostname)"
echo "======================================================"

# ----------------------------------------------------------
# 1. OS 확인
# ----------------------------------------------------------
echo "[1] OS Check"

cat /etc/rocky-release

if ! grep -q "^Rocky Linux release 9\.6" /etc/rocky-release; then
    echo "[ERROR] Rocky Linux 9.6이 아닙니다."
    exit 1
fi

# ----------------------------------------------------------
# 2. Hostname 확인
# ----------------------------------------------------------
echo "[2] Hostname Check"

hostname

# ----------------------------------------------------------
# 3. 공통 패키지 설치
# ----------------------------------------------------------
echo "[3] Common Packages"

dnf install -y \
    git \
    python3 \
    python3-pip \
    python3-devel \
    python3-libselinux \
    libffi-devel \
    gcc \
    openssl-devel \
    vim-enhanced \
    wget \
    curl \
    rsync \
    net-tools \
    bind-utils \
    traceroute \
    tcpdump \
    lsof \
    bash-completion \
    pciutils \
    ethtool \
    chrony

# ----------------------------------------------------------
# 4. NTP
# ----------------------------------------------------------
echo "[4] NTP"

timedatectl set-timezone Asia/Seoul
systemctl enable --now chronyd

# ----------------------------------------------------------
# 5. Kernel Module
# ----------------------------------------------------------
echo "[5] Kernel Modules"

cat > /etc/modules-load.d/openstack.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# ----------------------------------------------------------
# 6. Sysctl
# ----------------------------------------------------------
echo "[6] Sysctl"

cat > /etc/sysctl.d/99-openstack.conf <<EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

# ----------------------------------------------------------
# 7. SSH
# ----------------------------------------------------------
echo "[7] SSH"

systemctl enable --now sshd

# ----------------------------------------------------------
# 8. SELinux 확인
# ----------------------------------------------------------
echo "[8] SELinux"

getenforce || true

# ----------------------------------------------------------
# 9. Firewall 확인
# ----------------------------------------------------------
echo "[9] Firewalld"

systemctl is-active firewalld || true
systemctl is-enabled firewalld || true

# ----------------------------------------------------------
# 10. Swap 확인
# ----------------------------------------------------------
echo "[10] Swap"

swapon --show || true

# ----------------------------------------------------------
# 11. NIC 확인
# ----------------------------------------------------------
echo "[11] Network"

ip -br addr
ip route
nmcli device status

# ----------------------------------------------------------
# 12. DNS 확인
# ----------------------------------------------------------
echo "[12] DNS"

cat /etc/resolv.conf
getent hosts mirrors.rockylinux.org || true

# ----------------------------------------------------------
# 13. Repository 확인
# ----------------------------------------------------------
echo "[13] DNF Repository"

dnf makecache

# ----------------------------------------------------------
# 14. Docker / OVS / OVN 기존 설치 여부
# ----------------------------------------------------------
echo "[14] Existing OpenStack Related Packages"

rpm -qa | egrep 'docker|podman|openvswitch|ovn' || true

echo
echo "======================================================"
echo " HOST PREPARATION COMPLETE"
echo " Hostname : $(hostname)"
echo "======================================================"
