program zk$map
    option type = explicit,						  &
	   constant type = integer,					  &
	   size = (integer long, real double)

%include "LIB$ROUTINES"		%from %library "SYS$LIBRARY:BASIC$STARLET.TLB"
%include "STARLET"		%from %library "SYS$LIBRARY:BASIC$STARLET.TLB"
%include "STR$ROUTINES"		%from %library "SYS$LIBRARY:BASIC$STARLET.TLB"

    external long function ifc$draw_map
    external long constant zk$room_max
    external long zk$room_table

    declare string command
    declare string map_name, map_filename
    declare long sstatus

    sstatus = lib$get_foreign(command)
    if ((sstatus and 1) <> 0) then
	command = edit$(command, 16 + 8 + 4)
	sstatus = str$element(map_name, 0, " ", command)
	if ((sstatus and 1) <> 0) then
	    sstatus = str$element(map_filename, 1, " ", command)
	end if
    end if

    if ((sstatus and 1) = 0) then
	print "%ZKMAP-F-INSFARG, insufficient arguments'"
	print ""
	print "  ZKMAP - Generate a Graphviz map of ZK"
	print ""
	print "   $ zkmap map-name output-filename"
	print ""
    else
	print "%ZKMAP-I-NAME, graph will be named "; map_name
	print "%ZKMAP-I-OUTPUT, writing graph to "; map_filename

	sstatus = ifc$draw_map(zk$room_table by ref,			  &
			       zk$room_max by ref, map_name by desc,	  &
			       map_filename by desc)
    end if
end program
