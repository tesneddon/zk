[inherit('lib$:typedef',
	 'sys$library:starlet')]
program zk$link_time;

type	fab$type_ptr = ^fab$type;
	nam$type_ptr = [unsafe]^nam$type;

	$pointer = record
			case integer of
			1: (address : unsigned);
			2: (char_ptr : ^char);
		   end;

var	now : $uquad;
	version, i : integer;
	p : $pointer;
	options_file : text;
	fab : fab$type_ptr;
	nam : nam$type_ptr;

function pas$fab(var file_variable : text) : fab$type_ptr;
	extern;

begin
	open(options_file, 'ZKLINK_TIME.OPT', history:=new);
	rewrite(options_file);

	$gettim(now);

	writeln(options_file, 'SYMBOL=ZK$K_LINK_TIME_L0, ', now.l0:0);
	writeln(options_file, 'SYMBOL=ZK$K_LINK_TIME_L1, ', now.l1:0);

	fab:=pas$fab(options_file); nam:=fab^.fab$l_nam;
	p.address:=nam^.nam$l_ver;
	version:=0;
	for i:=2 to nam^.nam$b_ver do
	  begin
		p.address:=p.address+1;
		version:=version*10+ord(p.char_ptr^)-48;
	  end;

	writeln(options_file, 'SYMBOL=ZK$K_BASELEVEL, ', version:0);

	close(options_file);
end.
