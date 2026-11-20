# Setting up Asterisk for The Halls of ZK by Telephone

The game runs on the VAX as a FastAGI server (`ZK$PHONE.EXE`, started by
the TCPIP service `ZKPHONE` on port 4573).  The Linux box does the rest:

- Asterisk answers the call and connects it to the VAX.
- It turns the text the VAX sends into speech with DECtalk, and keeps
  the result in a cache.
- It plays the sound files and sends the caller's keys to the VAX.

Sound never crosses the network; only text, file names and keys do.

The files for the Linux side are in `linux/`, and `linux/README.md`
says where each one is installed.  This guide covers setting up the box
around them, in order.

## 1. The box

Any small x86 box or a Raspberry Pi 4 is enough.  The reference system
is a Ryzen NUC running Debian 13.  It needs:

- TCP to the VAX on port 4573.
- A way in for calls: a SIP trunk, or an FXO ATA for a copper line.
- For testing, a softphone on the same LAN.

Install Debian from the amd64 netinst image, with only "SSH server" and
"standard system utilities".  Give the box a fixed address, so that the
VAX can be told to accept connections from it alone.

Packages:

```sh
sudo apt install sox build-essential autoconf automake libtool pkgconf git
```

`pkgconf` matters: without it, DECtalk's `autoreconf` leaves
`PKG_CHECK_MODULES` unexpanded and `configure` fails with a syntax error.

## 2. DECtalk

```sh
git clone -b develop https://github.com/dectalk/dectalk.git
cd dectalk/src
autoreconf -si && ./configure && make
sudo make install          # or copy the built `say` to /usr/local/bin
```

`configure` may also want the ALSA and PulseAudio headers
(`libasound2-dev`, `libpulse-dev`), although we only write WAV files.
GTK is optional.  Check the flags with `say -h`: `ifc-say` uses
`-fi FILE` to read text and `-fo FILE.wav` to write speech.

The DECtalk sources carry DEC's original licence: they are a community
preservation, fine for a hobby service but not for anything commercial.

### Speech to text: whisper.cpp

When the game wants something said, such as the magic word at the
building entrance, the caller can say it rather than spell it on the
keypad.  `ifc-hear` hands the recording to whisper.cpp, which runs on
the box itself: no sound leaves it.  whisper.cpp and its models are MIT
licensed.

**Build `whisper-cli`.**  It comes out of the whisper.cpp build; the
second `cmake` takes a few minutes.  `-DBUILD_SHARED_LIBS=OFF` makes it
a single program, with no libraries to install beside it.

```sh
sudo apt install cmake git build-essential wget
cd /usr/src
sudo git clone https://github.com/ggml-org/whisper.cpp.git
cd whisper.cpp
sudo cmake -B build -DBUILD_SHARED_LIBS=OFF
sudo cmake --build build -j --config Release
```

The program is then `build/bin/whisper-cli`.  Install it where
`ifc-hear` finds it, and check:

```sh
sudo install -m 755 build/bin/whisper-cli /usr/local/bin/
which whisper-cli            # /usr/local/bin/whisper-cli
whisper-cli -h | head -5     # the start of its usage message
```

- **"error while loading shared libraries"** means it was built
  without `-DBUILD_SHARED_LIBS=OFF`.  Rebuild from clean:
  `sudo rm -rf build`, then the two `cmake` commands and the `install`
  again.
- **`build/bin/main` but no `whisper-cli`** means an old clone: older
  releases called the program `main`.  Run `sudo git pull` and rebuild.

**Fetch the model.**  `base.en` is English only, and quick enough on a
small x86 box; `small.en` is more accurate and about three times
slower.  The script fetches it from Hugging Face, with `wget` or
`curl`, into `models/`:

```sh
sudo sh ./models/download-ggml-model.sh base.en
```

If the script gives trouble, fetch the same file directly:

```sh
sudo wget -O models/ggml-base.en.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin
```

Install it where `ifc-hear` looks for it, and check the size:

```sh
sudo install -d /usr/local/share/whisper
sudo install -m 644 models/ggml-base.en.bin /usr/local/share/whisper/
ls -l /usr/local/share/whisper/
```

It should be about 142 MB.  A file of a few kilobytes is an error page
saved in place of the model: fetch it again.  There is nothing else to
set up: no registry and no configuration.

**Check it,** first on the sample, then on the same sample cut down to
telephone quality, which is what callers sound like:

```sh
M=/usr/local/share/whisper/ggml-base.en.bin
whisper-cli -m $M -nt -f samples/jfk.wav
sox samples/jfk.wav -r 8000 /tmp/j8.wav
sox /tmp/j8.wav -r 16000 /tmp/j16.wav
whisper-cli -m $M -nt -f /tmp/j16.wav
```

