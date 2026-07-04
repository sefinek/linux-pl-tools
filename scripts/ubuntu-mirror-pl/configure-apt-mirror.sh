#!/bin/bash
# Uruchomienie z internetu:
# bash <(curl -fsSL https://raw.githubusercontent.com/sefinek/linux-pl-tools/main/scripts/ubuntu-mirror-pl/configure-apt-mirror.sh)
# bash <(curl -fsSL https://raw.githubusercontent.com/sefinek/linux-pl-tools/main/scripts/ubuntu-mirror-pl/configure-apt-mirror.sh) http://pl.archive.ubuntu.com/ubuntu/
#
# Uzycie: bash scripts/ubuntu-mirror-pl/configure-apt-mirror.sh
# Inny przydatny skrypt: https://raw.githubusercontent.com/ijash/ubuntu-fastest-mirror/master/run.sh

set -euo pipefail
SECONDS=0

# Logowanie
log() {
  local level="$1"; shift
  case "$level" in
    info)    echo -e "ℹ️ \033[1;34m$*\033[0m" ;;
    success) echo -e "✅ \033[1;32m$*\033[0m" ;;
    error)   echo -e "❌ \033[1;31m$*\033[0m" ;;
    *)       echo -e "$*";;
  esac
}

# Konfiguracja
MIRROR_URI="${1:-http://ubuntu.task.gda.pl/ubuntu/}"
SOURCES_DIR="/etc/apt/sources.list.d"
SOURCES_FILE="$SOURCES_DIR/ubuntu.sources"
SOURCES_BACKUP="${SOURCES_FILE}.bak"
LIST_FILE="/etc/apt/sources.list"
LIST_BACKUP="${LIST_FILE}.bak"
KEYRING="/usr/share/keyrings/ubuntu-archive-keyring.gpg"
SUPPORTED_CODENAMES=("noble" "resolute")
CHRONY_CONF="/etc/chrony/chrony.conf"
CHRONY_BACKUP="${CHRONY_CONF}.bak"
CHRONY_BLOCK_START="# linux-pl-tools: polskie serwery NTP"
CHRONY_BLOCK_END="# linux-pl-tools: end"
NTP_SERVERS=(
  "ntp.certum.pl iburst prefer"
  "ntp.task.gda.pl iburst"
  "ntp2.tp.pl iburst"
)

# Sprawdz, czy lsb_release jest dostepne.
command -v lsb_release >/dev/null || { log error "Brakuje lsb_release. Zainstaluj: sudo apt install lsb-release"; exit 1; }

# Sprawdz codename Ubuntu.
DISTRO_CODENAME="$(lsb_release -sc)"
SUPPORTED=false
for codename in "${SUPPORTED_CODENAMES[@]}"; do
  if [[ "$DISTRO_CODENAME" == "$codename" ]]; then
    SUPPORTED=true
    break
  fi
done

if [[ "$SUPPORTED" != true ]]; then
  log error "Wspierane codename Ubuntu: ${SUPPORTED_CODENAMES[*]} (wykryto: $DISTRO_CODENAME)"
  exit 1
fi

configure_chrony_if_present() {
  if [[ ! -f "$CHRONY_CONF" ]]; then
    log info "Nie znaleziono konfiguracji chrony, pomijam NTP: $CHRONY_CONF"
    return
  fi

  log info "Tworze kopie $CHRONY_CONF -> $CHRONY_BACKUP"
  sudo cp "$CHRONY_CONF" "$CHRONY_BACKUP"

  log info "Ustawiam polskie serwery NTP w chrony"
  TEMP_CHRONY_CONF="$(mktemp)"

  awk '
    $0 == "# linux-pl-tools: Polish NTP servers" { skip = 1; next }
    $0 == "# linux-pl-tools: polskie serwery NTP" { skip = 1; next }
    $0 == "# linux-pl-tools: end" { skip = 0; next }
    skip { next }
    /^[[:space:]]*(server|pool|peer)[[:space:]]+/ { next }
    { print }
  ' "$CHRONY_CONF" > "$TEMP_CHRONY_CONF"

  {
    echo
    echo "$CHRONY_BLOCK_START"
    for server in "${NTP_SERVERS[@]}"; do
      echo "server $server"
    done
    echo "$CHRONY_BLOCK_END"
  } >> "$TEMP_CHRONY_CONF"

  sudo cp "$TEMP_CHRONY_CONF" "$CHRONY_CONF"
  rm -f "$TEMP_CHRONY_CONF"

  if command -v systemctl >/dev/null 2>&1 && systemctl cat chrony.service >/dev/null 2>&1; then
    log info "Restartuje chrony.service"
    sudo systemctl restart chrony.service
  elif command -v service >/dev/null 2>&1; then
    log info "Restartuje chrony"
    sudo service chrony restart
  else
    log error "Nie udalo sie automatycznie zrestartowac chrony"
    return 1
  fi

  if command -v chronyc >/dev/null 2>&1; then
    chronyc sources || true
  fi
}

