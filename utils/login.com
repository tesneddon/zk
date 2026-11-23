$ ! Procedure:	LOGIN.COM
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
$ ! The subroutines below are called with arguments and hand back their
$ ! results in global symbols, as a subroutine cannot write to a symbol of
$ ! the main line.  The main line must not assign to a symbol of the same
$ ! name, or its own would hide the result.  They read the main line's
$ ! symbols (say, err, getmd5 and the field sizes) but not its labels: one
$ ! that cannot go on exits with an error, for the caller to bail out.
$ !
$ ! Subroutine: get_name
$ !
$ ! Ask for a name, into the global symbol name_answer.
$ !
$ !	P1	What it is, as it is prompted for: "First name".
$ !	P2	The size of its field.  A longer name is asked for again.
$ !	P3	KEEP if RETURN alone keeps the name there is already;
$ !		name_answer is then empty.
$ !
$ ! A name cannot have a quotation mark in it: it is passed to put_field
$ ! in quotes, and ZK$MULTI_USER is defined with it.
$ !
$get_name: subroutine
$ set noon
$ keep = (f$edit(p3,"COLLAPSE,UPCASE") .eqs. "KEEP")
$ what = f$edit(p1,"LOWERCASE")
$ name_answer == ""
$ goto get_name_ask
$get_name_help:
$ say ""
$ say "  Please enter your ''what', for personalization.  Under no"
$ say "  circumstances will it be provided to any third-party."
$ say ""
$get_name_ask:
$ read sys$command/error=get_name_error/prompt="''p1': " answer
$ answer = f$edit(answer,"TRIM,COMPRESS")
$ if ((answer .eqs. "") .and. keep) then exitt 1
$ if (answer .eqs. "") then goto get_name_ask
$ if (answer .eqs. "?") then goto get_name_help
$ if (f$length(answer) .gt. f$integer(p2))
$ then
$   err W TOOLONG "names over ''p2' characters cannot be used"
$   goto get_name_ask
$ endif
$ if (f$locate("""",answer) .lt. f$length(answer))
$ then
$   err W BADNAME "names cannot contain quotation marks"
$   goto get_name_ask
$ endif
$ name_answer == answer
$ exitt 1
$get_name_error:
$ say f$message($status)
$ exitt 4
$ endsubroutine
$
$ ! Subroutine: get_password
$ !
$ ! Ask for a new password, twice, and return its MD5 hash in the global
$ ! symbol password_hash; empty if MD5 did not give one.  The password
$ ! itself does not leave the subroutine.
$ !
$ !	P1	The prompt for the first of the two.
$ !
$get_password: subroutine
$ set noon
$ password_hash == ""
$ goto get_password_ask
$get_password_help:
$ say ""
$ say "  It is necessary to specify a password to protect your account."
$get_password_valid:
$ say ""
$ say "  To ensure password safety it is recommended that you use as many"
$ say "  different characters as possible.  Also steer clear of dictionary"
$ say "  words, and dictionary words followed by a number."
$ say ""
$ say "  Your password will NEVER be given out.  It is only stored in"
$ say "  encrypted form.  The only restriction placed on passwords is"
$ say "  that they are 8 characters or longer."
$ say ""
$get_password_ask:
$ set terminal/noecho
$ read sys$command/error=get_password_error/prompt="''p1'" answer
$ say ""
$ set terminal/echo
$ answer = f$edit(answer,"TRIM")
$ if (answer .eqs. "") then goto get_password_ask
$ if (answer .eqs. "?") then goto get_password_help
$ if (f$length(answer) .lt. 8) then goto get_password_valid
$ password = answer
$
$ set terminal/noecho
$ read sys$command/error=get_password_error/prompt="Confirm password: " answer
$ say ""
$ set terminal/echo
$ answer = f$edit(answer,"TRIM")
$ if (answer .nes. password)
$ then
$   err E MISMATCH "passwords do not match"
$   goto get_password_ask
$ endif
$
$ ! MD5 leaves its hash in MD5_MD5, a local symbol of this level.  It is
$ ! cleared first, so that one from an earlier run cannot pass for this.
$ md5_md5 = ""
$ getmd5 'password'
$ password_hash == md5_md5
$ exitt 1
$get_password_error:
$ set terminal/echo
$ say f$message($status)
$ exitt 4
$ endsubroutine
$
$ ! Subroutine: verify_password
$ !
$ ! Ask for the current password.  The global symbol password_ok is true
$ ! if it is the right one.
$ !
$ !	P1	The account's password hash.
$ !
$verify_password: subroutine
$ set noon
$ password_ok == 0
$ set terminal/noecho
$ read sys$command/error=verify_password_error/prompt="Current password: " answer
$ say ""
$ set terminal/echo
$ answer = f$edit(answer,"TRIM")
$ if (answer .eqs. "") then exitt 1
$ md5_md5 = ""
$ getmd5 'answer'
$ if ((md5_md5 .nes. "") .and. (md5_md5 .eqs. p1)) then password_ok == 1
$ if (.not. password_ok) then err E AUTHFAIL "the password is incorrect"
$ exitt 1
$verify_password_error:
$ set terminal/echo
$ say f$message($status)
$ exitt 4
$ endsubroutine
$
$ ! Subroutine: put_field
$ !
$ ! Put a value into a field of zk_record, the global symbol holding the
$ ! signed-in account's record.  uaf_update writes it to the file.
$ !
$ !	P1	The field's offset.
$ !	P2	The field's size.
$ !	P3	The value, blank filled or cut short to fit.  Leave it out
$ !		to blank the field.
$ !
$put_field: subroutine
$ set noon
$ offset = f$integer(p1)
$ size = f$integer(p2)
$ field = f$fao("!#* ",size)
$ if (p3 .nes. "") then field = f$fao("!#AS",size,p3)
$ zk_record == f$extract(0,offset,zk_record) + field + -
	      f$extract(offset+size,f$length(zk_record),zk_record)
$ exitt 1
$ endsubroutine
$
$ ! Subroutine: uaf_update
$ !
$ ! Write zk_record back to the file.  The update drops the record's
$ ! lock, so the record is read again to take it back, into zk_record.
$ !
$ !	P1	The account's username.
$ !
$uaf_update: subroutine
$ set noon
$ key = f$fao("!#AS",zk_s_user,p1)
$ write/update/symbol/error=uaf_update_write uaf zk_record
$ read/index=0/key="''key'"/match=eq/error=uaf_update_read uaf record
$ zk_record == record
$ exitt 1
$uaf_update_write:
$ message = "-" + f$message($status) - "%"
$ err F UAFWRITE "unable to write UAF file"
$ saysym message
$ exitt 4
$uaf_update_read:
$ message = "-" + f$message($status) - "%"
$ err F UAFREAD "unable to read UAF file"
$ saysym message
$ exitt 4
$ endsubroutine
$
$ ! Subroutine: format_date
$ !
$ ! A date as dd-MMM-yyyy hh:mm, in the global symbol fmt_date.
$ !
$ !	P1	The date, an F$CVTIME comparison time (yyyy-mm-dd
$ !		hh:mm:ss.cc).  A blank one comes back empty.
$ !
$format_date: subroutine
$ set noon
$ fmt_date == ""
$ if (f$edit(p1,"COLLAPSE") .eqs. "") then exitt 1
$ month = f$element(f$integer(f$extract(5,2,p1)),"/",-
		"/JAN/FEB/MAR/APR/MAY/JUN/JUL/AUG/SEP/OCT/NOV/DEC")
$ fmt_date == f$fao("!2UL-!AS-!AS !AS",f$integer(f$extract(8,2,p1)),-
		month,f$extract(0,4,p1),f$extract(11,5,p1))
$ exitt 1
$ endsubroutine
$
$ ! Subroutine: find_saves
$ !
$ ! Count the saved games in a directory, into the global symbol
$ ! save_count, with the name and the date last saved of each in
$ ! save_name_n and save_date_n.  Only the highest version of each is
$ ! looked at.  The search has a stream of its own and is always run to
$ ! its end, so that the next one starts afresh.
$ !
$ !	P1	The directory.
$ !
$find_saves: subroutine
$ set noon
$ save_count == 0
$find_saves_next:
$ file = f$search(p1 + "*.ZKO;",1)
$ if (file .eqs. "") then exitt 1
$ save_count == save_count + 1
$ save_name_'save_count' == f$parse(file,,,"NAME")
$ save_date_'save_count' == f$file_attributes(file,"RDT")
$ goto find_saves_next
$ endsubroutine
$
$ procedure = f$element(0,";",f$environment("PROCEDURE"))
$ procedure_name = f$parse(procedure,,,"NAME")
$ facility = "ZKLOGIN"
$ location = f$parse(procedure,,,"DEVICE","NO_CONCEAL") -
		+ f$parse(procedure,,,"DIRECTORY","NO_CONCEAL") - "]["
$
$ @sys$common:[perl-5_6_2]perl_setup
$ if (f$mode() .nes. "INTERACTIVE") then -
$    exitt 1.or.(0*f$verify(__vfy_saved))
$
$ set noon
$ set symbol/scope=(nolocal)
$ set nocontrol=(y,t)
$ set terminal/line_edit/insert/wrap/eight/notab-
        /application/form/device=vt100/nobroadcast
$ on error then goto bail_out
$
$ _arch_type = f$getsyi("ARCH_TYPE")
$ _arch_name = f$element(_arch_type,",","OTHER,VAX,ALPHA,I64") - ","
$ _vax = (_arch_type .eq. 1)
$ _axp = (_arch_type .eq. 2)
$ _i64 = (_arch_type .eq. 3)
$ _other = (.not. (_vax .or. _axp .or. _i64))
$
$ ask = "read sys$command/error=err_prompt/prompt="
$ say = "write sys$output"
$ err = "call___ err"
$ saysym = "write/symbol sys$output"
$
$ esc[0,8]	= %X1B
$ csi[0,8]	= %X9B
$ clear_screen	= csi + "2J"
$ define_scroll	= csi + "5;24r"
$ double_width	= esc + "#6"
$ full_screen	= csi + "1;24r"
$ home_cursor	= csi + "1;1H"
$ single_width	= esc + "#5"
$ top_of_scroll	= csi + "5;1H"
$
$!@sys$library:$rmsdef
$ RMS$_RNF = 98994
$ RMS$_RLK = 98986
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
$ zk_s_lgic  = 10
$ zk_i_lgic  = 0
$ zk_l_first = zk_l_lgic + zk_s_lgic            ! First Name
$ zk_s_first = 32
$ zk_t_first = ""
$ zk_l_last  = zk_l_first + zk_s_first          ! Last Name
$ zk_s_last  = 32
$ zk_t_last  = ""
$ zk_l_pdt   = zk_l_last + zk_s_last            ! Date of last password change
$ zk_s_pdt   = 22
$ zk_n_pdt   = ""
$ zk_l_link  = zk_l_pdt + zk_s_pdt              ! Linked account's username
$ zk_s_link  = 64
$ zk_t_link  = ""
$ zk_l_rst   = zk_l_link + zk_s_link            ! Date the last reset code was sent
$ zk_s_rst   = 22
$ zk_n_rst   = ""
$ zk_l_spare = zk_l_rst + zk_s_rst              ! Spare
$ zk_s_spare = 154
$ zk_t_spare = f$fao("!#* ", zk_s_spare)
$
$ ! The date of the login before this one, kept only while signed in.
$ !
$ zk_n_prev  = ""
$
$init:
$ zk_t_default = f$environment("DEFAULT") - "]"
$ getmd5 ="$" + zk_t_default + ".EXE.''_arch_name']MD5"
$ getuid ="$" + zk_t_default + ".EXE.''_arch_name']UID"
$
$reset:
$ zk_t_logged_in = "N"
$ reset_code = ""				! see forgot
$ reset_for = ""
$ reset_expires = ""
$
$start:
$ say clear_screen
$ type sys$input:
$ deck
    Welcome to...
										
       ********** **                **      **            **  **
      /////**/// /**               /**     /**           /** /**
          /**    /**       *****   /**     /**  ******   /** /**  ******
          /**    /******  **///**  /********** //////**  /** /** **////
          /**    /**///**/*******  /**//////**  *******  /** /**//*****
          /**    /**  /**/**////   /**     /** **////**  /** /** /////**
          /**    /**  /**//******  /**     /**//******** *** *** ******
          //     //   //  //////   //      //  //////// /// /// //////
		                ****   ******** **   **
                               /**/   //////** /**  **
                      ******  ******       **  /** **
                     **////**///**/       **   /****
                    /**   /**  /**       **    /**/**
                    /**   /**  /**      **     /**//**
                    //******   /**     ********/** //**
                     //////    //     //////// //   //

$ eod
$ if (zk_t_logged_in)
$ then
$   type sys$input:
$   deck
                        [1] Play the game
                        [2] Account maintenance
                        [3] Exit

$   eod
$ else
$ type sys$input
$ deck
                        [1] Sign-in to an existing account
                        [2] Register a new account
                        [3] Forgotten your password
                        [4] Exit

$ eod
$ endif ! zk_t_logged_in
$
$ ask " Please choose an option: [1] " answer
$ answer = f$extract(0,1,f$edit(answer,"UPCASE,UNCOMMENT,TRIM,COLLAPSE"))
$ if (answer .eqs. "") then answer = "1"
$ if (zk_t_logged_in)
$ then
$   if (answer .eqs. "1") then goto play
$   if (answer .eqs. "2") then goto maintain
$   if (answer .eqs. "3") then goto bail_out
$ else
$   if (answer .eqs. "1") then goto sign_in
$   if (answer .eqs. "2") then goto register
$   if (answer .eqs. "3") then goto forgot
$   if (answer .eqs. "4") then goto bail_out
$ endif
$ goto start
$
$register:
$ say clear_screen
$ say ""
$ say "                     Account Registration"
$ say ""
$ say "  To use this system it is necessary to register a user access"
$ say "  account.  This allows you to save your progress and return to"
$ say "  it later."
$ say ""
$ goto ask_email
$
$help_email:
$ say ""
$ say "  To ensure separate accounts for all ZK users it is necessary to"
$ say "  register your account with your email address.  In providing"
$ say "  your email address we will guard it appropriately.  Under no"
$ say "  circumstances will it be provided to any third-party."
$ say ""
$ say "  Your email will only be used to verify your account and possibly"
$ say "  contact you regarding any changes to this service."
$help_email_valid:
$ say ""
$ say "  An email must be of the form user@domain.  This email is also"
$ say "  tested for validity, so you must specify a valid email address."
$ say ""
$ask_email:
$ ask "Email address: " answer
$ answer = f$edit(answer, "TRIM,COLLAPSE,LOWERCASE")
$ if (answer .eqs. "") then goto ask_email
$ if (f$extract(0,1,answer) .eqs. "?") then goto help_email
$ if (f$length(answer) .gt. zk_s_user)
$ then
$   err W TOOLONG "email addresses over ''zk_s_user' characters cannot be used"
$   goto ask_email
$ endif
$ zk_t_user = answer
$ domain = f$element(1,"@",zk_t_user)
$ if (domain .eqs. "") then goto help_email_valid
$ if (domain .eqs. "@") then goto help_email_valid
$ define/user sys$error nla0:
$ define/user sys$output nla0:
$ ucx show mx_record 'domain'
$ if (.not. $status) then goto help_email_valid
$
$ ! Is it taken?  /NOLOCK, as the account may be in play, holding its lock.
$ key = f$fao("!#AS",zk_s_user,zk_t_user)
$ close/nolog uaf
$ open/read/share=write/error=err_uafopen uaf 'zk_t_default']ZKUAF.DAT
$ read/nolock/index=0/key="''key'"/match=eq/error=email_rnf uaf record
$ close/nolog uaf
$ err W EXISTS "an account for this email address already exists"
$ goto ask_email
$email_rnf:
$ status = $status
$ if (status .ne. RMS$_RNF) then goto err_uafread_status
$ close/nolog uaf
$ call get_name "First name" 'zk_s_first'
$ if (.not. $status) then goto bail_out
$ zk_t_first = name_answer
$ call get_name "Last name" 'zk_s_last'
$ if (.not. $status) then goto bail_out
$ zk_t_last = name_answer
$ call get_password "Password: "
$ if (.not. $status) then goto bail_out
$ if (password_hash .eqs. "")
$ then
$   err F NOHASH "that password cannot be used"
$   goto bail_out
$ endif
$
$complete_register:
$ key = f$fao("!#AS",zk_s_user,zk_t_user)
$ close/nolog uaf
$ open/read/write/share=write/error=err_uafopen uaf 'zk_t_default']ZKUAF.DAT
$ read/nolock/index=0/key="''key'"/match=eq -
      /end_of_file=register_rnf/error=register_rnf uaf record
$ goto err_exists
$register_rnf:
$ status = $status
$ if (status .ne. RMS$_RNF) then goto err_uafread_status
$ getuid
$ zk_t_uid  = uid_uid
$ zk_t_hash = password_hash
$ zk_n_cdt  = f$cvtime(,"COMPARISON")
$ zk_n_rdt  = f$cvtime(,"COMPARISON")
$ zk_i_lgic = 1
$ zk_n_pdt  = zk_n_cdt
$ zk_n_prev = ""
$ record = f$fao("!#AS!AS!AS!AS!AS!#UL!#AS!#AS",-
		 zk_s_user,zk_t_user,zk_t_uid,zk_t_hash,zk_n_cdt,-
		 zk_n_rdt,zk_s_lgic,zk_i_lgic,zk_s_first,zk_t_first,-
		 zk_s_last,zk_t_last) + zk_n_pdt + -
	   f$fao("!#* ",zk_s_link) + f$fao("!#* ",zk_s_rst) + zk_t_spare
$ write/symbol/error=err_uafwrite uaf record
$
$ ! Lock the record and leave the file open, as a sign-in does: the
$ ! account is in play from here on.
$ read/index=0/key="''key'"/match=eq/error=err_uafread uaf record
$ zk_record == record
$ create/directory 'zk_t_default'.USERS.'zk_t_uid']
$ ! register with mailing list
$ zk_t_logged_in = "Y"
$ say ""
$ err S CREATED "you have successfully created your account"
$ say ""
$ ask " Please press RETURN to continue" answer
$ goto start
$
$ ! Account maintenance.  The record is locked on UAF by the sign-in, or
$ ! by registering, and the global symbol zk_record is what the file
$ ! holds.  Every change is made to it by put_field and written back by
$ ! uaf_update.
$ !
$maintain:
$ zk_t_hash  = f$extract(zk_l_hash, zk_s_hash, zk_record)
$ zk_n_cdt   = f$extract(zk_l_cdt,  zk_s_cdt,  zk_record)
$ zk_i_lgic  = f$integer(f$extract(zk_l_lgic, zk_s_lgic, zk_record))
$ zk_t_first = f$edit(f$extract(zk_l_first,zk_s_first,zk_record),"TRIM")
$ zk_t_last  = f$edit(f$extract(zk_l_last, zk_s_last, zk_record),"TRIM")
$ zk_n_pdt   = f$extract(zk_l_pdt,  zk_s_pdt,  zk_record)
$ zk_t_link  = f$edit(f$extract(zk_l_link, zk_s_link, zk_record),"TRIM")
$
$ call format_date "''zk_n_prev'"
$ last_login = fmt_date
$ if (last_login .eqs. "") then last_login = "None before this one"
$
$ ! An account from before V1-003 has no date here until its password
$ ! is changed: it has had the one password since it was created.
$ if (f$edit(zk_n_pdt,"COLLAPSE") .eqs. "") then zk_n_pdt = zk_n_cdt
$ call format_date "''zk_n_pdt'"
$ password_changed = fmt_date
$
$ phone_linked = "No"
$ link_option = "Link to your phone account"
$ if (zk_t_link .nes. "")
$ then
$   phone_linked = "Yes"
$   link_option = "Unlink your phone account"
$ endif
$
$ ! Saved games are only offered when there are some, and returning to
$ ! the main menu is always the last option.
$ call find_saves 'zk_t_default'.USERS.'zk_t_uid']
$ return_option = "4"
$ if (save_count .gt. 0) then return_option = "5"
$
$ say clear_screen
$ say ""
$ say "                       Account Maintenance"
$ say ""
$ say "              Name:              " + zk_t_first + " " + zk_t_last
$ say "              Last login:        " + last_login
$ say "              Password changed:  " + password_changed
$ say f$fao("              Login count:       !UL",zk_i_lgic)
$ say "              Phone linked:      " + phone_linked
$ say ""
$ say "                        [1] Change your password"
$ say "                        [2] Change your name"
$ say "                        [3] " + link_option
$ if (save_count .gt. 0) then -
$    say "                        [4] Manage your saved games"
$ say "                        [" + return_option + "] Return to the main menu"
$ say ""
$ ask " Please choose an option: [''return_option'] " answer
$ answer = f$extract(0,1,f$edit(answer,"UPCASE,UNCOMMENT,TRIM,COLLAPSE"))
$ if (answer .eqs. "") then answer = return_option
$ if (answer .eqs. "1") then goto maintain_password
$ if (answer .eqs. "2") then goto maintain_name
$ if ((answer .eqs. "3") .and. (zk_t_link .eqs. "")) then goto maintain_link
$ if (answer .eqs. "3") then goto maintain_unlink
$ if (answer .eqs. return_option) then goto start
$ if (answer .eqs. "4") then goto maintain_saves
$ goto maintain
$
$maintain_done:
$ say ""
$ ask "  Please press RETURN to continue" answer
$ goto maintain
$
$maintain_password:
$ say ""
$ call verify_password "''zk_t_hash'"
$ if (.not. $status) then goto bail_out
$ if (.not. password_ok) then goto maintain_done
$ call get_password "New password: "
$ if (.not. $status) then goto bail_out
$ if (password_hash .eqs. "")
$ then
$   err E NOTCHANGED "that password cannot be used; yours is not changed"
$   goto maintain_done
$ endif
$ now = f$cvtime(,"COMPARISON")
$ call put_field 'zk_l_hash' 'zk_s_hash' "''password_hash'"
$ call put_field 'zk_l_pdt' 'zk_s_pdt' "''now'"
$ call uaf_update "''zk_t_user'"
$ if (.not. $status) then goto bail_out
$ say ""
$ err S PWDCHANGED "your password has been changed"
$ goto maintain_done
$
$maintain_name:
$ say ""
$ say "  Your name is " + zk_t_first + " " + zk_t_last + ".  Press RETURN alone"
$ say "  to keep your first or your last name as it is."
$ say ""
$ changed = 0
$ call get_name "First name" 'zk_s_first' KEEP
$ if (.not. $status) then goto bail_out
$ if (name_answer .nes. "")
$ then
$   call put_field 'zk_l_first' 'zk_s_first' "''name_answer'"
$   changed = 1
$ endif
$ call get_name "Last name" 'zk_s_last' KEEP
$ if (.not. $status) then goto bail_out
$ if (name_answer .nes. "")
$ then
$   call put_field 'zk_l_last' 'zk_s_last' "''name_answer'"
$   changed = 1
$ endif
$ if (.not. changed) then goto maintain
$ call uaf_update "''zk_t_user'"
$ if (.not. $status) then goto bail_out
$ say ""
$ err S NAMECHANGED "your name has been changed"
$ goto maintain_done
$
$ ! Link to a phone account, a PHONE:nnnnnn record of ZK$PHONE's.  Its
$ ! passcode is all a caller needs to play it, so it is all that is asked
$ ! for here.  Each record gets the other's username.  The phone record
$ ! is read on a channel of its own, UAF2, so that the lock on this
$ ! account's record is kept.
$ !
$ ! ZK$PHONE plays a linked phone account from this account's directory
$ ! and under this account's name, so that a game saved at the terminal
$ ! can be restored on the phone and the other way about.  The phone's
$ ! saved games are moved in here when the link is made.
$ !
$maintain_link:
$ say ""
$ say "  If you also play ZK by telephone, you can link your phone account"
$ say "  to this one.  Your phone's saved games are then kept with the"
$ say "  games you save here, and you can play on from either."
$ say ""
$ say "  Enter the six digit passcode you were given when you first"
$ say "  called, or press RETURN alone to go back."
$ say ""
$ set terminal/noecho
$ ask "Phone passcode: " answer
$ say ""
$ set terminal/echo
$ answer = f$edit(answer,"COLLAPSE")
$ if (answer .eqs. "") then goto maintain
$
$ ! Six digits and nothing else: it goes into a key.
$ if (f$length(answer) .ne. 6) then goto link_unknown
$ i = 0
$link_digits:
$ if (f$locate(f$extract(i,1,answer),"0123456789") .eq. 10) then -
$    goto link_unknown
$ i = i + 1
$ if (i .lt. 6) then goto link_digits
$
$ link_user = "PHONE:" + answer
$ link_key = f$fao("!#AS",zk_s_user,link_user)
$ close/nolog uaf2
$ open/read/write/share=write/error=err_uafopen uaf2 'zk_t_default']ZKUAF.DAT
$ read/index=0/key="''link_key'"/match=eq/error=link_error uaf2 link_record
$ if (f$edit(f$extract(zk_l_link,zk_s_link,link_record),"COLLAPSE") .nes. "")
$ then
$   close/nolog uaf2
$   err E INUSE "that phone account is already linked to an account"
$   goto maintain_done
$ endif
$
$ ! This record first.  Should the phone record's update then fail, this
$ ! account can still be unlinked and nothing holds the phone account.
$ call put_field 'zk_l_link' 'zk_s_link' "''link_user'"
$ call uaf_update "''zk_t_user'"
$ if (.not. $status) then goto bail_out
$ link_uid = f$extract(zk_l_uid,zk_s_uid,link_record)
$ link_end = zk_l_link + zk_s_link
$ link_record = f$extract(0,zk_l_link,link_record) + -
		f$fao("!#AS",zk_s_link,zk_t_user) + -
		f$extract(link_end,f$length(link_record)-link_end,link_record)
$ write/update/symbol/error=err_uafwrite uaf2 link_record
$ close/nolog uaf2
$
$ ! Move the phone's saved games in.  They are copied, so that one with
$ ! the name of a game already here becomes its newest version, and the
$ ! phone's own are deleted only once the copy has worked.  With no
$ ! saved games the copy fails and there is nothing more to do.
$ link_saves = zk_t_default + ".USERS." + link_uid + "]*.ZKO"
$ define/user sys$error nla0:
$ define/user sys$output nla0:
$ copy/nolog 'link_saves'; 'zk_t_default'.USERS.'zk_t_uid']
$ if ($status)
$ then
$   define/user sys$error nla0:
$   define/user sys$output nla0:
$   delete/nolog 'link_saves';*
$ endif
$ say ""
$ err S LINKED "your phone account is now linked to this account"
$ goto maintain_done
$
$link_error:
$ status = $status
$ close/nolog uaf2
$ if (status .eq. RMS$_RNF) then goto link_unknown
$ if (status .eq. RMS$_RLK) then goto link_busy
$ goto err_uafread_status
$
$ ! The wait is to slow down anyone guessing at passcodes.
$link_unknown:
$ wait 00:00:03
$ err E NOPASSCODE "that passcode is not known"
$ goto maintain_done
$
$link_busy:
$ err W BUSY "that phone account is busy just now; please try again"
$ goto maintain_done
$
$ ! Unlink: the phone record first, and only if it is this account that
$ ! it names.  If it is busy nothing has been changed.  If it has gone
$ ! there is only this record to change.  The saved games stay here: the
$ ! phone account goes back to its own directory, with none.
$ !
$maintain_unlink:
$ say ""
$ say "  Your saved games stay with this account.  The phone will start"
$ say "  again with none, until it is linked once more."
$ say ""
$ ask "Unlink your phone account? (Y/N) [N] " answer
$ answer = f$extract(0,1,f$edit(answer,"UPCASE,TRIM"))
$ if (answer .nes. "Y") then goto maintain
$ link_key = f$fao("!#AS",zk_s_user,zk_t_link)
$ close/nolog uaf2
$ open/read/write/share=write/error=err_uafopen uaf2 'zk_t_default']ZKUAF.DAT
$ read/index=0/key="''link_key'"/match=eq/error=unlink_error uaf2 link_record
$ if (f$edit(f$extract(zk_l_link,zk_s_link,link_record),"TRIM") .eqs. zk_t_user)
$ then
$   link_end = zk_l_link + zk_s_link
$   link_record = f$extract(0,zk_l_link,link_record) + -
		  f$fao("!#* ",zk_s_link) + -
		  f$extract(link_end,f$length(link_record)-link_end,link_record)
$   write/update/symbol/error=err_uafwrite uaf2 link_record
$ endif
$unlink_own:
$ close/nolog uaf2
$ call put_field 'zk_l_link' 'zk_s_link'
$ call uaf_update "''zk_t_user'"
$ if (.not. $status) then goto bail_out
$ say ""
$ err S UNLINKED "your phone account is no longer linked to this account"
$ goto maintain_done
$
$unlink_error:
$ status = $status
$ close/nolog uaf2
$ if (status .eq. RMS$_RNF) then goto unlink_own
$ if (status .eq. RMS$_RLK) then goto link_busy
$ goto err_uafread_status
$
$ ! Saved games: list them, numbered, and delete the one chosen, in all
$ ! its versions.  Back to account maintenance once there are none left.
$ !
$maintain_saves:
$ call find_saves 'zk_t_default'.USERS.'zk_t_uid']
$ if (save_count .eq. 0) then goto maintain
$ say clear_screen
$ say ""
$ say "                           Saved Games"
$ say ""
$ i = 1
$saves_list:
$ save_date = save_date_'i'
$ say f$fao("          [!2UL] !39AS !AS",i,save_name_'i',-
	    f$extract(0,f$length(save_date)-6,save_date))
$ i = i + 1
$ if (i .le. save_count) then goto saves_list
$ say ""
$ ask " Delete which saved game? (RETURN alone to go back) " answer
$ answer = f$edit(answer,"COLLAPSE")
$ if (answer .eqs. "") then goto maintain
$ if (f$type(answer) .nes. "INTEGER") then goto maintain_saves
$ i = f$integer(answer)
$ if ((i .lt. 1) .or. (i .gt. save_count)) then goto maintain_saves
$ save_name = save_name_'i'
$ ask " Delete ''save_name'? (Y/N) [N] " answer
$ answer = f$extract(0,1,f$edit(answer,"UPCASE,TRIM"))
$ if (answer .nes. "Y") then goto maintain_saves
$ save_file = zk_t_default + ".USERS." + zk_t_uid + "]" + save_name + ".ZKO;*"
$ define/user sys$error nla0:
$ define/user sys$output nla0:
$ delete/nolog 'save_file'
$ if (.not. $status)
$ then
$   err E NOTDELETED "''save_name' could not be deleted"
$   say ""
$   ask "  Please press RETURN to continue" answer
$ endif
$ goto maintain_saves
$
$ ! Forgotten password.  A code is mailed to the account's address and,
$ ! entered here in the same session within 15 minutes, lets a new
$ ! password be set.  The code is kept only in this process, for the one
$ ! address it was sent to.  What is shown is the same whether or not
$ ! there is an account, so that this cannot be used to find out which
$ ! addresses have one; with none, no code is right.  At most one code
$ ! is sent to an account every 10 minutes (ZK_N_RST), so that no one
$ ! can flood an address with them.  The wait after a wrong code, and
$ ! the three tries, are to slow down anyone guessing.
$ !
$forgot:
$ say clear_screen
$ say ""
$ say "                        Forgotten Password"
$ say ""
$ say "  Enter the email address you registered with.  A code will be"
$ say "  mailed to it, to enter here so that you can set a new password."
$ say "  Press RETURN alone to go back."
$ say ""
$forgot_email:
$ ask "Email address: " answer
$ answer = f$edit(answer,"TRIM,COLLAPSE,LOWERCASE")
$ if (answer .eqs. "") then goto start
$ if ((f$locate("@",answer) .eq. f$length(answer)) .or. -
      (f$locate("""",answer) .lt. f$length(answer)) .or. -
      (f$length(answer) .gt. zk_s_user))
$ then
$   err W BADEMAIL "that is not an email address"
$   goto forgot_email
$ endif
$
$ ! A code already sent in this session, to this address, still stands
$ if (answer .nes. reset_for) then reset_code = ""
$ if (reset_code .nes. "") then goto forgot_sent
$ reset_for = answer
$
$ ! /NOLOCK to look, as the account may be in play.  The record is only
$ ! locked to note the time, once the mail has gone; if it is in play
$ ! the account's owner is signed in, and nothing is sent.
$ key = f$fao("!#AS",zk_s_user,reset_for)
$ close/nolog uaf
$ open/read/write/share=write/error=err_uafopen uaf 'zk_t_default']ZKUAF.DAT
$ read/nolock/index=0/key="''key'"/match=eq/error=forgot_rnf uaf record
$ zk_n_rst = f$extract(zk_l_rst,zk_s_rst,record)
$ if (f$edit(zk_n_rst,"COLLAPSE") .nes. "")
$ then
$   if (zk_n_rst .gts. f$cvtime("-0-00:10:00.00","COMPARISON")) then -
	goto forgot_quiet
