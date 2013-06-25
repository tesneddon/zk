$!
$!  KITINSTAL procedure for ZK
$!
$ on control_y then vmi$callback control_y
$ on warning then exit $status
$
$! Determine architecture...
$!
$ version = f$integer(f$extract(1,1,f$getsyi("VERSION")))
$ if (version .ge. 6)
$ then
$    _arch_type = f$getsyi("ARCH_TYPE")
$    _arch_name = f$element(_arch_type,",","OTHER,VAX,ALPHA,I64") - ","
$    _vax = (_arch_type .eq. 1)
$    _axp = (_arch_type .eq. 2)
$    _i64 = (_arch_type .eq. 3)
$    _other = (.not. (_vax .or. _axp .or. _i64))
$ else
$    _vax = (f$search("SYS$SYSTEM:VMB.EXE") .nes. "")
$    if (_vax)
$    then
$	_arch_type = 1
$	_arch_name = "VAX"
$    else
$	_arch_type = 2
$	_arch_name = "ALPHA"
$	_axp = 1
$    endif
$ endif
$
$! Determine course of action...
$!
$ if (p1 .eqs. "VMI$_INSTALL")	   then goto zk_install
$ exit VMI$_UNSUPPORTED
$
$! Install the product
$!
$zk_install:
$ type sys$input:

                            The Halls Of ZK

        This procedure install the sophisticated, interactive fiction
  adventure game, The Halls Of ZK.  Discover incredible treasures,
  famous personalities and mind-boggling encounters as you walk the
  halls of Digital's Spitbrook software engineering facility.

        Installation of this product is supported on OpenVMS VAX,
  Alpha and I64.  If you have an unsupported architecture, consider
  downloading the source kit and have a shot at building it.

        For support, downloads and other things related to ZK, visit
  the ZK webpage, here:

        http://hallsofzk.org

$
$ save_set = f$element(_arch_type,",",",B,C,D") - ","
$
$ if (save_set .eqs. "")
$ then
$    vmi$callback message E BADARCH "architecture not supported" -
		"binary installation is impossible"
$    exitt 1
$ endif
$
$ vmi$callback restore_saveset 'save_set'
$
$ vmi$callback provide_image zk$main zk$main.exe vmi$root:[sysexe]
$ vmi$callback provide_dcl_command zk$cld.cld
$ vmi$callback provide_dcl_help zk$dcl_help.hlp
$
$ exit $status