# Wyciagnij hostname z MIRROR_URI.
MIRROR_HOST=$(echo "$MIRROR_URI" | awk -F/ '{print $3}')

# Test ping ICMP.
if command -v ping >/dev/null; then
  log info "Sprawdzam ping do hosta: $MIRROR_HOST [3s]"
  if PING_OUT=$(ping -c 3 -W 3 "$MIRROR_HOST" 2>/dev/null); then
    PING_AVG=$(echo "$PING_OUT" | awk -F'/' '/^rtt/ {printf "%.0f", $5}')
    log success "Sredni ping: ${PING_AVG}ms"
  else
    log error "Host mirrora jest niedostepny przez ICMP (ping)"
    exit 1
  fi
else
  log info "Pomijam test ping - komenda ping nie jest dostepna"
fi

# Sprawdz katalog zrodel APT.
if [[ ! -d "$SOURCES_DIR" ]]; then
  log error "Brakuje katalogu zrodel APT: $SOURCES_DIR"
  exit 1
fi

# Sprawdz keyring Ubuntu.
if [[ ! -f "$KEYRING" ]]; then
  log error "Brakuje keyringa: $KEYRING"
  echo "   Sprobuj: sudo apt install ubuntu-keyring"
  exit 1
fi

# Zrob kopie i wyczysc stare wpisy w sources.list.
if [[ -f "$LIST_FILE" ]]; then
  log info "Tworze kopie $LIST_FILE -> $LIST_BACKUP"
  sudo cp "$LIST_FILE" "$LIST_BACKUP"
  log info "Usuwam wpisy archive.ubuntu.com z $LIST_FILE"
  sudo sed -i '/^deb .*archive\.ubuntu\.com/Id' "$LIST_FILE"
fi

# Zrob kopie istniejacego pliku .sources.
if [[ -f "$SOURCES_FILE" ]]; then
  log info "Tworze kopie $SOURCES_FILE -> $SOURCES_BACKUP"
  sudo cp "$SOURCES_FILE" "$SOURCES_BACKUP"
fi

# Zapisz nowa konfiguracje mirrora.
log info "Ustawiam mirror APT: $MIRROR_URI"
sudo tee "$SOURCES_FILE" > /dev/null <<EOF
Types: deb
URIs: $MIRROR_URI
Suites: $DISTRO_CODENAME $DISTRO_CODENAME-updates $DISTRO_CODENAME-backports
Components: main restricted universe multiverse
Signed-By: $KEYRING

Types: deb
URIs: $MIRROR_URI
Suites: $DISTRO_CODENAME-security
Components: main restricted universe multiverse
Signed-By: $KEYRING
EOF

# Wyczysc cache APT.
log info "Czyszcze cache APT..."
sudo apt clean

# Odwież indeks APT.
log info "Uruchamiam apt update..."
if sudo apt update; then
  log success "Mirror ustawiony poprawnie. Czas: ${SECONDS}s."
else
  log error "apt update nie powiodl sie. Sprawdz siec albo dostepnosc mirrora. Czas: ${SECONDS}s"
  exit 2
fi

configure_chrony_if_present
