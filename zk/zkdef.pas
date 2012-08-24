module zk$definitions;

(* Enumerated types for tokens.  The directions must be first, in the order
   specified.  Any token which will appear in the 'token to object' table
   must be listed in alphabetical order. *)

type	$symbol_token =
		      ( north_keyword, south_keyword, east_keyword,
			west_keyword, north_east_keyword, south_west_keyword,
			south_east_keyword, north_west_keyword, up_keyword,
			down_keyword, in_keyword, out_keyword,

			all_keyword, and_keyword, arm_keyword, ascii_keyword,
			at_keyword, back_keyword, badge_keyword,
			ball_keyword, bank_keyword, bars_keyword,
			bills_keyword, black_keyword, blank_keyword,
			blood_keyword, blue_keyword,
			board_keyword, boot_keyword, brief_keyword,
			broken_keyword, building_keyword, bulletin_keyword,
			burlap_keyword,	button_keyword,
			cabinet_keyword, cafeteria_keyword, can_keyword,
			card_keyword, cdd_keyword, close_keyword,
			coins_keyword, coke_keyword, comma_symbol,
			compass_keyword, computer_keyword,
			console_keyword, contents_keyword, control_keyword,
			crystal_keyword, dark_keyword, debris_keyword,
			desk_keyword, developer_keyword, diet_keyword,
			discarded_keyword, disk_keyword, doc_keyword,
			door_keyword, drink_keyword, drive_keyword,
			drop_keyword, dtr_keyword,
			edswbl_keyword,	end_of_line,
			elevator_keyword, elvish_keyword, empty_keyword,
			enquirer_keyword, enter_keyword, examine_keyword,
			exit_keyword, field_keyword,
			fluorescent_keyword, follow_keyword, from_keyword,
			get_keyword, give_keyword, glass_keyword,
			go_keyword, guard_keyword, heal_keyword,
			helicopter_keyword, hello_keyword,
			information_keyword,
			install_keyword, integer_constant, invalid,
			inventory_keyword, is_keyword, 
			journal_keyword, jump_keyword,
			keypad_keyword, keys_keyword, kill_keyword,
			lamp_keyword, light_keyword, liquid_keyword,
			listings_keyword, locate_keyword, lock_keyword,
			look_keyword, machine_keyword, magazine_keyword,
			magic_keyword, mahogany_keyword,
			mail_keyword, manager_keyword,
			manuals_keyword, marker_keyword, media_keyword,
			menu_keyword, message_keyword, mirror_keyword,
			money_keyword,
			move_keyword, needle_keyword, neon_keyword,
			newspaper_keyword, nil_keyword, notes_keyword,
			nurse_keyword, off_keyword,
			officer_keyword, old_keyword, on_keyword,
			open_keyword, orange_keyword, pack_keyword,
			panel_keyword, pattern_keyword,	people_keyword,
			period_symbol, personnel_keyword, pick_keyword,
			play_keyword, plant_keyword, please_keyword,
			plugh_keyword,
			possessions_keyword, pray_keyword, pressure_keyword,
			product_keyword, prototype_keyword,
			put_keyword, quit_keyword, quiz_keyword,
			racks_keyword, read_keyword, reception_keyword,
			red_keyword, rep_keyword, restart_keyword,
			restore_keyword,
			room_keyword, rose_keyword, route3_keyword,
			rtl_keyword, rub_keyword, rug_keyword, sack_keyword,
			safe_keyword, sailor_keyword, save_keyword,
			say_keyword, scale_keyword, score_keyword,
			scratch_keyword, scream_keyword, 
			sdc_keyword, security_keyword, self_keyword,
			service_keyword, shake_keyword,
			shut_keyword, sign_keyword, software_keyword,
			stairwell_keyword, stand_keyword,
			start_keyword, stop_keyword, strange_keyword,
			sword_keyword, system_keyword,
			table_keyword, take_keyword, tape_keyword,
			tell_keyword, temporary_keyword,
			terminal_keyword, text_string,
			the_keyword, then_keyword, today_keyword, to_keyword,
			turn_keyword, type_keyword,
			undefined, unknown, unlock_keyword,
			vax_keyword, verbose_keyword, version_keyword,
			video_keyword,
			vms_keyword, wait_keyword, wall_keyword,
			wear_keyword, where_keyword, with_keyword,
			working_keyword, xyzzy_keyword,
			yellow_keyword, zk_keyword);

	$symbol_set = set of $symbol_token;
	$symbol_value = [unsafe] integer;
	$symbol_string = varying[132] of char;

	$symbol_desc = record
			string : $symbol_string;
			token : $symbol_token;
			value : $symbol_value;
			end;

	$ast_node_types = (command_node, object_node, string_node,
			   number_node);
	$ast_node_ptr = ^$ast_node;
	$ast_node = record
			list : $ast_node_ptr;
			case node_type : $ast_node_types of
			command_node:
				(keyword1, keyword2 : $symbol_token;
				 left, right : $ast_node_ptr;
				 please : boolean);
			object_node:
				(object_code, from : integer);
			string_node:
				(string : $symbol_string);
			number_node:
				(number : integer);
		    end;
end.
