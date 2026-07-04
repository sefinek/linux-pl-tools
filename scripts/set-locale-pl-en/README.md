# set-locale-pl-en

Ustawia:

- `LANG=en_US.UTF-8`,
- polskie formaty regionalne `pl_PL.UTF-8`,
- timezone `Europe/Warsaw`,
- polskie serwery NTP w `chrony`, jesli istnieje.

Wymaga Debiana/Ubuntu, `apt-get` i roota albo `sudo`.

Uruchomienie:

```bash
bash scripts/set-locale-pl-en/configure-locale.sh
```

Bez klonowania:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sefinek/linux-pl-tools/main/scripts/set-locale-pl-en/configure-locale.sh)
```

Benchmark polskich serwerow NTP:

```bash
node scripts/set-locale-pl-en/benchmark-polish-ntp-servers.js
```

Przykladowy output: `examples/ntp-benchmark-output.txt`.

Jesli istnieje `/etc/chrony/chrony.conf`, skrypt tworzy kopie `/etc/chrony/chrony.conf.bak`, ustawia:

```conf
server ntp.certum.pl iburst prefer
server ntp.task.gda.pl iburst
server ntp2.tp.pl iburst
```

i restartuje `chrony`.
