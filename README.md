# 🐧 linux-pl-tools

Moje skrypty do podstawowej konfiguracji polskich serwerow Linux. Używam je gdy coś nowego stawiam.

## 🛠️ Skrypty

### 🌍 set-locale-pl-en

Ustawia angielski jezyk systemu, polskie formaty regionalne, timezone `Europe/Warsaw` i polskie NTP w `chrony`, jesli istnieje.

System: Debian/Ubuntu

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sefinek/linux-pl-tools/main/scripts/set-locale-pl-en/configure-locale.sh)
```

### ⏱️ benchmark-polish-ntp-servers

Testuje polskie serwery NTP i proponuje konfiguracje dla `chrony`.

System: Linux z Node.js

```bash
curl -fsSL https://raw.githubusercontent.com/sefinek/linux-pl-tools/main/scripts/set-locale-pl-en/benchmark-polish-ntp-servers.js | node
```

### 📦 ubuntu-mirror-pl

Ustawia polski mirror APT dla Ubuntu Noble/Resolute.

System: Ubuntu Noble/Resolute

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sefinek/linux-pl-tools/main/scripts/ubuntu-mirror-pl/configure-apt-mirror.sh)
```

## 📁 Struktura

Skrypty sa w `scripts/<nazwa>/`. Jesli narzedzie ma dodatkowe pliki albo przyklady, trzymam je w tym samym katalogu.

## 📄 Licencja

MIT
