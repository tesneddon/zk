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
$ procedure = f$element(0,";",f$environment("PROCEDURE"))
$ procedure_name = f$parse(procedure,,,"NAME")
$ facility = "ZKLOGIN"
$ location = f$parse(procedure,,,"DEVICE","NO_CONCEAL") -
		+ f$parse(procedure,,,"DIRECTORY","NO_CONCEAL") - "]["
$
$ if (f$mode() .eqs. "NETWORK") then -
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
$ zk_l_spare = zk_t_last + zk_s_last            ! Spare
$ zk_s_spare = 262
$ zk_t_spare = f$fao("!#* ", zk_s_spare)
$
$init:
$ zk_t_default = f$environment("DEFAULT") - "]"
$ getmd5 ="$" + zk_t_default + ".EXE]MD5"
$ getuid ="$" + zk_t_default + ".EXE]UID"
$
$reset:
$ zk_t_logged_in = "N"
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
                        [3] Exit

$ eod
$ endif ! zk_t_logged_in
$
$ ask " Please chose an option: [1] " answer
$ answer = f$extract(0,1,f$edit(answer,"UPCASE,UNCOMMENT,TRIM,COLLAPSE"))
$ if (answer .eqs. "") then answer = "1"
$ if (zk_t_logged_in)
$ then
$   if (answer .eqs. "1") then goto play
$   if (answer .eqs. "2") then goto maintain
$ else
$   if (answer .eqs. "1") then goto sign_in
$   if (answer .eqs. "2") then goto register
$ endif
$ if (answer .eqs. "3") then goto bail_out
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
$ answer = f$edit(answer, "TRIM,COLLAPSE")
$ if (answer .eqs. "") then goto ask_email
$ if (f$extract(0,1,answer) .eqs. "?") then goto help_email
$ zk_t_user = answer
$ domain = f$element(1,"@",zk_t_user)
$ if (domain .eqs. "") then goto help_email_valid
$ if (domain .eqs. "@") then goto help_email_valid
$ define/user sys$error nla0:
$ define/user sys$output nla0:
$ ucx show mx_record 'domain'
$ if (.not. $status) then goto help_email_valid
$ goto ask_firstname
$
$help_firstname:
$ say ""
$ say "  Please enter your first name, for personalization.  Under no"
$ say "  circumstances will it be provided to any third-party."
$ say ""
$ask_firstname:
$ ask "First name: " answer
$ answer = f$edit(answer,"TRIM,COMPRESS")
$ if (answer .eqs. "") then goto ask_firstname
$ if (answer .eqs. "?") then goto help_firstname
$ zk_t_first = answer
$ goto ask_lastname
$
$help_lastname:
$ say ""
$ say "  Please enter your last name, for personalization.  Under no"
$ say "  circumstances will it be provided to any third-party."
$ say ""
$ask_lastname:
$ ask "Last name: " answer
$ answer = f$edit(answer,"TRIM,COMPRESS")
$ if (answer .eqs. "") then goto ask_lastname
$ if (answer .eqs. "?") then goto help_lastname
$ zk_t_last = answer
$ goto ask_password
$
$help_password:
$ say ""
$ say "  It is necessary to specify a password to protect your account."
$help_password_valid:
$ say ""
$ say "  To ensure password safety it is recommended that you use as many"
$ say "  different characters as possible.  Also steer clear of dictionary"
$ say "  words, and dictionary words followed by a number."
$ say ""
$ say "  Your password will NEVER be given out.  It is only stored in"
$ say "  encrypted form.  The only restriction placed on passwords is"
$ say "  that they are 8 characters or longer."
$ say ""
$ask_password:
$ set terminal/noecho
$ ask "Password: " answer
$ say ""
$ set terminal/echo
$ answer = f$edit(answer,"TRIM")
$ if (answer .eqs. "") then goto ask_password
$ if (answer .eqs. "?") then goto help_password
$ if (f$length(answer) .lt. 8) then goto help_password_valid
$ password = answer
$
$ set terminal/noecho
$ ask "Confirm password: " answer
$ say ""
$ set terminal/echo
$ answer = f$edit(answer,"TRIM")
$ if (answer .eqs. password) then goto complete_register
$ err E MISMATCH "passwords do not match"
$ goto ask_password
$
$complete_register:
$ getmd5 'password'
$ key = f$fao("!#AS",zk_s_user,zk_t_user)
$ close/nolog uaf
$ open/read/write/share=write/error=err_uafopen uaf 'zk_t_default']ZKUAF.DAT
$ read/index=0/key="''key'"/match=eq -
      /end_of_file=register_rnf/error=register_rnf uaf record
$ goto err_exists
$register_rnf:
$ if ($status .ne. RMS$_RNF) then goto err_uafdread
$ getuid
$ zk_t_uid  = uid_uid
$ zk_t_hash = md5_md5
$ zk_n_cdt  = f$cvtime(,"COMPARISON")
$ zk_n_rdt  = f$cvtime(,"COMPARISON")
$ zk_i_lgic = 1
$ record = f$fao("!#AS!AS!AS!AS!AS!#UL!#AS!#AS!AS",-
		 zk_s_user,zk_t_user,zk_t_uid,zk_t_hash,zk_n_cdt,-
		 zk_n_rdt,zk_s_lgic,zk_i_lgic,zk_s_first,zk_t_first,-
		 zk_s_last,zk_t_last,zk_t_spare)
$ write/symbol/error=err_uafwrite uaf record
$ close/nolog uaf
$ create/directory 'zk_t_default'.USERS.'zk_t_uid']
$ ! register with mailing list
$ zk_t_logged_in = "Y"
$ say ""
$ err S CREATED "you have successfully created your account"
$ say ""
$ ask " Please press RETURN to continue" answer
$ goto start
$
$maintain:
$ say ""
$ say "  It is not possible to maintain your account at this time..."
$ say ""
$ goto start
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
$ answer = f$edit(answer, "TRIM,COLLAPSE")
$ if (answer .eqs. "") then goto ask_username
$ username = answer
$
$ set terminal/noecho
$ ask "Password: " answer
$ set terminal/echo
$ password = f$edit(answer,"TRIM")
$
$ key = f$fao("!#AS",zk_s_user,username)
$ open/read/write/share=write/error=err_uafopen uaf 'zk_t_default']ZKUAF.DAT
$ read/index=0/key="''key'"/match=eq -
      /end_of_file=err_authfail/error=err_authfail uaf record
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
$ zk_t_logged_in = "Y"
$ err S LOGIN "you successfully logged in"
$ goto start
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
$ message = "-" + f$message($status) - "%"
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
$ !-==========================================================================