$ endif
$ read/index=0/key="''key'"/match=eq/error=forgot_quiet uaf record
$ zk_record == record
$
$ ! The code: the first 8 of an MD5 hash of a new UID, the time and this
$ ! process's PID.  It is entered without regard to case.
$ getuid
$ seed = f$edit(uid_uid + f$cvtime(,"COMPARISON") + f$getjpi("","PID"),"COLLAPSE")
$ md5_md5 = ""
$ getmd5 'seed'
$ if (md5_md5 .eqs. "") then goto forgot_quiet
$ code = f$edit(f$extract(0,8,md5_md5),"UPCASE")
$
$ reset_mail = "SYS$SCRATCH:ZKRESET_''f$getjpi("","PID")'.TXT"
$ open/write/error=forgot_quiet mailf 'reset_mail'
$ write mailf "Someone asked to reset the password of your account on The"
$ write mailf "Halls of ZK, ''reset_for'.  If it was you, enter this code"
$ write mailf "at the Reset code prompt:"
$ write mailf ""
$ write mailf "    ''code'"
$ write mailf ""
$ write mailf "It works for 15 minutes, and only in the session that asked"
$ write mailf "for it.  If you did not ask, there is nothing to do: your"
$ write mailf "password has not been changed."
$ close mailf
$ define/user sys$output nla0:
$ define/user sys$error nla0:
$ mail/noself/subject="Halls of ZK password reset" 'reset_mail' -
	"SMTP%""''reset_for'"""
