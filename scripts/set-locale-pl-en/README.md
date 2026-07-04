# set-locale-pl-en

Ustawia:

- `LANG=en_US.UTF-8`,
- polskie formaty regionalne `pl_PL.UTF-8`,
- timezone `Europe/Warsaw`.

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