Both should print "And so my fellow Americans, ask not what your
country can do for you…".  The time it reports is about how long a
caller waits after speaking.

`ifc-hear` itself is installed with the other ZK files (section 4), and
checked there.

## 3. Asterisk

First see whether Debian packages a current version: `apt policy
asterisk`.  If it offers 20 or later, `sudo apt install asterisk` is
enough; skip to "Starting it".

Otherwise build 22 LTS:

```sh
cd /usr/src
sudo wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-22-current.tar.gz
sudo tar xzf asterisk-22-current.tar.gz
cd asterisk-22.*/
sudo contrib/scripts/install_prereq install
sudo ./configure --with-pjproject-bundled --with-jansson-bundled
sudo make -j$(nproc)
sudo make install
sudo make samples
sudo make config
sudo ldconfig
```

The default modules include everything the game uses: `res_pjsip`,
`res_agi`, `func_file`, `func_regex` and `app_system`.

Run it as its own user:

```sh
sudo adduser --system --group --home /var/lib/asterisk --no-create-home asterisk
sudo chown -R asterisk:asterisk /etc/asterisk /var/lib/asterisk /var/log/asterisk /var/spool/asterisk /usr/lib/asterisk
```

Then uncomment `runuser = asterisk` and `rungroup = asterisk` in
`/etc/asterisk/asterisk.conf`.

### Starting it

```sh
sudo systemctl enable --now asterisk
sudo asterisk -rvvv
```

`asterisk -rvvv` gives the `*CLI>` prompt.  Commands typed there are
Asterisk's own: `core show version`, `dialplan reload`, and so on.  From
the shell, the same commands are run with `sudo asterisk -rx '…'`.

If `dialplan reload` says "No such command", `pbx_config` did not load,
usually because `extensions.conf` was missing when Asterisk started.
Fix it with `module load pbx_config.so`, or restart Asterisk.

## 4. The ZK files

Install them as `linux/README.md` describes: the directories, `ifc-say`,
`ifc-hear`, `make-zk-prompts`, `zk.sed` and the `zk-hear` files, the
two Asterisk files and the cron job.
Then make two edits:

- **In `extensions_zk.conf`,** change `VAX-ADDRESS` to the VAX's
  address.  The AGI URL is the only place the VAX is named.  `/zk` at
  the end of the URL is the sound directory, and is passed to the VAX.
- **At the end of Asterisk's own files,** add one line each:
  `#include extensions_zk.conf` in `extensions.conf`, and
  `#include pjsip_zk.conf` in `pjsip.conf`.

Check the VAX can be reached, then render the prompts:

```sh
nc -vz VAX-ADDRESS 4573
sudo make-zk-prompts
```

`make-zk-prompts` ends by checking that every prompt exists.  A missing
one ends a call the first time it is played, which may be well into a
call.

Check speech to text, if whisper.cpp is installed.  `[ifc-hear]` needs
`func_shell`, and `ifc-hear` can be tried by hand on any WAV file:

```sh
sudo asterisk -rx 'module show like func_shell'
sox /usr/src/whisper.cpp/samples/jfk.wav -r 8000 /tmp/h1.wav
sudo install -o asterisk -g asterisk /tmp/h1.wav /var/spool/ifc-hear/h1.wav
sudo runuser -u asterisk -- ifc-hear zk h1; echo
```

It should print the sample in capitals, `AND SO MY FELLOW AMERICANS …`,
and delete the recording.  On a call, pressing 0 in the game, then 0
for "say something", then 1, gives the tone; what you say is read back
before the game hears it.

Writing the spool file with `FILE()` from the `[ifc-say]` subroutine
works on Asterisk 22 without `live_dangerously`.  Commas and quotes in
the text come through `Set()` unchanged.

## 5. A softphone

`pjsip_zk.conf` has a test softphone, `tes-phone`.  Set its password,
then point any SIP softphone at the box: Zoiper, Linphone, or Telephone
on a Mac.

| Setting | Value |
| --- | --- |
| Username | `tes-phone` |
| Password | as in `pjsip_zk.conf` |
| Domain, server or host | the box's address |
| Transport | UDP, port 5060 |
| STUN, ICE, outbound proxy | off |
| DTMF | RFC 2833 (RFC 4733) |
| Codecs | G.711 µ-law and A-law |

Check that it registered with `pjsip show contacts` at `*CLI>`, then
dial `9`.  On a first call you hear `sys_welcome`, the welcome text and
the passcode prompt.  Pound, then 1, gives a new player a passcode,
spoken twice.

## 6. The trunk

Open an account with a SIP provider and buy a number.  The reference
setup uses Crazytel; others are much the same.  In the provider's
portal, create a SIP trunk and route the number's incoming calls to it.

Fill in the trunk part of `pjsip_zk.conf`:

