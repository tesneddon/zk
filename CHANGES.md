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