$ mail_status = $status
$ delete/nolog 'reset_mail';*
$ if (.not. mail_status) then goto forgot_quiet
$
$ ! Sent: note when, so that the next can't follow for 10 minutes
$ now = f$cvtime(,"COMPARISON")
$ call put_field 'zk_l_rst' 'zk_s_rst' "''now'"
$ call uaf_update "''reset_for'"
$ if (.not. $status) then goto bail_out
$ close/nolog uaf
$ reset_code = code
$ reset_expires = f$cvtime("+0-00:15:00.00","COMPARISON")
$ goto forgot_sent
$
$forgot_rnf:
$ status = $status
$ if (status .ne. RMS$_RNF) then goto err_uafread_status
$forgot_quiet:
$ close/nolog uaf
$
$forgot_sent:
$ say ""
$ say "  If there is an account for that address, a code has been mailed"
$ say "  to it.  It may take a few minutes to arrive.  Enter it here, or"
$ say "  press RETURN alone to go back."
$ say ""
$ tries = 0
$forgot_code:
$ ask "Reset code: " answer
$ answer = f$edit(answer,"COLLAPSE,UPCASE")
$ if (answer .eqs. "") then goto start
$ ! An expired code is told as a wrong one, as only an account has one.
$ ! The third wrong try ends the code too.
$ if (f$cvtime(,"COMPARISON") .gts. reset_expires) then reset_code = ""
$ if ((reset_code .eqs. "") .or. (answer .nes. reset_code))
$ then
$   wait 00:00:03
$   err E BADCODE "that code is not right, or has expired"
$   tries = tries + 1
$   if (tries .lt. 3) then goto forgot_code
$   reset_code = ""
$   goto forgot_done
$ endif
$
$ ! The code is right, and is used up
$ reset_code = ""
$ say ""
$ call get_password "New password: "
$ if (.not. $status) then goto bail_out
$ if (password_hash .eqs. "")
$ then
$   err E NOTCHANGED "that password cannot be used; yours is not changed"
$   goto forgot_done
$ endif
$ key = f$fao("!#AS",zk_s_user,reset_for)
$ close/nolog uaf
$ open/read/write/share=write/error=err_uafopen uaf 'zk_t_default']ZKUAF.DAT
$ read/index=0/key="''key'"/match=eq/error=forgot_lock uaf record
$ zk_record == record
$ call put_field 'zk_l_hash' 'zk_s_hash' "''password_hash'"
$ now = f$cvtime(,"COMPARISON")
$ call put_field 'zk_l_pdt' 'zk_s_pdt' "''now'"
$ call uaf_update "''reset_for'"
$ if (.not. $status) then goto bail_out
$ close/nolog uaf
$ say ""
$ err S PWDCHANGED "your password has been changed; please sign in with it"
$forgot_done:
$ say ""
$ ask "  Please press RETURN to continue" answer
$ goto start
$
$forgot_lock:
$ status = $status
$ close/nolog uaf
$ if (status .ne. RMS$_RLK) then goto err_uafread_status
$ err W INUSE "this account is signed in elsewhere; your password is not changed"
$ goto forgot_done
$
$sign_in:
$ say clear_screen
$ goto ask_login
$
$ask_login:
$ say ""
$ say "                          Account Login"
$ say ""
$ say "  Enter a registered email address to log in and play ZK!"
$ say ""
$ask_username:
$ ask "Email address: " answer
$ answer = f$edit(answer, "TRIM,COLLAPSE,LOWERCASE")
$ if (answer .eqs. "") then goto ask_username
$ username = answer
$
$ set terminal/noecho
$ ask "Password: " answer
$ say ""
$ set terminal/echo
$ password = f$edit(answer,"TRIM")
$
$ key = f$fao("!#AS",zk_s_user,username)
$ open/read/write/share=write/error=err_uafopen uaf 'zk_t_default']ZKUAF.DAT
$ read/nolock/index=0/key="''key'"/match=eq -
      /end_of_file=err_authfail/error=signin_rnf uaf record
