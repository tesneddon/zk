[inherit('lib$:typedef',
	 'lib$:rtldef',
	 'lib$:dscdef',
	 'ifc$library:ifc$rtl_def',
	 'lib$:zk$def')]
module zk$lex;

const	number_keywords = 272;

type	$bit7 = [byte] packed record
			bit0, bit1, bit2, bit3,
			bit4, bit5, bit6, bit7 : boolean;
		end;

	$keyword_rec = record
			string : varying[14] of char;
			token : $symbol_token;
			end;

	$keyword_table = array[1..number_keywords] of $keyword_rec;

var	current_symbol : $symbol_desc;
	current_line : varying[132] of char;
	line_pointer : integer;

	keyword_table : $keyword_table :=
	      ( ('ALL', all_keyword),
		('AND', and_keyword),
		('ARM', arm_keyword),
		('ASCII', ascii_keyword),
		('ASK', tell_keyword),
		('AT', at_keyword),
		('ATTACK', kill_keyword),
		('BACK', back_keyword),
		('BADGE', badge_keyword),
		('BAG', sack_keyword),
		('BALL', ball_keyword),
		('BANK', bank_keyword),
		('BARS', bars_keyword),
		('BILLS', bills_keyword),
		('BINDERS', doc_keyword),
		('BLACK', black_keyword),
		('BLANK', blank_keyword),
		('BLOOD', blood_keyword),
		('BLUE', blue_keyword),
		('BOARD', board_keyword),
		('BOOT', boot_keyword),
		('BREAK', kill_keyword),
		('BRIEF', brief_keyword),
		('BROKEN', broken_keyword),
		('BUILDING', building_keyword),
		('BULLETIN', bulletin_keyword),
		('BURLAP', burlap_keyword),
		('BUTTON', button_keyword),
		('CABINET', cabinet_keyword),
		('CAFETERIA', cafeteria_keyword),
		('CAN', can_keyword),
		('CANS', can_keyword),
		('CARD', card_keyword),
		('CASH', bills_keyword),
		('CDD', cdd_keyword),
		('CLIMB', stand_keyword),
		('CLOSE', close_keyword),
		('COINS', coins_keyword),
		('COKE', coke_keyword),
(**)		('COMPASS', compass_keyword),
(**)		('COMPUTER', computer_keyword),
		('CONSOLE', console_keyword),
(**)		('CONTENTS', contents_keyword),
(**)		('CONTROL', control_keyword),
		('CRETIN', self_keyword),
		('CRYSTAL', crystal_keyword),
		('D', down_keyword),
		('DARK', dark_keyword),
		('DATATRIEVE', dtr_keyword),
		('DEBRIS', debris_keyword),
		('DESIGN', pattern_keyword),
		('DESK', desk_keyword),
		('DESTROY', kill_keyword),
		('DEVELOPER', developer_keyword),
		('DEVO', developer_keyword),
		('DIETARY', diet_keyword),
		('DISCARDED', discarded_keyword),
		('DISK', disk_keyword),
		('DISMOUNT', take_keyword),
		('DOC', doc_keyword),
		('DOCUMENTATION', doc_keyword),
		('DOOR', door_keyword),
		('DOWN', down_keyword),
		('DRINK', drink_keyword),
		('DRIVE', drive_keyword),
		('DROP', drop_keyword),
		('DTR', dtr_keyword),
		('E', east_keyword),
		('EAST', east_keyword),
		('EDS', edswbl_keyword),
		('EDSWBL', edswbl_keyword),
		('ELEVATOR', elevator_keyword),
		('ELF', elvish_keyword),
		('ELVISH', elvish_keyword),
		('EMPTY', empty_keyword),
		('ENQUIRER', enquirer_keyword),
		('ENTER', enter_keyword),
		('EXA', examine_keyword),
		('EXAMINE', examine_keyword),
		('EXIT', exit_keyword),
		('FIELD', field_keyword),
		('FIND', locate_keyword),
		('FIX', heal_keyword),
		('FLUORESCENT', fluorescent_keyword),
		('FOLLOW', follow_keyword),
		('FONDLE', rub_keyword),
		('FROM', from_keyword),
		('GARBAGE', debris_keyword),
		('GET', get_keyword),
		('GIVE', give_keyword),
		('GLASS', glass_keyword),
		('GO', go_keyword),
		('GRAB', take_keyword),
		('GREETINGS', hello_keyword),
		('GUARD', guard_keyword),
		('HACKER', developer_keyword),
		('HEAL', heal_keyword),
		('HELICOPTER', helicopter_keyword),
		('HELLO', hello_keyword),
		('I', inventory_keyword),
		('IN', in_keyword),
		('INCANT', say_keyword),
		('INFORMATION', information_keyword),
		('INSIDE', in_keyword),
		('INSTALL', install_keyword),
		('INTO', in_keyword),
		('INVENTORY', inventory_keyword),
		('IS', is_keyword),
		('JOURNAL', journal_keyword),
		('JUMP', jump_keyword),
		('JUNK', debris_keyword),
		('KEY', keys_keyword),
		('KEYPAD', keypad_keyword),
		('KEYS', keys_keyword),
		('KILL', kill_keyword),
		('KIT', tape_keyword),
		('L', look_keyword),
		('LAMP', lamp_keyword),
		('LANTERN', lamp_keyword),
		('LEAVE', exit_keyword),
		('LIGHTS', light_keyword),
		('LIQUID', liquid_keyword),
		('LISTINGS', listings_keyword),
		('LOAD', put_keyword),
		('LOCATE', locate_keyword),
		('LOCK', lock_keyword),
		('LOOK', look_keyword),
		('MACHINE', machine_keyword),
		('MAGAZINE', magazine_keyword),
		('MAGIC', magic_keyword),
		('MAHOGANY', mahogany_keyword),
		('MAIL', mail_keyword),
		('MANAGER', manager_keyword),
		('MANUALS', manuals_keyword),
		('MARKER', marker_keyword),
		('ME', self_keyword),
		('MEDIA', media_keyword),
		('MENU', menu_keyword),
		('MESSAGE', message_keyword),
		('MIRROR', mirror_keyword),
		('MONEY', money_keyword),
		('MOUNT', put_keyword),
		('MOVE', move_keyword),
		('MUNG', kill_keyword),
		('N', north_keyword),
		('NE', north_east_keyword),
		('NEEDLE', needle_keyword),
		('NEON', neon_keyword),
		('NEWSPAPER', newspaper_keyword),
		('NORTH', north_keyword),
		('NOTES', notes_keyword),
		('NURSE', nurse_keyword),
		('NW', north_west_keyword),
		('OFF', off_keyword),
		('OFFICER', officer_keyword),
		('OLD', old_keyword),
		('ON', on_keyword),
		('OPEN', open_keyword),
		('ORANGE', orange_keyword),
		('OUT', out_keyword),
		('PACK', pack_keyword),
		('PANEL', panel_keyword),
		('PATTERN', pattern_keyword),
		('PEOPLE', people_keyword),
		('PERSONNEL', personnel_keyword),
		('PICK', pick_keyword),
		('PLANT', plant_keyword),
		('PLAY', play_keyword),
		('PLEASE', please_keyword),
		('PLUGH', plugh_keyword),
		('POSSESSIONS', possessions_keyword),
		('PRAY', pray_keyword),
		('PRESSURE', pressure_keyword),
		('PRINTER', console_keyword),
		('PRODUCT', product_keyword),
		('PROGRAMMER', developer_keyword),
		('PROTOTYPE', prototype_keyword),
		('PULL', move_keyword),
		('PUSH', move_keyword),
		('PUT', put_keyword),
		('QUIET', brief_keyword),
		('QUIT', quit_keyword),
		('QUIZ', quiz_keyword),
		('RACKS', racks_keyword),
		('READ', read_keyword),
		('RECEPTION', reception_keyword),
		('RED', red_keyword),
		('REMOVE', take_keyword),
		('REP', rep_keyword),
		('REPAIR', heal_keyword),
		('REPRESENTATIVE', rep_keyword),
(**)		('RESTART', restart_keyword),
(**)		('RESTORE', restore_keyword),
		('RODS', bars_keyword),
		('ROOM', room_keyword),
		('ROSE', rose_keyword),
		('ROUTE3', route3_keyword),
		('RTL', rtl_keyword),
		('RUB', rub_keyword),
		('RUG', rug_keyword),
		('RUN', go_keyword),
		('S', south_keyword),
		('SACK', sack_keyword),
		('SAFE', safe_keyword),
		('SAILOR', sailor_keyword),
		('SAVE', save_keyword),
		('SAY', say_keyword),
		('SCALE', scale_keyword),
		('SCORE', score_keyword),
		('SCRATCH', scratch_keyword),
		('SCREAM', scream_keyword),
		('SCREEN', terminal_keyword),
		('SDC', sdc_keyword),
		('SE', south_east_keyword),
		('SECURITY', security_keyword),
		('SELF', self_keyword),
		('SERVICE', service_keyword),
		('SHAKE', shake_keyword),
		('SHUT', shut_keyword),
		('SIGN', sign_keyword),
		('SMASH', kill_keyword),
		('SODA', coke_keyword),
		('SOFTWARE', software_keyword),
		('SOUTH', south_keyword),
		('SPHERE', ball_keyword),
		('STAIRS', stairwell_keyword),
		('STAIRWELL', stairwell_keyword),
		('STAND', stand_keyword),
		('START', start_keyword),
		('STEP', stand_keyword),
		('STOP', stop_keyword),
		('STRANGE', strange_keyword),
		('SW', south_west_keyword),
		('SWORD', sword_keyword),
		('SYSTEM', system_keyword),
		('TABLE', table_keyword),
		('TAKE', take_keyword),
		('TAPE', tape_keyword),
		('TELL', tell_keyword),
		('TEMPORARY', temporary_keyword),
		('TERMINAL', terminal_keyword),
		('THE', the_keyword),
		('THEN', then_keyword),
		('TIDBITS', information_keyword),
		('TO', to_keyword),
		('TODAY', today_keyword),
		('TURN', turn_keyword),
		('TYPE', type_keyword),
		('U', up_keyword),
		('UNLOCK', unlock_keyword),
		('UP', up_keyword),
		('USING', with_keyword),
		('VAX', vax_keyword),
		('VERBOSE', verbose_keyword),
		('VERSION', version_keyword),
		('VIDEO', video_keyword),
		('VMS', vms_keyword),
		('VT100', video_keyword),
		('W', west_keyword),
		('WAIT', wait_keyword),
		('WALK', go_keyword),
		('WALL', wall_keyword),
		('WAVE', shake_keyword),
		('WBL', edswbl_keyword),
		('WEAR', wear_keyword),
		('WEST', west_keyword),
		('WHERE', where_keyword),
		('WITH', with_keyword),
		('WORKING', working_keyword),
		('XYZZY', xyzzy_keyword),
		('YELLOW', yellow_keyword),
		('ZK', zk_keyword) );

