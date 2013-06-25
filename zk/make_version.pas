program make_version(input, output);

type	$string_long = [long, unsafe] record
				case integer of
				1: (string : packed array[1..4] of char);
				2: (long : unsigned);
				end;

var	filename : varying[40] of char;
	version : $string_long;
	options_file : text;
begin
	write('Filename? '); readln(filename);
	write('Version? '); readln(version.string);
	open(options_file, filename, history:=new);
	rewrite(options_file);
	writeln(options_file, 'SYMBOL=ZK$T_VERSION, ',version.long:0);
	close(options_file);
end.
