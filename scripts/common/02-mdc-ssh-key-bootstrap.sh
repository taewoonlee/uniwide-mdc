#!/bin/bash
set -Eeuo pipefail

# ==========================================================
# MDC SSH Key Bootstrap Configuration
#
# File:
#   mdc-ssh-key-bootstrap.sh
#
# Usage:
#   Enable temporary root/password SSH:
#     ./mdc-ssh-key-bootstrap.sh enable
#
#   Disable password SSH after ssh-copy-id:
#     ./mdc-ssh-key-bootstrap.sh disable
#
# Target:
#   Rocky Linux 9.6
#
# Purpose:
#   Temporarily allow root password SSH so ctrl01 can run
#   ssh-copy-id to ctrl02/ctrl03/cmp nodes.
# ==========================================================

MODE="${1:-}"
DROPIN_DIR="/etc/ssh/sshd_config.d"
DROPIN_FILE="${DROPIN_DIR}/90-mdc-key-bootstrap.conf"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="/root/mdc-ssh-backup-${TIMESTAMP}"

die() {
    echo "[ERROR] $*" >&2
    exit 1
}

if [[ "$(id -u)" -ne 0 ]]; then
    die "root 계정으로 실행해야 합니다."
fi

if [[ "${MODE}" != "enable" && "${MODE}" != "disable" ]]; then
    echo "Usage:"
    echo "  $0 enable"
    echo "  $0 disable"
    exit 1
fi

command -v sshd >/dev/null 2>&1 || die "sshd 명령을 찾을 수 없습니다."
command -v systemctl >/dev/null 2>&1 || die "systemctl 명령을 찾을 수 없습니다."

mkdir -p "${BACKUP_DIR}"
mkdir -p "${DROPIN_DIR}"

cp -a /etc/ssh/sshd_config "${BACKUP_DIR}/sshd_config" 2>/dev/null || true
cp -a "${DROPIN_DIR}" "${BACKUP_DIR}/sshd_config.d" 2>/dev/null || true

echo "======================================================"
echo " MDC SSH KEY BOOTSTRAP"
echo " Hostname : $(hostname)"
echo " Mode     : ${MODE}"
echo " Backup   : ${BACKUP_DIR}"
echo "======================================================"

if [[ "${MODE}" == "enable" ]]; then

    cat > "${DROPIN_FILE}" <<'CONF'
# Temporary setting for MDC ssh-copy-id bootstrap
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
CONF

    chmod 600 "${DROPIN_FILE}"

    echo
    echo "[1] Temporary SSH configuration created:"
    cat "${DROPIN_FILE}"

else

    # 키 배포 후 최종 보안 설정
    cat > "${DROPIN_FILE}" <<'CONF'
# MDC final SSH authentication policy
PermitRootLogin prohibit-password
PasswordAuthentication no
PubkeyAuthentication yes
CONF

    chmod 600 "${DROPIN_FILE}"

    echo
    echo "[1] Final SSH configuration created:"
    cat "${DROPIN_FILE}"
fi

echo
echo "[2] SSH configuration syntax check"

if ! sshd -t; then
    echo "[FAIL] sshd configuration syntax error."
    echo "Backup directory: ${BACKUP_DIR}"
    exit 1
fi

echo "[OK] sshd -t"

echo
echo "[3] Reload sshd"

# reload first; fallback to restart
if systemctl reload sshd; then
    echo "[OK] sshd reload"
else
    systemctl restart sshd
    echo "[OK] sshd restart"
fi

echo
echo "[4] Effective SSH policy"

sshd -T | egrep \
'permitrootlogin|passwordauthentication|pubkeyauthentication'

echo
echo "======================================================"

if [[ "${MODE}" == "enable" ]]; then
    echo "TEMPORARY SSH PASSWORD ACCESS ENABLED"
    echo
    echo "Next step on ctrl01:"
    echo "  ssh-copy-id root@<target-host>"
    echo
    echo "After key copy and key-login verification,"
    echo "run this script again with:"
    echo "  $0 disable"
else
    echo "SSH PASSWORD ACCESS DISABLED"
    echo "Root login is now public-key only."
fi

echo "======================================================"
