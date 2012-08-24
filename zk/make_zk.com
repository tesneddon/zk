$ pascal:=""
$ link:=""
$ purge:=""
$ !
$ if p1 .nes. "" then goto 'p1
$ mms
$ !
$ set ver
$ pascal/opt/nodeb/nocheck/obj=[.production] zk$main
$ pascal/opt/nodeb/nocheck/obj=[.production] zk$parse
$ pascal/opt/nodeb/nocheck/obj=[.production] zk$parse_obj
$ pascal/opt/nodeb/nocheck/obj=[.production] zk$lex
$ pascal/opt/nodeb/nocheck/obj=[.production] zk$ast
$ pascal/opt/nodeb/nocheck/obj=[.production] zk$init
$ pascal/opt/nodeb/nocheck/obj=[.production] zk$action
$ pascal/opt/nodeb/nocheck/obj=[.production] zk$object
$ pascal/opt/nodeb/nocheck/obj=[.production] zk$routines
$ !
$link:
$ copy zk$link_time.opt zk$prod_time.opt
$ inquire foo "Do you wish to supply a different link time"
$ if .not.foo then goto link1
$ define/user sys$input sys$command
$ run zk$prod_time
$link1:
$ link/notrace/exe=[.production]zk -
	v40shr/opt, zk$prod_time/opt, zk$version_v/opt
$copy:
$ set nover
$ purge [.production]
$ copy/log [.production]zk.exe sys$games/prot=w:r
$ purge sys$games:zk.exe
$ exit
$update_needed:
$ set nover
$ exit
