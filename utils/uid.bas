	program	uid

	option	type = explicit,					  &
		constant type = integer,				  &
		size = (integer long, real double)

%include "LIB$ROUTINES"		%from %library "SYS$LIBRARY:BASIC$STARLET.TLB"
%include "STARLET"		%from %library "SYS$LIBRARY:BASIC$STARLET.TLB"

	declare basic$octaword binuid
	declare string struid

	call sys$create_uid(binuid by ref)
	call lib$uid_to_ascii(binuid by ref, struid by desc)

	call lib$set_symbol("UID_UID" by desc, struid by desc)

  	end program