$ 
$ zk_t_user  = f$edit(f$extract(zk_l_user, zk_s_user, record),"TRIM")
$ zk_t_uid   = f$extract(zk_l_uid,  zk_s_uid,  record)
$ zk_t_hash  = f$extract(zk_l_hash, zk_s_hash, record)
$ zk_n_cdt   = f$extract(zk_l_cdt,  zk_s_cdt,  record)
$ zk_n_rdt   = f$extract(zk_l_rdt,  zk_s_rdt,  record)
$ zk_i_lgic  = f$integer(f$extract(zk_l_lgic, zk_s_lgic, record))
$ zk_t_first = f$edit(f$extract(zk_l_first,zk_s_first,record),"TRIM")
$ zk_t_last  = f$edit(f$extract(zk_l_last, zk_s_last, record),"TRIM")
$
$ getmd5 'password'
$
$ if (zk_t_hash .nes. md5_md5) then goto err_authfail
$
$
$ ! The password is right: now lock the record, and hold the lock while
$ ! this sign-in is in play.  RLK is another sign-in holding it.  Only a
$ ! caller with the password learns that.
$ read/index=0/key="''key'"/match=eq/error=signin_lock uaf record
$
$ ! One more login, and when.  The update drops the lock, so read the
$ ! record again to take it back.  The login before this one is kept,
$ ! for account maintenance to show.
$ zk_n_prev = f$extract(zk_l_rdt, zk_s_rdt, record)
$ zk_i_lgic = f$integer(f$extract(zk_l_lgic, zk_s_lgic, record)) + 1
$ zk_n_rdt  = f$cvtime(,"COMPARISON")
$ record = f$extract(0,zk_l_rdt,record) + zk_n_rdt + -
	   f$fao("!#UL",zk_s_lgic,zk_i_lgic) + -
	   f$extract(zk_l_first,f$length(record)-zk_l_first,record)
