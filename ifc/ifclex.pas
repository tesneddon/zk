[inherit('lib$:rtldef',
	 'lib$:ifc$def')]
module ifc$lex(output);

const	number_keywords = 46;

type	$error_ptr = ^$error_node;
	$error_node = record
			position : integer;
			number : integer;
			code : $error_code;
			string : $symbol_string;
			members : $symbol_set;
			value : $symbol_value;
			next : $error_ptr;
			end;

	$keyword_table_rec = record
				name : $symbol_string;
				value : $symbol_token;
				end;

	$keyword_table = array[1..number_keywords] of $keyword_table_rec;

var	current_symbol : $symbol_desc;
	current_line : $symbol_string;
	current_position : integer;
	first_error, last_error : $error_ptr := nil;
	source_file : text;
	errors_enabled : boolean;

	keyword_table : $keyword_table :=
		( ('AREA', area_keyword),
		  ('BLINK', blink_keyword),
		  ('BOLD', bold_keyword),
		  ('CAPACITY', capacity_keyword),
		  ('CLASS', class_keyword),
		  ('COGNIZANT', cognizant_keyword),
		  ('DESCRIPTION', description_keyword),
		  ('DETAIL', detail_keyword),
		  ('DOOR', door_keyword),
		  ('DOWN', down_keyword),
		  ('EAST', east_keyword),
		  ('END', end_keyword),
		  ('FAO', fao_keyword),
		  ('FLEXIBLE', flexible_keyword),
		  ('GENERIC', generic_keyword),
		  ('IDENT', ident_keyword),
		  ('IN', in_keyword),
		  ('INFINITE', infinite_keyword),
		  ('INITIAL', initial_keyword),
		  ('LOCKABLE', lockable_keyword),
		  ('MACHINE', machine_keyword),
		  ('MASS', mass_keyword),
		  ('MESSAGE', message_keyword),
		  ('NAME', name_keyword),
		  ('NORTH', north_keyword),
		  ('NORTH_EAST', north_east_keyword),
		  ('NORTH_WEST', north_west_keyword),
		  ('OBJECT', object_keyword),
		  ('OPENABLE', openable_keyword),
		  ('OUT', out_keyword),
		  ('PREFIX', prefix_keyword),
		  ('READABLE', readable_keyword),
		  ('REVERSE', reverse_keyword),
		  ('ROOM', room_keyword),
		  ('SIZE', size_keyword),
		  ('SOUTH', south_keyword),
		  ('SOUTH_EAST', south_east_keyword),
		  ('SOUTH_WEST', south_west_keyword),
		  ('SPECIFIC', specific_keyword),
		  ('STARTABLE', startable_keyword),
		  ('STATIC', static_keyword),
		  ('STRENGTH', strength_keyword),
		  ('UNDERLINE', underline_keyword),
		  ('UP', up_keyword),
		  ('VOLUME', volume_keyword),
		  ('WEST', west_keyword) );

procedure lookup_keyword(var symbol : $symbol_desc);
var	found : boolean;
	t, b, m, state : integer;
begin
	t:=1; b:=number_keywords; found:=false;
	while ((b>=t) and (not found)) do
	  begin
		m:=t + (b-t) div 2;
		state:=$compare(symbol.string, keyword_table[m].name);
		if (state=0) then found:=true
		else
		  begin
			if (state=-1) then b:=m-1 else t:=m+1;
		  end;
	  end;

	if (found) then symbol.token:=keyword_table[m].value;
end;

procedure enumerate_members(symbol_set : $symbol_set);
var	index : $symbol_token;
begin
	index:=identifier;
	repeat
	  begin
		if (index in symbol_set) then writeln(index);
		index:=succ(index);
	  end
	until (index=identifier);
end;

[global] procedure ifc$defer_error_message(
	code : $error_code;
	string : $symbol_string;
	members : $symbol_set;
	value : $symbol_value);

