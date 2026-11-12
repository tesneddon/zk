# The Linux side of ZK by Telephone

These are the files that run on the Asterisk box.  `ASTERISK.md` in the
top directory explains the setup in order.  This file says what each
one is and where it goes.

| File | Installed as | What it is |
| --- | --- | --- |
| `bin/ifc-say` | `/usr/local/bin/ifc-say`, mode 755 | Renders one piece of game text to a `.sln` with DECtalk and sox, unless it is cached |
| `bin/make-zk-prompts` | `/usr/local/bin/make-zk-prompts`, mode 755 | Renders the fixed prompts (`sys_*`, `key*`, `letter_*`), then checks that they all exist |
| `bin/ifc-hear` | `/usr/local/bin/ifc-hear`, mode 755 | Turns a recording of the caller into one word, with whisper.cpp |
| `etc/ifc-say/zk.sed` | `/etc/ifc-say/zk.sed` | Pronunciation fixes; `ifc-say` needs the file even when it is empty |
| `etc/ifc-say/zk-hear.sed` | `/etc/ifc-say/zk-hear.sed` | Fixes to what was heard: number words to digits |
| `etc/ifc-say/zk-hear.prompt` | `/etc/ifc-say/zk-hear.prompt` | A vocabulary hint for the recogniser |
| `etc/asterisk/extensions_zk.conf` | `/etc/asterisk/extensions_zk.conf` | The dialplan: `[zk]`, `[ifc-say]`, `[ifc-hear]`, `[from-trunk]`, `[from-lan]` |
| `etc/asterisk/pjsip_zk.conf.sample` | `/etc/asterisk/pjsip_zk.conf`, mode 640 | The trunk and a test softphone; fill in the capitals |
| `etc/nftables-zk.conf.sample` | `/etc/nftables.conf` | Firewall: SIP and RTP only from the LAN and the provider |
| `etc/cron.d/zk-phone` | `/etc/cron.d/zk-phone` | Prunes rendered text not heard for 90 days |

The Asterisk files are pulled in with one line each at the end of
Asterisk's own files, which are otherwise left alone:

```
#include extensions_zk.conf       ; in /etc/asterisk/extensions.conf
#include pjsip_zk.conf            ; in /etc/asterisk/pjsip.conf
```

## Installing by hand

From this directory, as root, once Asterisk, DECtalk's `say`, sox and
whisper.cpp (`whisper-cli` and `ggml-base.en.bin`) are installed:

```sh
install -d -o asterisk -g asterisk /var/spool/ifc-say /var/spool/ifc-hear /var/lib/asterisk/sounds/zk
install -m 755 bin/ifc-say bin/ifc-hear bin/make-zk-prompts /usr/local/bin/
install -d /etc/ifc-say
install -m 644 etc/ifc-say/zk.sed etc/ifc-say/zk-hear.sed etc/ifc-say/zk-hear.prompt /etc/ifc-say/
install -m 644 -o asterisk -g asterisk etc/asterisk/extensions_zk.conf /etc/asterisk/
install -m 640 -o asterisk -g asterisk etc/asterisk/pjsip_zk.conf.sample /etc/asterisk/pjsip_zk.conf
install -m 644 etc/cron.d/zk-phone /etc/cron.d/
```

Then:
1. Change `VAX-ADDRESS` in `extensions_zk.conf`, and the capitals in
   `pjsip_zk.conf`.
2. Add the two `#include` lines above.
3. Run `asterisk -rx 'core reload'`.
4. Run `make-zk-prompts`.

These steps are what the Debian package and `zk-phone-setup` will do
in time.
