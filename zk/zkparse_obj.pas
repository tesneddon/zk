[inherit('lib$:typedef',
	 'lib$:zk$def',
	 'lib$:zk$lex_def',
	 'lib$:zk$text',
	 'lib$:zk$obj',
	 'ifc$library:ifc$rtl_def')]
module zk$parse_object;

const	object_table_size = 176;
	keywords_per_object = 3;

type	$keyword_array = packed array[1..keywords_per_object] of $symbol_token;
	$object_record = packed record
				keyword : $keyword_array;
				object : [unsafe] $ubyte;
			 end;
	$object_table = packed array[1..object_table_size] of $object_record;

var	object_table : $object_table :=
      ( ( (all_keyword, nil_keyword, nil_keyword), zk$obj_all),
	( (arm_keyword, nil_keyword, nil_keyword), zk$obj_arm),
	( (ascii_keyword, table_keyword, nil_keyword), zk$obj_ascii_table),
	( (badge_keyword, nil_keyword, nil_keyword), zk$obj_badge),
	( (ball_keyword, nil_keyword, nil_keyword), zk$obj_any_ball),
	( (bars_keyword, nil_keyword, nil_keyword), zk$obj_bars),
	( (bills_keyword, nil_keyword, nil_keyword), zk$obj_bills),
	( (black_keyword, board_keyword, nil_keyword), zk$obj_black_board),
	( (blank_keyword, card_keyword, nil_keyword), zk$obj_sdc_card_blank),
	( (blood_keyword, pressure_keyword, machine_keyword),zk$obj_bp_machine),
	( (blue_keyword, button_keyword, nil_keyword), zk$obj_blue_button),
	( (board_keyword, nil_keyword, nil_keyword), zk$obj_any_board),
	( (broken_keyword, coins_keyword, machine_keyword),
						zk$obj_broken_coin_machine),
	( (building_keyword,light_keyword,nil_keyword), zk$obj_building_lights),
	( (bulletin_keyword, board_keyword, nil_keyword),zk$obj_bulletin_board),
	( (burlap_keyword, sack_keyword, nil_keyword), zk$obj_sack),
	( (button_keyword, nil_keyword, nil_keyword), zk$obj_any_button),
	( (cabinet_keyword, nil_keyword, nil_keyword), zk$obj_cabinet),
	( (cafeteria_keyword, table_keyword, nil_keyword), zk$obj_cafe_table),
	( (can_keyword, nil_keyword, nil_keyword), zk$obj_any_coke),
	( (card_keyword, nil_keyword, nil_keyword), zk$obj_any_card),
	( (cdd_keyword, developer_keyword, nil_keyword), zk$obj_cdd_developer),
	( (cdd_keyword, tape_keyword, nil_keyword), zk$obj_cdd_tape),
	( (coins_keyword,machine_keyword, nil_keyword),zk$obj_any_coin_machine),
	( (coins_keyword, nil_keyword, nil_keyword), zk$obj_coins),
	( (coke_keyword, can_keyword, nil_keyword), zk$obj_any_coke),
	( (coke_keyword, machine_keyword, nil_keyword), zk$obj_coke_machine),
	( (coke_keyword, nil_keyword, nil_keyword), zk$obj_coke),
	( (compass_keyword, needle_keyword, nil_keyword), zk$obj_needle),
	( (compass_keyword, nil_keyword, nil_keyword), zk$obj_compass),
	( (compass_keyword, pattern_keyword, nil_keyword), zk$obj_compass),
	( (compass_keyword, rose_keyword, nil_keyword), zk$obj_compass),
	( (computer_keyword, nil_keyword, nil_keyword), zk$obj_computer),
	( (computer_keyword, prototype_keyword, nil_keyword), zk$obj_computer),
	( (computer_keyword, system_keyword, nil_keyword), zk$obj_computer),
	( (console_keyword, nil_keyword, nil_keyword), zk$obj_console),
	( (contents_keyword, nil_keyword, nil_keyword), zk$obj_contents),
	( (control_keyword, panel_keyword, nil_keyword), zk$obj_control_panel),
	( (crystal_keyword, ball_keyword, nil_keyword), zk$obj_any_ball),
	( (crystal_keyword, door_keyword, nil_keyword), zk$obj_crystal_door),
	( (dark_keyword, liquid_keyword, nil_keyword), zk$obj_liquid),
	( (debris_keyword, nil_keyword, nil_keyword), zk$obj_any_debris),
	( (desk_keyword, nil_keyword, nil_keyword), zk$obj_any_desk),
	( (developer_keyword, nil_keyword, nil_keyword), zk$obj_any_developer),
	( (diet_keyword, quiz_keyword, nil_keyword), zk$obj_diet_quiz),
	( (discarded_keyword,can_keyword, nil_keyword), zk$obj_discarded_cans),
	( (discarded_keyword,coke_keyword,can_keyword), zk$obj_discarded_cans),
	( (disk_keyword, drive_keyword, nil_keyword), zk$obj_disk_drive),
	( (disk_keyword, nil_keyword, nil_keyword), zk$obj_any_disk),
	( (disk_keyword, pack_keyword, nil_keyword), zk$obj_any_disk),
	( (doc_keyword, nil_keyword, nil_keyword), zk$obj_doc),
	( (door_keyword, nil_keyword, nil_keyword), zk$obj_any_door),
	( (drink_keyword, nil_keyword, nil_keyword), zk$obj_liquid),
	( (drive_keyword, nil_keyword, nil_keyword), zk$obj_any_drive),
	( (dtr_keyword, nil_keyword, nil_keyword), zk$obj_dtr_tape),
	( (dtr_keyword, tape_keyword, nil_keyword), zk$obj_dtr_tape),
	( (elevator_keyword, door_keyword, nil_keyword), zk$obj_elevator_door),
	( (elevator_keyword, lock_keyword, nil_keyword), zk$obj_elevator_lock),
	( (elvish_keyword, old_keyword, sword_keyword), zk$obj_sword),
	( (elvish_keyword, sword_keyword, nil_keyword), zk$obj_sword),
	( (empty_keyword, can_keyword, nil_keyword), zk$obj_empty_can),
	( (empty_keyword, coke_keyword, can_keyword), zk$obj_empty_can),
	( (enquirer_keyword, newspaper_keyword,nil_keyword),zk$obj_zk_enquirer),
	( (enquirer_keyword, nil_keyword, nil_keyword), zk$obj_zk_enquirer),
	( (field_keyword, rep_keyword, nil_keyword), zk$obj_field_service_rep),
	( (field_keyword,service_keyword,rep_keyword),zk$obj_field_service_rep),
	( (fluorescent_keyword, ball_keyword, nil_keyword),
						zk$obj_fluorescent_ball),
	( (fluorescent_keyword, crystal_keyword, ball_keyword),
						zk$obj_fluorescent_ball),
	( (glass_keyword, door_keyword, nil_keyword), zk$obj_glass_door),
	( (guard_keyword, nil_keyword, nil_keyword), zk$obj_guard),
	( (helicopter_keyword, nil_keyword, nil_keyword), zk$obj_helicopter),
	( (information_keyword, nil_keyword, nil_keyword), zk$obj_tidbit),
	( (journal_keyword, newspaper_keyword, nil_keyword), zk$obj_zk_journal),
	( (journal_keyword, nil_keyword, nil_keyword), zk$obj_zk_journal),
	( (keypad_keyword, nil_keyword, nil_keyword), zk$obj_keypad),
	( (keys_keyword, nil_keyword, nil_keyword), zk$obj_keys),
	( (lamp_keyword, nil_keyword, nil_keyword), zk$obj_lamp),
	( (light_keyword, nil_keyword, nil_keyword), zk$obj_any_light),
	( (liquid_keyword, nil_keyword, nil_keyword), zk$obj_liquid),
	( (listings_keyword, nil_keyword, nil_keyword), zk$obj_listings),
	( (lock_keyword, nil_keyword, nil_keyword), zk$obj_elevator_lock),
	( (machine_keyword, nil_keyword, nil_keyword), zk$obj_any_machine),
	( (magic_keyword, marker_keyword, board_keyword),
					zk$obj_any_marker_board),
	( (mahogany_keyword, desk_keyword, nil_keyword), zk$obj_desk),
	( (mail_keyword, message_keyword, nil_keyword), zk$obj_mail_message),
	( (mail_keyword, nil_keyword, nil_keyword), zk$obj_mail_message),
	( (manager_keyword, nil_keyword, nil_keyword), zk$obj_manager),
	( (manuals_keyword, nil_keyword, nil_keyword), zk$obj_doc),
	( (manuals_keyword, scale_keyword, nil_keyword), zk$obj_scale),
	( (marker_keyword, board_keyword, nil_keyword),zk$obj_any_marker_board),
	( (media_keyword, cabinet_keyword, nil_keyword), zk$obj_cabinet),
	( (menu_keyword, nil_keyword, nil_keyword), zk$obj_menu),
	( (message_keyword, nil_keyword, nil_keyword), zk$obj_mail_message),
	( (mirror_keyword, nil_keyword, nil_keyword), zk$obj_mirror),
	( (money_keyword, nil_keyword, nil_keyword), zk$obj_any_money),
	( (needle_keyword, nil_keyword, nil_keyword), zk$obj_needle),
	( (neon_keyword, ball_keyword, nil_keyword), zk$obj_neon_ball),
	( (neon_keyword, crystal_keyword, ball_keyword), zk$obj_neon_ball),
	( (newspaper_keyword, nil_keyword, nil_keyword), zk$obj_any_newspaper),
	( (notes_keyword, nil_keyword, nil_keyword), zk$obj_notes),
	( (nurse_keyword, nil_keyword, nil_keyword), zk$obj_nurse),
	( (officer_keyword, nil_keyword, nil_keyword), zk$obj_officer),
	( (old_keyword, elvish_keyword, sword_keyword), zk$obj_sword),
	( (old_keyword, sword_keyword, nil_keyword), zk$obj_sword),
	( (orange_keyword, button_keyword, nil_keyword), zk$obj_orange_button),
	( (orange_keyword, wall_keyword, nil_keyword), zk$obj_wall),
	( (pack_keyword, nil_keyword, nil_keyword), zk$obj_any_disk),
	( (panel_keyword, nil_keyword, nil_keyword), zk$obj_control_panel),
	( (pattern_keyword, nil_keyword, nil_keyword), zk$obj_any_pattern),
	( (people_keyword, nil_keyword, nil_keyword), zk$obj_people),
	( (personnel_keyword, nil_keyword, nil_keyword), zk$obj_any_person),
	( (personnel_keyword, rep_keyword, nil_keyword), zk$obj_personnel_rep),
	( (plant_keyword, nil_keyword, nil_keyword), zk$obj_plant),
	( (possessions_keyword, nil_keyword, nil_keyword), zk$obj_possessions),
	( (pressure_keyword, machine_keyword, nil_keyword), zk$obj_bp_machine),
	( (product_keyword, manager_keyword, nil_keyword), zk$obj_manager),
	( (prototype_keyword, computer_keyword, nil_keyword), zk$obj_computer),
	( (prototype_keyword, nil_keyword, nil_keyword), zk$obj_computer),
	( (prototype_keyword, system_keyword, nil_keyword), zk$obj_computer),
	( (prototype_keyword, vax_keyword, nil_keyword), zk$obj_computer),
	( (quiz_keyword, nil_keyword, nil_keyword), zk$obj_diet_quiz),
	( (racks_keyword, nil_keyword, nil_keyword), zk$obj_tape_racks),
	( (reception_keyword,desk_keyword,nil_keyword), zk$obj_reception_desk),
	( (red_keyword, button_keyword, nil_keyword), zk$obj_red_button),
	( (rep_keyword, nil_keyword, nil_keyword), zk$obj_any_rep),
	( (room_keyword, nil_keyword, nil_keyword), zk$obj_current_room),
	( (rose_keyword, nil_keyword, nil_keyword), zk$obj_compass),
	( (route3_keyword, nil_keyword, nil_keyword), zk$obj_computer),
	( (rtl_keyword, developer_keyword, nil_keyword), zk$obj_stan),
	( (rug_keyword, nil_keyword, nil_keyword), zk$obj_rug),
	( (sack_keyword, nil_keyword, nil_keyword), zk$obj_sack),
	( (safe_keyword, nil_keyword, nil_keyword), zk$obj_safe),
	( (sailor_keyword, nil_keyword, nil_keyword), zk$obj_sailor),
	( (scale_keyword, nil_keyword, nil_keyword), zk$obj_scale),
	( (scratch_keyword, disk_keyword, nil_keyword), zk$obj_scratch_disk),
	( (sdc_keyword, card_keyword, nil_keyword), zk$obj_any_card),
	( (security_keyword, guard_keyword, nil_keyword), zk$obj_guard),
	( (self_keyword, nil_keyword, nil_keyword), zk$obj_self),
	( (service_keyword, rep_keyword, nil_keyword),zk$obj_field_service_rep),
	( (sign_keyword, nil_keyword, nil_keyword), zk$obj_any_sign),
	( (software_keyword, nil_keyword, nil_keyword), zk$obj_any_software),
	( (stairwell_keyword, door_keyword, nil_keyword), zk$obj_stair_door),
	( (strange_keyword, light_keyword, nil_keyword), zk$obj_strange_light),
	( (sword_keyword, nil_keyword, nil_keyword), zk$obj_sword),
	( (system_keyword, disk_keyword, nil_keyword), zk$obj_system_disk),
	( (system_keyword, nil_keyword, nil_keyword), zk$obj_computer),
	( (table_keyword, nil_keyword, nil_keyword), zk$obj_any_table),
	( (tape_keyword, drive_keyword, nil_keyword), zk$obj_tape_drive),
	( (tape_keyword, nil_keyword, nil_keyword), zk$obj_any_tape),
	( (tape_keyword, racks_keyword, nil_keyword), zk$obj_tape_racks),
	( (temporary_keyword, badge_keyword, nil_keyword), zk$obj_badge),
	( (terminal_keyword, nil_keyword, nil_keyword), zk$obj_any_terminal),
	( (today_keyword, newspaper_keyword, nil_keyword), zk$obj_zk_today),
	( (today_keyword, nil_keyword, nil_keyword), zk$obj_zk_today),
	( (vax_keyword, computer_keyword, nil_keyword), zk$obj_computer),
	( (vax_keyword, computer_keyword, prototype_keyword), zk$obj_computer),
	( (vax_keyword, nil_keyword, nil_keyword), zk$obj_computer),
	( (vax_keyword, prototype_keyword, computer_keyword), zk$obj_computer),
	( (vax_keyword, prototype_keyword, nil_keyword), zk$obj_computer),
	( (vax_keyword, system_keyword, nil_keyword), zk$obj_computer),
	( (video_keyword, nil_keyword, nil_keyword), zk$obj_any_terminal),
	( (video_keyword, terminal_keyword, nil_keyword), zk$obj_any_terminal),
	( (vms_keyword, developer_keyword, nil_keyword), zk$obj_vms_developer),
	( (vms_keyword, manager_keyword, nil_keyword), zk$obj_manager),
	( (vms_keyword, product_keyword, manager_keyword), zk$obj_manager),
	( (vms_keyword, tape_keyword, nil_keyword), zk$obj_vms_tape),
	( (wall_keyword, nil_keyword, nil_keyword), zk$obj_wall),
	( (working_keyword, coins_keyword, machine_keyword),
						zk$obj_working_coin_machine),
	( (yellow_keyword, button_keyword, nil_keyword), zk$obj_yellow_button),
	( (zk_keyword, enquirer_keyword, newspaper_keyword),zk$obj_zk_enquirer),
	( (zk_keyword, enquirer_keyword, nil_keyword), zk$obj_zk_enquirer),
	( (zk_keyword, journal_keyword, newspaper_keyword), zk$obj_zk_journal),
	( (zk_keyword, journal_keyword, nil_keyword), zk$obj_zk_journal),
	( (zk_keyword, newspaper_keyword, nil_keyword), zk$obj_any_newspaper),
	( (zk_keyword, today_keyword, newspaper_keyword), zk$obj_zk_today),
	( (zk_keyword, today_keyword, nil_keyword), zk$obj_zk_today));

