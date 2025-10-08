#!/usr/bin/env bash
# run with sudo if needed
set -euo pipefail
: "${RAM:=4096}"
: "${CPUS:=$(nproc)}"
: "${DISK_SIZE:=30G}"
: "${SECUREBOOT:=0}"
REPO_NAME="lnos-arch"
GITHUB_REPO="rcghpge/lnos"
CWD="$(pwd)"
if [[ "$(basename "$CWD")" == "vm" && -d "$(dirname "$CWD")/$REPO_NAME" ]]; then
  VM_DIR="$CWD"
  REPO_DIR="$(dirname "$CWD")"
elif [[ "$(basename "$CWD")" == "$REPO_NAME" ]]; then
  REPO_DIR="$CWD"
  VM_DIR="$REPO_DIR/vm"
else
  REPO_DIR="$CWD"
  VM_DIR="$REPO_DIR/vm"
fi
mkdir -p "$VM_DIR"
: "${DISK:=$VM_DIR/$REPO_NAME.qcow2}"
ISO_DIR="$REPO_DIR/iso"
mkdir -p "$ISO_DIR"
: "${ISO:=}"
fetch_latest_iso_url() {
  local api="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
  local hdr=()
  [[ -n "${GITHUB_TOKEN:-}" ]] && hdr=(-H "Authorization: Bearer $GITHUB_TOKEN" -H "X-GitHub-Api-Version: 2022-11-28")
  local url
  url="$(curl -fsSL "${hdr[@]}" "$api" | grep -Eo '"browser_download_url": *"[^"]+\.iso"' | head -n1 | sed -E 's/.*"([^"]+)".*/\1/')" || true
  if [[ -z "${url:-}" ]]; then
    url="$(curl -fsSL "https://github.com/$GITHUB_REPO/releases/latest" | grep -Eo 'href="[^"]+\.iso"' | head -n1 | sed -E 's@href="([^"]+)"@https://github.com\1@')" || true
  fi
  printf '%s' "${url:-}"
}
fetch_checksum_url() {
  local page="$1"
  printf '%s' "$page" | grep -Eo '"browser_download_url": *"[^"]+\.(sha256|sha256sum|SHA256)(\.txt)?[^"]*"' | head -n1 | sed -E 's/.*"([^"]+)".*/\1/' || true
}
download_latest_iso() {
  local api="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
  local hdr=()
  [[ -n "${GITHUB_TOKEN:-}" ]] && hdr=(-H "Authorization: Bearer $GITHUB_TOKEN" -H "X-GitHub-Api-Version: 2022-11-28")
  local json
  json="$(curl -fsSL "${hdr[@]}" "$api")" || json=""
  local url name
  if [[ -n "$json" ]]; then
    url="$(printf '%s' "$json" | grep -Eo '"browser_download_url": *"[^"]+\.iso"' | head -n1 | sed -E 's/.*"([^"]+)".*/\1/')" || true
    name="$(printf '%s' "$json" | grep -Eo '"name": *"[^"]+\.iso"' | head -n1 | sed -E 's/.*"([^"]+)".*/\1/')" || true
  fi
  if [[ -z "${url:-}" ]]; then
    url="$(fetch_latest_iso_url)" || true
    name="$(basename "$url")"
  fi
  [[ -n "${url:-}" ]] || { echo "[!] No ISO found on releases"; return 1; }
  local out="$ISO_DIR/$name"
  if [[ ! -f "$out" ]]; then
    echo "[i] Downloading ISO: $url"
    curl -fL --progress-bar -o "$out.part" "$url"
    mv "$out.part" "$out"
  fi
  local sum_url
  sum_url="$(fetch_checksum_url "${json:-}")" || true
  if [[ -z "${sum_url:-}" ]]; then
    sum_url="$(curl -fsSL "https://github.com/$GITHUB_REPO/releases/latest" | grep -Eo 'href="[^"]+\.(sha256|sha256sum|SHA256)(\.txt)?[^"]*"' | head -n1 | sed -E 's@href="([^"]+)"@https://github.com\1@')" || true
  fi
  if command -v sha256sum >/dev/null 2>&1 && [[ -n "${sum_url:-}" ]]; then
    local sum_file="$ISO_DIR/$(basename "$sum_url")"
    if [[ ! -f "$sum_file" ]]; then
      echo "[i] Downloading checksum: $sum_url"
      curl -fL --progress-bar -o "$sum_file" "$sum_url" || true
    fi
    if [[ -s "$sum_file" ]]; then
      if grep -q "$(basename "$out")" "$sum_file"; then
        (cd "$ISO_DIR" && sha256sum -c "$(basename "$sum_file")") || { echo "[!] Checksum failed"; exit 1; }
      else
        local expected
        expected="$(grep -Eo '^[0-9a-fA-F]{64}' "$sum_file" | head -n1 || true)"
        if [[ -n "${expected:-}" ]]; then
          local actual
          actual="$(sha256sum "$out" | awk '{print $1}')"
          [[ "$expected" == "$actual" ]] || { echo "[!] Checksum mismatch"; exit 1; }
        fi
      fi
    fi
  fi
  ISO="$out"
}
if [[ -z "$ISO" ]]; then
  while IFS= read -r -d '' candidate; do
    ISO="$candidate"; break
  done < <(find "$REPO_DIR" -maxdepth 2 -type f \( -path "*/iso/*.iso" -o -path "*/out/*.iso" -o -path "*/artifacts/*.iso" -o -name "*.iso" \) -print0 | sort -z)
