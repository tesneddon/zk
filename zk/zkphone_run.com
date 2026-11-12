$! ZKPHONE_RUN.COM - run ZK for one call, from the TCPIP auxiliary server.
$!
$! SYS$NET is the FastAGI connection from Asterisk.  The service:
$!
$!   $ TCPIP SET SERVICE ZKPHONE /PORT=4573 /PROTOCOL=TCP -
$!	/USER_NAME=ZK /PROCESS_NAME=ZKPHONE -
$!	/FILE=<device>:[<directory>]ZKPHONE_RUN.COM /LIMIT=4
$!   $ TCPIP ENABLE SERVICE ZKPHONE
$!
$! ZK$PHONE_WELCOME and ZK$PHONE_INTRO are what a caller hears first and
$! what pound, then 2, reads to a new player.  Each is the text itself, or
$! @ and a file spec.  They are defined here unless already defined.
$!
$ SET NOON
$ HERE = F$PARSE(F$ENVIRONMENT("PROCEDURE"),,,"DEVICE") + -
	 F$PARSE(F$ENVIRONMENT("PROCEDURE"),,,"DIRECTORY")
$ WELCOME = "Welcome to The Halls of ZK, the original interactive " + -
	    "fiction game written exclusively for OpenVMS."
$ INTRO = "@" + (HERE - "]") + ".-]README.MD"	! README.MD, one level up
$ IF F$TRNLNM("ZK$PHONE_WELCOME") .EQS. "" THEN -
	DEFINE/NOLOG ZK$PHONE_WELCOME "''WELCOME'"
$ IF F$TRNLNM("ZK$PHONE_INTRO") .EQS. "" THEN -
	DEFINE/NOLOG ZK$PHONE_INTRO "''INTRO'"
$ SET DEFAULT SYS$LOGIN			! ZK$PHONE adds [.USERS.<uid>]
$ RUN 'HERE'ZK$PHONE.EXE
$ EXIT
