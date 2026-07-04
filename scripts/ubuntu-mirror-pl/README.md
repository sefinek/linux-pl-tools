# ubuntu-mirror-pl

Ustawia polski mirror APT dla Ubuntu Noble i Resolute.

Domyslnie uzywa:

```text
http://ubuntu.task.gda.pl/ubuntu/
```

Wymaga Ubuntu Noble/Resolute, `sudo`, `lsb_release` i `ubuntu-keyring`.

Uruchomienie:

```bash
bash scripts/ubuntu-mirror-pl/configure-apt-mirror.sh
```

Bez klonowania:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sefinek/linux-pl-tools/main/scripts/ubuntu-mirror-pl/configure-apt-mirror.sh)
```

Inny mirror:

```bash
bash scripts/ubuntu-mirror-pl/configure-apt-mirror.sh http://pl.archive.ubuntu.com/ubuntu/
bash <(curl -fsSL https://raw.githubusercontent.com/sefinek/linux-pl-tools/main/scripts/ubuntu-mirror-pl/configure-apt-mirror.sh) http://pl.archive.ubuntu.com/ubuntu/
```

Tworzy kopie:

- `/etc/apt/sources.list.bak`,
- `/etc/apt/sources.list.d/ubuntu.sources.bak`.