var	p : $error_ptr;
begin
	if (errors_enabled) then
	  begin
		new(p);
		p^.position:=current_position;
		p^.number:=0;
		p^.code:=code;
		p^.string:=string;
		p^.members:=members;
		p^.value:=value;
		p^.next:=nil;

		if (last_error=nil) then
		  begin
			first_error:=p; last_error:=p;
		  end
		else
		  begin
			last_error^.next:=p; last_error:=p;
		  end;
	  end;
end;

procedure write_error_message(p : $error_ptr);
begin
	case (p^.code) of
	error_muldef:
		writeln('%IFC-W-MULDEF, (',p^.number:0,') Room ',
			p^.string,' is multiply defined');
	error_strtrm:
		writeln('%IFC-W-STRTRM, (',p^.number:0,') String ',
			'terminated at end of line');
	error_invchr:
		writeln('%IFC-W-INVCHR, (',p^.number:0,') Character "',
			p^.string,'" is invalid');
	error_syntax:
		writeln('%IFC-W-SYNTAX, (',p^.number:0,') Found ',
			'unexpected syntax "',p^.string,'"');
	error_expect:
	  begin
		writeln('-IFC-W-EXPECT, Expecting one of the following:');
		enumerate_members(p^.members);
	  end;
	error_sync:
	  begin
		writeln('-IFC-W-SYNC, Synchronizing with one ',
			'of the following:');
		enumerate_members(p^.members);	
	  end;
	error_skip:
		writeln('-IFC-W-SKIP, Some text may be skipped');
	end;
end;

procedure emit_error_messages;
var	o, p : $error_ptr;
	bp, n, i : integer;
	buf : $symbol_string;
begin
	p:=first_error;
	if (p<>nil) then
	  begin
		writeln; writeln(current_line);
	  end;

	buf:=''; bp:=0; n:=0;
	while (p<>nil) do
	  begin
		if (p^.position>bp) then
		  begin
			n:=n+1;
			for i:=(bp+1) to (p^.position-1) do buf:=buf+'.';
			bp:=p^.position;
			buf:=buf+chr(n+48);
		  end;
		p^.number:=n;
		p:=p^.next;
	  end;

	p:=first_error;
	if (p<>nil) then writeln(buf);

	while (p<>nil) do
	  begin
		write_error_message(p);
		o:=p; p:=p^.next; dispose(o);
	  end;
	first_error:=nil; last_error:=nil;
end;

procedure expand_tabs(
	source : varying[$u1] of char;
	var dest : varying[$u2] of char);

var	i, j : integer;
	c : char;
begin
	dest:='';
	for i:=1 to (source.length) do
	  begin
		c:=source[i];
		if (c<>chr(9)) then dest:=dest + c
		else
			for j:=1 to (8-(dest.length mod 8)) do
				dest:=dest + ' ';
	  end;
end;

procedure get_char(var c, n : char; var lp : integer);

var	line : [static] $symbol_string := '';
	p : integer;
begin
	while ((not eof(source_file)) and (line.length=0)) do
	  begin
		readln(source_file, line);
		p:=index(line,'--');
		if (p<>0) then line.length:=p-1;
		if (line.length<>0) then
		  begin
			emit_error_messages;
			expand_tabs(line, line); current_line:=line;
			lp:=0;
		  end;
	  end;

	if (line.length<>0) then
	  begin
		lp:=lp+1; c:=line[lp];
		if (c<=' ') then c:=' ';
		if (lp<line.length) then n:=line[lp+1]
		else
		  begin
			n:=chr(13); line.length:=0;
		  end;
	  end
	else	c:=chr(26);
end;

procedure get_token(var symbol : $symbol_desc);

var	c, n, d : char;
	lp : [static] integer := 0;