[global] function zk$test_symbol(expected : $symbol_set) : boolean;
var	error : boolean;
	symbol : $symbol_desc;
	message : unsigned;
begin
	error:=false;
	$get_symbol(symbol);
	if ( not (symbol.token in expected)) then
	  begin
		error:=true;
		if (end_of_line in expected) then
			message:=zk$text_unnecessary_word
		else
		if (in_keyword in expected) then message:=zk$text_in_where
		else
		if (to_keyword in expected) then message:=zk$text_to_whom
		else
			case (symbol.token) of
			unknown:	message:=zk$text_unknown_word;
			invalid:	message:=zk$text_invalid_char;
			end_of_line,
			period_symbol,
			then_keyword:	message:=zk$text_incomplete;
			text_string:	message:=zk$text_cant_use_string;
			integer_constant:message:=zk$text_cant_use_number;
			otherwise	message:=zk$text_cant_use_word;
			end;
		$message(message, 2, symbol.string.length,
				iaddress(symbol.string.body));
	  end;

	zk$test_symbol:=error;
end;

[global] function parse_object_name(
	var object_code : integer;
	followers : $symbol_set) : boolean;

var	end_of_obj, error : boolean;
	keyword : $keyword_array;
	symbol : $symbol_desc;
	state, i, t, b, m : integer;