procedure get_char(var c, n : char);
begin
	if (current_line.length<>0) then
	  begin
		line_pointer:=line_pointer+1;
		c:=current_line[line_pointer];
		if (c<=' ') then c:=' ';
		if (line_pointer<current_line.length) then
			n:=current_line[line_pointer+1]
		else
		  begin
			n:=chr(13); current_line.length:=0;
		  end;
	  end
	else	c:=chr(13);
end;

procedure get_token(var symbol : $symbol_desc);
var	c, n, d : char;
begin
	get_char(c, n);
	while (c=' ') do get_char(c, n);

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
			get_char(c,n);
			symbol.string:=symbol.string+c;
		  end;
	  end
	else
	  begin
		case (c) of
		',':	symbol.token:=comma_symbol;
		'.':	symbol.token:=period_symbol;
		'"':	begin
				symbol.token:=text_string;
				symbol.string.length:=0;
				while ((n<>'"') and (n<>chr(13))) do
				  begin
					get_char(c,n);
					symbol.string:=symbol.string+c;
				  end;
				if (n<>chr(13)) then get_char(c,n)
			end;
		chr(13):  begin
				symbol.token:=end_of_line;
				symbol.string:='END_OF_LINE';
			  end;
		otherwise
			symbol.token:=invalid;
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