begin
	get_char(c, n, lp);
	while (c=' ') do get_char(c, n, lp);

	current_position:=lp;
	symbol.error:=false;
	symbol.value:=0;
	symbol.string:=c;
	if ( ((c>='A') and (c<='Z')) or
	     ((c>='a') and (c<='z')) or
	     ((c>='0') and (c<='9')) or
	     (c='_') or (c='$') ) then
	  begin
		symbol.token:=unknown;
		while ( ((n>='A') and (n<='Z')) or
			((n>='a') and (n<='z')) or
			((n>='0') and (n<='9')) or
			(n='_') or (n='$') ) do
		  begin
			get_char(c,n,lp);
			symbol.string:=symbol.string+c;
		  end;
	  end
	else
	  begin
		case (c) of
		'+':	symbol.token:=plus_symbol;
		'-':	symbol.token:=minus_symbol;
		'*':	symbol.token:=star_symbol;
		'(':	symbol.token:=left_paren_symbol;
		')':	symbol.token:=right_paren_symbol;
		';':	symbol.token:=semicolon_symbol;
		',':	symbol.token:=comma_symbol;
		'.':	symbol.token:=dot_symbol;
		'=':	symbol.token:=equal_symbol;
		'/':	symbol.token:=fslash_symbol;
		':':	symbol.token:=colon_symbol;
		'<':	begin
				symbol.token:=text_string;
				symbol.string.length:=0;
				while ((n<>'>') and (n<>chr(13))) do
				  begin
					get_char(c,n,lp);
					symbol.string:=symbol.string+c;
				  end;
				if (n<>chr(13)) then get_char(c,n,lp)
				else
					ifc$defer_error_message(error_strtrm,
						'', [], 0);
			end;
		chr(26):  begin
				symbol.token:=end_of_file;
				symbol.string:='END_OF_FILE';
			  end;
		otherwise
		  begin
			symbol.token:=invalid;
			ifc$defer_error_message(error_invchr, c, [], 0);
		  end;
		end;
	  end;
end;

procedure convert_integer(var symbol : $symbol_desc);
var	d : integer;
begin
	symbol.token:=integer_constant;
	symbol.value:=0; d:=0;
	while ( (d<symbol.string.length) and
		(symbol.token=integer_constant)) do
	  begin
		d:=d+1;
		if ( (symbol.string[d]>='0') and
		     (symbol.string[d]<='9') ) then
			symbol.value := symbol.value*10 +
					ord(symbol.string[d])-48
		else	symbol.token:=invalid;
	  end;
end;

procedure recognize_token(var symbol : $symbol_desc);
begin
	if (symbol.token=unknown) then
	  begin
		if ( (symbol.string[1]>='0') and (symbol.string[1]<='9') ) then
			convert_integer(symbol)
		else
		  begin
			$upcase(symbol.string, symbol.string);
			lookup_keyword(symbol);
			if (symbol.token=unknown) then
				symbol.token:=identifier;
		  end;
	  end;
end;

[global] procedure ifc$advance_symbol;
begin
	get_token(current_symbol);
	recognize_token(current_symbol);
end;

[global] procedure ifc$get_symbol(var symbol : $symbol_desc);
begin
	symbol:=current_symbol;
end;

procedure skip_symbol(followers : $symbol_set);
begin
	ifc$defer_error_message(error_sync, '', followers, 0);
	while not (current_symbol.token in followers) do
		ifc$advance_symbol;
end;

[global] procedure ifc$sync_symbol(followers : $symbol_set);
begin
	if not (current_symbol.token in followers) then
	  begin
		if (not current_symbol.error) then
		  begin
			current_symbol.error:=true;
			ifc$defer_error_message(error_syntax,
				current_symbol.string, [], 0);
		  end;
		skip_symbol(followers);
	  end;
end;

[global] procedure ifc$test_symbol(expected, followers : $symbol_set);
begin
	if not (current_symbol.token in expected) then
	  begin
		if (not current_symbol.error) then
		  begin
			current_symbol.error:=true;
			ifc$defer_error_message(error_syntax,
				current_symbol.string, [], 0);
			ifc$defer_error_message(error_expect, '',
				expected, 0);
		  end;
		skip_symbol(expected+followers);
	  end;
end;

[global] procedure ifc$open_lex(
	source_filename : varying[$u1] of char);
begin
	open(source_file, source_filename, history:=old);
end;

[global] procedure ifc$close_lex;
begin
	emit_error_messages;
	close(source_file);
end;

[global] procedure ifc$reset_lex(error : boolean);
begin
	emit_error_messages;
	reset(source_file);
	errors_enabled:=error;
end;

end.