begin
	keyword[1]:=undefined; keyword[2]:=undefined; keyword[3]:=undefined;
	end_of_obj:=false;

	$get_symbol(symbol);
	if (symbol.token = the_keyword) then $advance_symbol;

	t:=1; b:=object_table_size; error:=true;
	while ( (b>=t) and (error) ) do
	  begin
		m:=t + (b - t) div 2;

		state:=0; i:=0;
		while ( (state=0) and (i<keywords_per_object) ) do
		  begin
			i:=i+1;
			if (keyword[i]=undefined) then
			  begin
				if ( (i>1) and (not end_of_obj) ) then
					$advance_symbol;
				$get_symbol(symbol);
				if (symbol.token in followers) then
				  begin
					keyword[i]:=nil_keyword;
					end_of_obj:=true;
				  end
				else	keyword[i]:=symbol.token;
			  end;

			if (keyword[i]<object_table[m].keyword[i]) then
				state:=-1
			else
			if (keyword[i]>object_table[m].keyword[i]) then
				state:=1
		  end;

		if (state=0) then error:=false
		else
			if (state=-1) then b:=m-1 else t:=m+1;
	  end;

	if (not error) then
	  begin
		if (not end_of_obj) then $advance_symbol;
		object_code:=object_table[m].object;
	  end
	else	zk$test_symbol([]);

	parse_object_name:=error;