procedure lookup_keyword(var symbol : $symbol_desc);

var	found : boolean;
	t, m, b, state : integer;
	nl, kl : $uword;
	keyword_desc : [static] $descriptor :=
		(0, dsc$k_dtype_t, dsc$k_class_s, 0);
begin
	nl:=symbol.string.length;
	t:=1; b:=number_keywords; found:=false;
	while ( (b>=t) and (not found) ) do
	  begin
		m:=t + (b - t) div 2;

		kl:=keyword_table[m].string.length;
		if ( (nl < kl) and (nl>=4) ) then
			keyword_desc.dsc$w_length:=nl
		else	keyword_desc.dsc$w_length:=kl;
		keyword_desc.dsc$a_pointer:=
			iaddress(keyword_table[m].string.body);

		state:=$compare_vs_dx(symbol.string, keyword_desc);
		if (state=0) then found:=true
		else
			if (state=-1) then b:=m-1 else t:=m+1;
	  end;

	if (found) then symbol.token:=keyword_table[m].token
	else
		symbol.token:=unknown;
end;

procedure case_string(
	var string : varying[$u1] of char;
	lower : boolean);

var	i : integer;
begin
	for i:=1 to string.length do
		if (string[i]::$bit7.bit6) then
				string[i]::$bit7.bit5:=lower;
end;

procedure recognize_token(var symbol : $symbol_desc);
begin
	if (symbol.token=unknown) then
	  begin
		if ( (symbol.string[1]>='0') and (symbol.string[1]<='9') ) then
			convert_integer(symbol)
		else
		  begin
			case_string(symbol.string, lower:=false);
			lookup_keyword(symbol);
			case_string(symbol.string, lower:=true);
		  end;
	  end;
end;

[global] function zk$init_lex : unsigned;
begin
	line_pointer:=0;
	$message(0);
	zk$init_lex:=$get_composed_line(current_line, '>');
end;

[global] procedure zk$advance_symbol;
begin
	get_token(current_symbol);
	recognize_token(current_symbol);
end;

[global] procedure zk$get_symbol(var symbol : $symbol_desc);
begin
	symbol:=current_symbol;
end;

end.
