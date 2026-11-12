$ ! Procedure:	TIDY_ZKUAF.COM
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
$ facility = f$parse(procedure,,,"NAME")
$
$ set noon
$ set symbol/scope=(nolocal)
$ on control_y then goto bail_out
$
$ say = "write sys$output"
$ err = "call___ err"
$ RMS$_RNF = 98994
$
$ zk_s_user = 64				! as LOGIN.COM
$ zk_s_key0 = 100				! user + uid
$
$ if (p1 .eqs. "") then p1 = "ZKUAF.DAT"
$ file = f$search(p1)
$ if (file .eqs. "")
$ then
$   err E FNF "''p1' not found"
$   goto bail_out
$ endif
$ update = (f$edit(p2,"COLLAPSE,UPCASE") .eqs. "UPDATE")
$ backup = f$parse(".BEFORE_TIDY;",file,,,"SYNTAX_ONLY")
$ tmp = "SYS$SCRATCH:TIDY_ZKUAF_''f$getjpi("","PID")'.TMP"
$ seen = 0
$ found = 0
$ changed = 0
$ clashes = 0
$
$ ! Updating needs the file to itself, so that no account is in play:
$ ! LOGIN.COM and the phone keep it open while they are.  The copy is
$ ! made first, as no one can copy it once it is held.
$ if (update)
$ then
$   define/user sys$error nla0:
$   define/user sys$output nla0:
$   copy/nolog 'file' 'backup'
$   if (.not. $status) then goto err_inuse
$   backup = f$search(backup)
$   open/read/write/error=err_inuse_copied uaf 'file'
$   err I BACKUP "the file as it was is ''backup'"
$ else
$   open/read/share=write/error=err_open uaf 'file'
$   err I REPORT "nothing is changed without UPDATE"
$ endif
$
$ ! Pass 1: the records to change.  They are kept aside, as changing a
$ ! key part way through a sequential pass would move the position.
$ open/write/error=err_open tmpf 'tmp'
$pass1:
$ read/nolock/end_of_file=pass1_done/error=err_read uaf record
$ seen = seen + 1
$ user = f$extract(0,zk_s_user,record)
$ if (f$extract(0,6,user) .eqs. "PHONE:") then goto pass1	! by design
$ if (f$edit(user,"LOWERCASE") .eqs. user) then goto pass1
$ write/symbol/error=err_write tmpf record
$ found = found + 1
$ goto pass1
$pass1_done:
$ close tmpf
$
$ ! Pass 2: change each one, unless its lower case form has an account
$ ! of its own.  The new record is written once the old is deleted: the
$ ! first 36 characters are a key of their own, without duplicates.
$ open/read/error=err_open tmpf 'tmp'
$pass2:
$ read/end_of_file=pass2_done/error=err_read tmpf record
$ user  = f$extract(0,zk_s_user,record)
$ lower = f$edit(user,"LOWERCASE")
$ from  = f$edit(user,"TRIM")
$ to    = f$edit(lower,"TRIM")
$ read/nolock/index=0/key="''lower'"/match=eq/error=pass2_free uaf other
$ clashes = clashes + 1
$ err W CLASH "''from' not changed: ''to' has an account already"
$ goto pass2
$pass2_free:
$ status = $status
$ if (status .ne. RMS$_RNF) then goto err_read_status
$ if (.not. update)
$ then
$   say "  ''from' -> ''to'"
$   goto pass2
$ endif
$ old_key = f$extract(0,zk_s_key0,record)
$ new = lower + f$extract(zk_s_user,f$length(record)-zk_s_user,record)
$ read/delete/index=0/key="''old_key'"/match=eq/error=err_read uaf old
$ write/symbol/error=err_put uaf new
$ say "  ''from' -> ''to'"
$ changed = changed + 1
$ goto pass2
$pass2_done:
$ close tmpf
$
$ err S DONE "''seen' records, ''found' with capitals, ''changed' changed, ''clashes' clashes"
$ if ((.not. update) .and. (found .gt. clashes)) then -
	err I UPDATE "@''procedure' ''p1' UPDATE makes the changes" CONTINUE
$ goto bail_out
$
$err_inuse_copied:
$ delete/nolog 'backup'
$err_inuse:
$ err E INUSE "''file' is in use: no one may be signed in, nor on the phone"
$ goto bail_out
$
$err_open:
$ err E OPEN "unable to open a file"
$ say "-" + f$message($status) - "%"
$ goto bail_out
$
$err_read:
$ status = $status
$err_read_status:
$ err E READ "unable to read a record"
$ say "-" + f$message(status) - "%"
$ goto bail_out
$
$err_write:
$ err E WRITE "unable to write ''tmp'"
$ say "-" + f$message($status) - "%"
$ goto bail_out
$
$err_put:
$ status = $status
$ write/symbol/error=err_lost uaf old		! put the old one back
$ err E PUT "unable to change ''from'; it is left as it was"
$ say "-" + f$message(status) - "%"
$ goto bail_out
$
$err_lost:
$ err F LOST "the record for ''from' could not be put back"
$ say "-" + f$message(status) - "%"
$ err I RESTORE "the file as it was is ''backup'" CONTINUE
$
$bail_out:
$ close/nolog tmpf
$ close/nolog uaf
$ if (f$type(tmp) .nes. "") then -
$     if (f$search(tmp) .nes. "") then delete/nolog 'tmp';*
$ exitt 1.or.(0*f$verify(__vfy_saved))
$ !+==========================================================================
$ !
$ ! Procedure:	TIDY_ZKUAF.COM
$ !
$ ! Purpose:	Lower-case the email addresses in ZKUAF.DAT.  LOGIN.COM looks
$ !		accounts up by lower-case address from V1-002, so an account
$ !		registered with capitals cannot sign in until its record is
$ !		changed.  Phone records (PHONE:nnnnnn) are left as they are.
$ !
$ ! Parameters:	P1	The file; ZKUAF.DAT by default.
$ !		P2	UPDATE to make the changes.  Without it the changes
$ !			are only listed.  With it the file is first copied to
$ !			<name>.BEFORE_TIDY, then held, so it can only be run
$ !			while no one is signed in or on the phone.
$ !
$ !		An address whose lower-case form already has an account is
$ !		listed as a clash and left alone, for a person to sort out.
$ !
$ ! History:
$ !		12-NOV-2026, TES; Version V1-001
$ !	001 -	Original version.
$ !-==========================================================================