end;

[global] function zk$parse_object(
	var ast : $ast_node_ptr;
	followers : $symbol_set) : boolean;

var	error : boolean;
	object_code : integer;
	symbol : $symbol_desc;
begin
	$get_symbol(symbol);
	if (symbol.token = all_keyword) then
	  begin
		$advance_symbol;
		object_code:=zk$obj_all;
		error:=false;
	  end
	else	error:=parse_object_name(object_code, followers+[from_keyword]);

	if (not error) then
	  begin
		new(ast, object_node);
		ast^.node_type:=object_node; ast^.list:=nil;
		ast^.object_code:=object_code; ast^.from:=0;

		$get_symbol(symbol);
		if (symbol.token = from_keyword) then
		  begin
			$advance_symbol;
			error:=parse_object_name(ast^.from, followers);
		  end;
	  end
	else	ast:=nil;

	zk$parse_object:=error;
end;

[global] function zk$parse_object_list(
	var ast : $ast_node_ptr;
	var verb : varying[$u1] of char;
	followers : $symbol_set) : boolean;

var	error : boolean;
	symbol : $symbol_desc;
	next_ast : $ast_node_ptr;
begin
	$get_symbol(symbol);
	if (symbol.token in followers) then
	  begin
		error:=true;
		$message(zk$text_want_to_verb, 2,
				verb.length, iaddress(verb.body));
	  end
	else
	  begin
		error:=zk$parse_object(ast, followers + [and_keyword]);
		next_ast:=ast;

		$get_symbol(symbol);
		while ( (not error) and (symbol.token = and_keyword) ) do
		  begin
			$advance_symbol;
			error:=zk$parse_object(next_ast^.list,
					followers + [and_keyword]);
			if (not error) then
			  begin
				next_ast:=next_ast^.list;
				$get_symbol(symbol);
			  end;
		  end;
	  end;
	zk$parse_object_list:=error
end;

end.