$ write/update/symbol/error=err_uafwrite uaf record
$ read/index=0/key="''key'"/match=eq/error=signin_lock uaf record
$ zk_record == record			! for account maintenance
$ zk_t_logged_in = "Y"
$ err S LOGIN "you successfully logged in"
$ goto start
$
$signin_rnf:
$ status = $status
$ if (status .eq. RMS$_RNF) then goto err_authfail
$ goto err_uafread_status
$
$signin_lock:
$ status = $status
$ if (status .eq. RMS$_RLK) then goto err_inuse
$ goto err_uafread_status
$
$play:
$ save_spec = "''zk_t_default'.USERS.''zk_t_uid']*.ZKO"
$ if (f$search(save_spec) .nes. "")
$ then
$    err I SAVED "current saved games"
$    directory 'save_spec' -
	      /notrailing/noheading/date=modified/width=(file=36)/nosize -
	      /select=file=(nonode,nodevice,nodirectory,name,notype,noversion)
$ else
$    err I NOSAVED "you have no currently saved games"
$ endif
$ ask "    Press RETURN to continue..." answer
$
$ define/job/nolog ZK$MULTI_USER "''zk_t_first' ''zk_t_last'"
$ set default 'zk_t_default'.USERS.'zk_t_uid']
$ assign/user sys$command sys$input
$ zk
$ if (f$search("*.ZKO") .nes. "") then -
$    purge/nolog *.ZKO
$ set default sys$login:
$
$ ask "  Please press RETURN to continue" answer
$ goto start
$
$err_uafopen:
$ message = "-" + f$message($status) - "%"
$ err F UAFOPEN "unable to open UAF file"
$ saysym message
$ goto bail_out
$
$err_uafread:
$ status = $status
$err_uafread_status:
$ message = "-" + f$message(status) - "%"
$ err F UAFREAD "unable to read UAF file"
$ saysym message
$ goto bail_out
$
$err_uafwrite:
$ message = "-" + f$message($status) - "%"
$ err F UAFWRITE "unable to write UAF file"
$ saysym message
$ goto bail_out
$
$err_exists:
$ close/nolog uaf
$ err F EXISTS "an account for this email address already exists"
$ ask "  Press RETURN to continue" answer
$ goto start
$
$err_inuse:
$ close/nolog uaf
$ err E INUSE "this account is already signed in elsewhere"
$ ask "  Press RETURN to continue" answer
$ goto start
$
$err_authfail:
$ close/nolog uaf
$ err F AUTHFAIL "the username and/or password is incorrect"
$ ask "  Press RETURN to continue" answer
$ goto start
$
$err_prompt:
$ say f$message($status)
$ goto bail_out
$
$bail_out:
$ close/nolog uaf2
$ close/nolog uaf
$!$ exitt 1.or.(0*f$verify(__vfy_saved))
$ logout
$ !+==========================================================================
$ !
$ ! Procedure:	LOGIN.COM
$ !
$ ! Purpose:	Login procedure for ZK...
$ !
$ ! Parameters:	None.
$ !
$ ! History:
$ !		26-JUN-2013, TES; Version V1-001
$ !	001 -	Original version.
$ !
$ !		12-NOV-2026, TES; Version V1-002
$ !	002 -	Count logins and record the last one.  Email addresses are
$ !		lower case, at most 64 characters, and checked for an
$ !		existing account before anything else is asked.  Fixed the
$ !		err_uafread label, zk_l_spare and the prompts.  A second
$ !		sign-in to an account in play is told so, once its password
$ !		is right.
$ !
$ !		21-NOV-2026, TES; Version V1-003
$ !	003 -	Account maintenance: shows the name, the login before this
$ !		one, when the password was last changed, the login count
$ !		and whether a phone account is linked; changes the password
$ !		or the name; links and unlinks a phone account by its
$ !		passcode; lists the saved games, when there are any, and
$ !		deletes them.  The date of the last password change and the
$ !		linked account's username are new fields, taken from the
$ !		spare.  The prompts and the record updates are subroutines,
$ !		called with arguments.  Linking moves the phone's saved
$ !		games in with the account's, for ZK$PHONE to play from.
$ !		Names must fit their fields and have no quotation marks.  A
$ !		new account's record is locked, as a sign-in's is.
$ !
$ !		22-NOV-2026, TES; Version V1-004
$ !	004 -	Forgotten password: a code mailed to the account's address,
$ !		entered in the same session within 15 minutes, sets a new
$ !		one.  At most one code every 10 minutes for an account; the
$ !		date it was sent is a new field, taken from the spare.  The
$ !		phone record is rebuilt around the link field alone, not up
$ !		to the spare, so that the fields after it are kept.
$ !-==========================================================================
