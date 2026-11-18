$ ! Procedure:	DUMP_UAF.COM
$ __vfy = "VFY_''f$parse(f$environment("procedure"),,,"name")'"
$ if (f$type('__vfy') .eqs. "") then __vfy = 0
$ __vfy_saved = f$verify(&__vfy)
$
$err: subroutine
$ set noon
$ severity = f$edit(P1,"COLLAPSE,UPCASE")
$ identification = f$edit(P2,"COLLAPSE,UPCASE")
$ text = f$edit(P3,"TRIM")
$ continuation = (f$edit(P4,"COLLAPSE,UPCASE") .nes. "")
$ say = "write sys$output"
$ percent = "%"
$ if (continuation) then percent = "-"
$ if ((severity .eqs. "") .or. (identification .eqs. "") .or. (text .eqs. ""))
$ then say "%''facility'-F-SPOTTHEERR, <''severity'><''identification'><''text'>"
$ else say "''percent'''facility'-''severity'-''identification', ''text'"
$ endif
$ exitt 1
$ endsubroutine
$
$ procedure = f$element(0,";",f$environment("PROCEDURE"))
$ procedure_name = f$parse(procedure,,,"NAME")
$ facility = procedure_name
$ location = f$parse(procedure,,,"DEVICE","NO_CONCEAL") -
		+ f$parse(procedure,,,"DIRECTORY","NO_CONCEAL") - "]["
$
$ disk_checker__ = "dbslibrary:sys_check_sys$disk.com"
$ if (f$search(disk_checker__) .nes. "") then @'disk_checker__'
$
$ set noon
$ set symbol/scope=(nolocal)
$ on warning then goto bail_out
$ on control_y then goto bail_out
$
$ _arch_type = f$getsyi("ARCH_TYPE")
$ _arch_name = f$element(_arch_type,",","OTHER,VAX,ALPHA,I64") - ","
$ _vax = (_arch_type .eq. 1)
$ _axp = (_arch_type .eq. 2)
$ _i64 = (_arch_type .eq. 3)
$ _other = (.not. (_vax .or. _axp .or. _i64))
$
$ say = "write sys$output"
$ err = "call___ err"
$ saysym = "write/symbol sys$output"
$
$ ! Field definitions for ZKUAF...
$ !
$ zk_l_user  = 0                                ! Username/email
$ zk_s_user  = 64
$ zk_t_user  = ""
$ zk_l_uid   = zk_l_user + zk_s_user            ! UID
$ zk_s_uid   = 36
$ zk_t_uid   = ""
$ zk_l_hash  = zk_l_uid + zk_s_uid              ! MD5 Password hash
$ zk_s_hash  = 32
$ zk_t_hash  = ""
$ zk_l_cdt   = zk_l_hash + zk_s_hash            ! Account creation date
$ zk_s_cdt   = 22
$ zk_n_cdt   = ""
$ zk_l_rdt   = zk_l_cdt + zk_s_cdt              ! Date of last login
$ zk_s_rdt   = 22
$ zk_n_rdt   = ""
$ zk_l_lgic  = zk_l_rdt + zk_s_rdt              ! Login count
$ zk_l_lgic  = zk_l_rdt + zk_s_rdt              ! Login count
$ zk_s_lgic  = 10
$ zk_i_lgic  = 0
$ zk_l_first = zk_l_lgic + zk_s_lgic            ! First Name
$ zk_s_first = 32
$ zk_t_first = ""
$ zk_l_last  = zk_l_first + zk_s_first          ! Last Name
$ zk_s_last  = 32
$ zk_t_last  = ""
$ zk_l_spare = zk_t_last + zk_s_last            ! Spare
$ zk_s_spare = 262
$ zk_t_spare = f$fao("!#* ", zk_s_spare)
$
$start:
$ close/nolog uaf
$ open/read/share=write/error=err_uafopen uaf zkuaf.dat
$
$ say f$fao("+-!#*--+-!#*--+-!#*--+-!#*--+",-
	24,zk_s_uid,zk_s_cdt,zk_s_rdt)
$ say f$fao("| !#AS | !#AS | !#AS | !#AS |",-
	24,"Username/Email",zk_s_uid,"UID",zk_s_cdt,"Acct. Creation",-
	zk_s_rdt,"Last Login")
$ say f$fao("+-!#*--+-!#*--+-!#*--+-!#*--+",-
	24,zk_s_uid,zk_s_cdt,zk_s_rdt)
$
$loop:
$ read/end_of_file=end_loop uaf record
$ zk_t_user  = f$edit(f$extract(zk_l_user, zk_s_user, record),"TRIM")
$ zk_t_uid   = f$extract(zk_l_uid,  zk_s_uid,  record)
$ zk_t_hash  = f$extract(zk_l_hash, zk_s_hash, record)
$ zk_n_cdt   = f$extract(zk_l_cdt,  zk_s_cdt,  record)
$ zk_n_rdt   = f$extract(zk_l_rdt,  zk_s_rdt,  record)
$ zk_i_lgic  = f$integer(f$extract(zk_l_lgic, zk_s_lgic, record))
$ zk_t_first = f$edit(f$extract(zk_l_first,zk_s_first,record),"TRIM")
$ zk_t_last  = f$edit(f$extract(zk_l_last, zk_s_last, record),"TRIM")
$ say f$fao("| !#AS | !#AS | !#AS | !#AS |",-
	24,zk_t_user,zk_s_uid,zk_t_uid,zk_s_cdt,zk_n_cdt,-
	zk_s_rdt,zk_n_rdt)
$ say f$fao("+-!#*--+-!#*--+-!#*--+-!#*--+",-
	24,zk_s_uid,zk_s_cdt,zk_s_rdt)
$ goto loop
$end_loop:
$ close/nolog uaf
$ goto bail_out
$
$err_uafopen:
$ message = "-" + f$message($status) - "%"
$ err F UAFOPEN "unable to open UAF file"
$ saysym message
$ goto bail_out
$
$err_uafread:
$ message = "-" + f$message($status) - "%"
$ err F UAFREAD "unable to read UAF file"
$ saysym message
$ goto bail_out
$
$bail_out:
$ close/nolog uaf
$ exitt 1.or.(0*f$verify(__vfy_saved))
$ !+==========================================================================
$ !
$ ! Procedure:	DUMP_UAF.COM
$ !
$ ! Purpose:	Dump ZKUAF.
$ !
$ ! Parameters:
$ !
$ ! History:
$ !		20-JUL-2013, TES; Version V1-001
$ !	001 -	Original version.
$ !-==========================================================================
