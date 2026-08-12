# MDC Rocky Linux 9.6 Common Init

대전 갑동 MDC Rocky Linux 9.6 서버의 공통 기초 환경 설정 스크립트입니다.

## 파일
- `mdc-common-init.sh`

## 사용법

```bash
chmod +x mdc-common-init.sh
./mdc-common-init.sh (각 서버 호스트명 ex: ctrl02)
```

DNS를 변경하려면:

```bash
DNS1=8.8.8.8 DNS2=1.1.1.1 ./mdc-common-init.sh ctrl02
```

## 주요 기능
- Rocky Linux 9.6 확인
- Default Route 기준 Management NIC 자동 탐지
- Management IP/Gateway 확인
- 설정 백업
- Hostname 변경
- `/etc/hosts` 등록
- DNS 설정 및 `/etc/resolv.conf` 보정
- NTP 상태 확인
- Gateway/Internet/DNS 검증
- DNF Repository 검증

## 변경하지 않는 항목
- Management IP
- Default Gateway
- Provider NIC
- firewalld
- SELinux
- Swap
- Docker
- Kolla-Ansible
- OVS/OVN/br-ex

## 파일
- `mdc-ssh-key-bootstrap.sh`

## 사용법

```bash
chmod +x mdc-ssh-key-bootstrap.sh
./mdc-ssh-key-bootstrap.sh enable
```

## 파일
- `03-openstack-host-prep.sh`

### 사용법
chmod +x 03-openstack-host-prep.sh
./03-openstack-host-prep.sh

## 파일
- `scripts/precheck/01-all-node-precheck.sh`

### 사용법
chmod +x /root/01-all-node-precheck.sh
/root/01-all-node-precheck.sh | tee /root/mdc-precheck-result.txt