- **The server name** must be the one the portal gives.  Crazytel's is
  `sip.biz.crazytel.net.au`.  A wrong name gives "No response received"
  every 60 seconds, not an error.
- **The account and password** go in place of `ACCOUNT` and
  `TRUNK-PASSWORD`.  The file holds passwords, so keep it mode 640,
  owned by asterisk.

Reload and check:

```
module reload res_pjsip.so
pjsip show registrations
pjsip show contacts
```

You want **Registered**, and a contact that is **Avail** with a round
trip time.  Then call the number from a mobile on its own network, not
over Wi-Fi.

### NAT and the router

- **No port forward is needed.**  Asterisk registers outwards and calls
  come back along the same path.  `rtp_symmetric`, `force_rport` and
  `rewrite_contact` handle NAT and CGNAT, and `qualify_frequency` keeps
  the path open.
- **Do not forward port 5060 to the box.**  SIP scanners find an open
  5060 within hours, and toll fraud is what they are after.  A log line
  like `Request 'OPTIONS' from '"XmanV1"' … No matching endpoint found`
  is a scanner being turned away; if you see them, look for a forward.
- **On OPNsense,** add a hybrid outbound NAT rule with **static port**
  for UDP from the box, so its SIP keeps source port 5060.  OPNsense has
  no SIP ALG to switch off.  Other routers often do, and it is worth
  turning off.
- **If calls connect but audio is missing or one-way,** set
  `local_net`, `external_media_address` and
  `external_signaling_address` on the transport.  This only helps if
  the router has a real public address.

### Security

- `[from-trunk]` sends every incoming call to the game, and `[from-lan]`
  offers only extension 9.  No caller and no softphone can reach an
  outside line.
- Set a spending limit with the provider, or turn off outgoing calls.
- Use long random passwords for the trunk and the softphones.
- Install the firewall in `linux/etc/nftables-zk.conf.sample`.  It
  accepts SIP and RTP only from the LAN and the provider.

## 7. The VAX side

- **The service** is `TCPIP SHOW SERVICE ZKPHONE`: port 4573, user ZK,
  running `ZKPHONE_RUN.COM`.  `/LIMIT` is the most callers at once.
- **Who can connect:** anyone who can reach port 4573 can play and make
  new players.  Limit the service to the Asterisk box.
- **The logicals** `ZK$PHONE_WELCOME`, `ZK$PHONE_INTRO` and
  `ZK$PHONE_CREDITS` are set in `ZKPHONE_RUN.COM` unless already defined.
  Each holds either the text itself or `@` and a file spec.  By default
  `README.MD` and `CREDITS.MD` are read from the directory
  `ZKPHONE_RUN.COM` is in.
- **ZK's `LOGIN.COM`** must leave network logins alone: `if (f$mode()
  .eqs. "NETWORK") then exit` at the top.
- **To build,** run `MMK DEFINE`, then `MMK/MACRO=VERSION=1.4` (or the same
  with MMS) at the top of the tree.  The images go in `[<arch>_EXE]`, for
  example `[VAX_EXE]`.  If a build ever looks stale, `MMK CLEAN` and build
  again: an old object linked with a newer RTL fails in confusing ways,
  such as hanging up after the first room.

## 8. When something goes wrong

Watch `sudo asterisk -rvvv` during a call.  `agi set debug on` at
`*CLI>` adds every command the VAX sends and every reply.

| Symptom | Look at |
| --- | --- |
| The call drops right after answering | Is the AGI connection refused?  On the VAX, OPCOM and `ZKPHONE_RUN.LOG` in ZK's login directory |
| The call drops after `sys_welcome` | The VAX was given a reply it does not expect; take a trace with `agi set debug on` |
| "Something went wrong" instead of game text | Run `ifc-say` by hand on the `.txt` left in `/var/spool/ifc-say/`, as the asterisk user |
| A call drops partway through | A missing fixed prompt: run `make-zk-prompts` again |
| A long pause before new text | The first render of long text; later calls use the cache |
| Keys ignored | DTMF: RFC 2833 on the phone, `dtmf_mode = rfc4733` on the endpoint |
| "Sorry, that was not clear" every time | Run `ifc-hear` by hand as above; check `func_shell` is loaded and `/var/spool/ifc-hear` is owned by asterisk |
| A spoken word comes back wrong | Add it to `/etc/ifc-say/zk-hear.prompt`, or fix it in `zk-hear.sed`; or spell it with 2 instead |
| A call to the number beeps and hangs up | Look for "extension not found in context 'from-trunk'"; the call may be addressed to the account name |

`tools/fake_agi.py` plays the Asterisk side in a terminal, printing the
text instead of speaking it.  It separates VAX problems from Linux ones:

```sh
python3 tools/fake_agi.py VAX-ADDRESS
```
