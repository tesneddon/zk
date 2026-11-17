$! ZKPHONE_RUN.COM - run ZK for one call, from the TCPIP auxiliary server.
$!
$! SYS$NET is the FastAGI connection from Asterisk.  The service:
$!
$!   $ TCPIP SET SERVICE ZKPHONE /PORT=4573 /PROTOCOL=TCP -
$!	/USER_NAME=ZK /PROCESS_NAME=ZKPHONE -
$!	/FILE=<device>:[<directory>]ZKPHONE_RUN.COM /LIMIT=4
$!   $ TCPIP ENABLE SERVICE ZKPHONE
$!
$! ZK$PHONE_WELCOME is what a caller hears first.  ZK$PHONE_INTRO and
$! ZK$PHONE_CREDITS are what pound, then 2 or 3, reads to a new player.
$! Each is the text itself, or @ and a file spec.  They are defined here
$! unless already defined.  README.MD and CREDITS.MD are read from
$! the directory this procedure is in.
$!
$ SET NOON
$ HERE = F$PARSE(F$ENVIRONMENT("PROCEDURE"),,,"DEVICE") + -
	 F$PARSE(F$ENVIRONMENT("PROCEDURE"),,,"DIRECTORY")
$ WELCOME = "Welcome to The Halls of ZK, the original interactive " + -
	    "fiction game written exclusively for OpenVMS."
$ INTRO = "@" + HERE + "README.MD"
$ CREDITS = "@" + HERE + "CREDITS.MD"
$ IF F$TRNLNM("ZK$PHONE_WELCOME") .EQS. "" THEN -
	DEFINE/NOLOG ZK$PHONE_WELCOME "''WELCOME'"
$ IF F$TRNLNM("ZK$PHONE_INTRO") .EQS. "" THEN -
	DEFINE/NOLOG ZK$PHONE_INTRO "''INTRO'"
$ IF F$TRNLNM("ZK$PHONE_CREDITS") .EQS. "" THEN -
	DEFINE/NOLOG ZK$PHONE_CREDITS "''CREDITS'"
$ SET DEFAULT SYS$LOGIN			! ZK$PHONE adds [.USERS.<uid>]
$ RUN 'HERE'ZK$PHONE.EXE
$ EXIT
