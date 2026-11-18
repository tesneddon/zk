SYS$SYSDEVICE:[ZK]

ZK_LOGIN: = SYS$LOGIN: of ZK user
ZK_EXE = ZK_LOGIN_ROOT:[EXE]
ZK_USER = ZK_LOGIN_ROOT:[USER.]


 HALLS OF ZK: TODO...

* Before adding maintenance stuff to LOGIN.COM, we need to first move
  everything into subroutines.  Maybe not declared subroutines, but need
  to gosub in place of many gotos so we can reuse things.  Especially when
  doing the change of password.  Need to gosub to get existing password
  and gosub to get new password input.

* Fix the barcode on with web site
* Look at upgrading the website to use Bootstrap, etc. like wakemeup
* Upload/download the game files
	- Login using ZK/GUID to FTP server...
	- point ftp.hallsofzk.org to BENDER...
	- Add menu option under account maintenance that handles
		providing the GUID, etc.
* Add maintain password ot option
* Add details of last login somewhere

* Start work on V2...