fi
if [[ -z "${ISO:-}" || ! -f "$ISO" ]]; then
  download_latest_iso || true
fi
if [[ ! -f "$DISK" ]]; then
  echo "[i] Creating qcow2 disk: $DISK ($DISK_SIZE)"
  mkdir -p "$(dirname "$DISK")"
  qemu-img create -f qcow2 "$DISK" "$DISK_SIZE" >/dev/null
fi
_candidates=(
  "/usr/share/OVMF/OVMF_CODE.fd::/usr/share/OVMF/OVMF_VARS.fd"
  "/usr/share/edk2/x64/OVMF_CODE.fd::/usr/share/edk2/x64/OVMF_VARS.fd"
  "/usr/share/edk2-ovmf/x64/OVMF_CODE.fd::/usr/share/edk2-ovmf/x64/OVMF_VARS.fd"
  "/usr/share/qemu/OVMF_CODE.fd::/usr/share/qemu/OVMF_VARS.fd"
  "/usr/share/edk2/x64/OVMF_CODE.4m.fd::/usr/share/edk2/x64/OVMF_VARS.4m.fd"
  "/usr/share/OVMF/OVMF_CODE.4m.fd::/usr/share/OVMF/OVMF_VARS.4m.fd"
)
_sb_candidates=(
  "/usr/share/edk2/x64/OVMF_CODE.secboot.fd::/usr/share/edk2/x64/OVMF_VARS.secboot.fd"
  "/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd::/usr/share/edk2/x64/OVMF_VARS.secboot.4m.fd"
  "/usr/share/OVMF/OVMF_CODE.secboot.fd::/usr/share/OVMF/OVMF_VARS.secboot.fd"
  "/usr/share/qemu/OVMF_CODE.secboot.fd::/usr/share/qemu/OVMF_VARS.secboot.fd"
)
pick_ovmf_pair() {
  local want_sb="$1"
  local pair code vars
  local -a list=()
  if [[ "$want_sb" == "1" ]]; then
    list=("${_sb_candidates[@]}" "${_candidates[@]}")
  else
    list=("${_candidates[@]}")
  fi
  for pair in "${list[@]}"; do
    code="${pair%%::*}"
    vars="${pair##*::}"
    if [[ -f "$code" && -f "$vars" ]]; then
      echo "$code::$vars"
      return 0
    fi
  done
  return 1
}
OVMF_PAIR="$(pick_ovmf_pair "$SECUREBOOT" || true)"
USE_UEFI=0
OVMF_CODE=""
OVMF_VARS=""
VARS_RW="$VM_DIR/OVMF_VARS.fd"
if [[ -n "${OVMF_PAIR}" ]]; then
  USE_UEFI=1
  OVMF_CODE="${OVMF_PAIR%%::*}"
  OVMF_VARS="${OVMF_PAIR##*::}"
  if [[ ! -f "$VARS_RW" ]]; then
    cp -f "$OVMF_VARS" "$VARS_RW"
  fi
else
  echo "[!] OVMF firmware not found. Falling back to legacy BIOS (SeaBIOS)."
  echo "    Install OVMF: Arch: edk2-ovmf | Debian/Ubuntu: ovmf | Fedora: edk2-ovmf"
fi
ACCEL_OPTS=()
if [[ -c /dev/kvm && -w /dev/kvm ]]; then
  ACCEL_OPTS+=( -accel kvm )
else
  ACCEL_OPTS+=( -accel tcg )
fi
QEMU_CMD=(
  qemu-system-x86_64
  "${ACCEL_OPTS[@]}"
  -smp "$CPUS"
  -m "$RAM"
  -cpu host
  -machine q35
  -device virtio-net-pci,netdev=n0
  -netdev user,id=n0
  -drive file="$DISK",if=virtio,format=qcow2
)
if [[ -n "${ISO:-}" && -f "${ISO}" ]]; then
  QEMU_CMD+=( -cdrom "$ISO" )
fi
if [[ "$USE_UEFI" -eq 1 ]]; then
  QEMU_CMD+=(
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE"
    -drive if=pflash,format=raw,file="$VARS_RW"
  )
fi
echo "[i] Repo: $REPO_DIR"
echo "[i] VM dir: $VM_DIR"
[[ -n "${ISO:-}" ]] && echo "[i] ISO: $ISO"
echo "[i] Disk: $DISK"
echo "[i] Launching:"
printf '  %q ' "${QEMU_CMD[@]}"; echo
exec "${QEMU_CMD[@]}"
