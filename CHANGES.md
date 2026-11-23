* 22-Nov-2026 -- Tim Sneddon <tim@sneddon.id.au>
 - LOGIN.COM: forgotten password: a code is mailed to the account's address,
   and entered in the same session within 15 minutes sets a new password; at
   most one code every 10 minutes for an account
 - ZKUAF.DAT: the date the last reset code was sent is a new field, taken
   from the spare; existing files need no conversion
 - Status badges for the website and the phone line: utils/zkstatus.com, a
   batch job that requeues itself, writes status.html and mails a change

* 21-Nov-2026 -- Tim Sneddon <tim@sneddon.id.au>
 - LOGIN.COM: add account maintenance: change your password or name, and
   link or unlink a phone account by its passcode
 - LOGIN.COM: list your saved games and delete them, from account maintenance
 - A linked phone account plays in the linked account's directory, under its
   name; linking moves the phone's saved games there, so a game can be
   carried on at the terminal or on the phone
 - Phone: keep the account's record locked for the call, as LOGIN.COM does
   while signed in, so an account is played in one place at a time
 - Phone: save under a name, said or spelled; restore reads the names out,
   each against a key
 - LOGIN.COM: show the previous login, the last password change, the login
   count and whether a phone account is linked
 - ZKUAF.DAT: the date of the last password change and the linked account
   are new fields, taken from the spare; existing files need no conversion

* 20-Nov-2026 -- Tim Sneddon <tim@sneddon.id.au>
 - Fix the crash on SAVE on Alpha, I64 and x86-64 (Jake Hamby, #9, #4)
 - Build with one top-level DESCRIP.MMS, with MMK or MMS (after #11 from
   Brian Chiha); output goes to [<arch>_EXE], _LIB, _LIS and _OBJ
 - Kit and install the x86-64 binaries
 - IFC: give each generated MACRO module its own .TITLE
 - IFC: open sources read-only, so they no longer look changed

* 12-Nov-2026 -- Tim Sneddon <tim@sneddon.id.au>
 - Add the phone server, ZK$PHONE, played over Asterisk FastAGI
 - New phone players get a passcode, a ZKUAF.DAT record and their own directory
 - Count phone logins and record the last login time
 - Fix calls dropping when a GOSUB reply starts with "100 Trying"
 - Speak an ellipsis as a pause
 - Add the Linux side in linux/: ifc-say, prompts, dialplan and pjsip samples
 - Add ASTERISK.md, a guide to setting up the Linux box
 - Pronounce OpenVMS as "Open V M S"
 - Phone: type a number at the safe and its keypad
 - Phone: say something, spoken or spelled on the keypad
 - Add ifc-hear: speech to text with whisper.cpp, on the Linux side
 - LOGIN.COM: count logins, lower-case email addresses, check them early,
   and tell a second sign-in the account is in use
 - Add TIDY_ZKUAF.COM, to lower-case the email addresses in ZKUAF.DAT
 - Phone: hear the developer credits from the new player menu
 - Move the history from README.md to a new CREDITS.md

* 2-Nov-2026 -- Tim Sneddon <tim@sneddon.id.au>
 - Changes to remove use of MTH$RANDOM
