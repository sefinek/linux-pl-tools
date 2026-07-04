#!/usr/bin/env bash
#
# Konfiguracja locale dla Ubuntu/Debiana
# Uruchomienie z internetu:
# bash <(curl -fsSL https://raw.githubusercontent.com/sefinek/linux-pl-tools/main/scripts/set-locale-pl-en/configure-locale.sh)
#
# Skrypt ustawia hybrydowe locale:
# - jezyk systemu: angielski (en_US.UTF-8),
# - formaty regionalne: polskie (pl_PL.UTF-8).
#
# Uzycie: bash scripts/set-locale-pl-en/configure-locale.sh
#

set -euo pipefail

# Ustaw sudo tylko wtedy, gdy skrypt nie dziala jako root.
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
fi

# Sprawdz, czy to system oparty o Debiana.
if ! command -v apt-get >/dev/null 2>&1; then
  echo "Blad: ten skrypt wymaga apt-get (Debian/Ubuntu)" >&2
  exit 1
fi

# Zainstaluj pakiet locales, jezeli go brakuje.
if ! dpkg -s locales >/dev/null 2>&1; then
  echo "Instaluje pakiet locales..."
  ${SUDO} apt-get update -qq
  ${SUDO} apt-get install -y locales
  echo
fi

# Pokaz obecne ustawienia locale i czasu.
echo "--- Obecne ustawienia ---"
locale
date
echo

# Ustaw strefe czasowa na Europe/Warsaw.
${SUDO} timedatectl set-timezone Europe/Warsaw

# Odkomentuj wymagane locale w /etc/locale.gen.
${SUDO} sed -i 's/^# *en_US\.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
${SUDO} sed -i 's/^# *pl_PL\.UTF-8 UTF-8/pl_PL.UTF-8 UTF-8/' /etc/locale.gen

# Wygeneruj locale.
${SUDO} locale-gen

# Ustaw locale systemowe.
# Angielski: komunikaty, tekst i sortowanie.
# Polski: czas, liczby, waluta, papier, adresy i telefony.
${SUDO} update-locale \
  LANG=en_US.UTF-8 \
  LC_MESSAGES=en_US.UTF-8 \
  LC_CTYPE=en_US.UTF-8 \
  LC_COLLATE=en_US.UTF-8 \
  LC_TIME=pl_PL.UTF-8 \
  LC_NUMERIC=pl_PL.UTF-8 \
  LC_MONETARY=pl_PL.UTF-8 \
  LC_PAPER=pl_PL.UTF-8 \
  LC_MEASUREMENT=pl_PL.UTF-8 \
  LC_NAME=pl_PL.UTF-8 \
  LC_ADDRESS=pl_PL.UTF-8 \
  LC_TELEPHONE=pl_PL.UTF-8 \
  LC_IDENTIFICATION=pl_PL.UTF-8 \
  LC_ALL=""

# Pokaz zapisane ustawienia.
echo
echo "--- Zapisany /etc/default/locale ---"
${SUDO} cat /etc/default/locale

echo
echo "--- Strefa czasowa ---"
timedatectl | grep 'Time zone' || true

echo
echo "Info: otworz nowa sesje shella, aby locale zaczelo dzialac w Twoim srodowisku."
