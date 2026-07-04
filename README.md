# linux-pl-tools

Moje skrypty do podstawowej konfiguracji polskich serwerow Linux. Używam je gdy coś nowego stawiam.

## Skrypty

| Narzedzie                      | Opis                                                                                             | System                | Uruchomienie                                                                                                                                |
|--------------------------------|--------------------------------------------------------------------------------------------------|-----------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| `set-locale-pl-en`             | Ustawia angielski jezyk systemu, polskie formaty regionalne oraz strefe czasowa `Europe/Warsaw`. | Debian/Ubuntu         | `bash <(curl -fsSL https://raw.githubusercontent.com/sefinek/linux-pl-tools/main/scripts/set-locale-pl-en/configure-locale.sh)`             |
| `benchmark-polish-ntp-servers` | Testuje polskie serwery NTP i proponuje konfiguracje dla `chrony`.                               | Linux z Node.js       | `curl -fsSL https://raw.githubusercontent.com/sefinek/linux-pl-tools/main/scripts/set-locale-pl-en/benchmark-polish-ntp-servers.js \| node` |
| `ubuntu-mirror-pl`             | Ustawia polski mirror APT dla wspieranych wersji Ubuntu.                                         | Ubuntu Noble/Resolute | `bash <(curl -fsSL https://raw.githubusercontent.com/sefinek/linux-pl-tools/main/scripts/ubuntu-mirror-pl/configure-apt-mirror.sh)`         |

## Struktura

Skrypty sa w `scripts/<nazwa>/`. Jesli narzedzie ma dodatkowe pliki albo przyklady, trzymam je w tym samym katalogu.

## Licencja

MIT
