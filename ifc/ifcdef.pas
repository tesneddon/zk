[inherit('lib$:typedef')]
module ifc$def;

type    $longword = [unsafe, long] packed record
                        case integer of
                        1 : (long : unsigned);
                        2 : (word0, word1 : $uword);
                        3 : (byte0, byte1, byte2, byte3 : $ubyte);
                        end;

type	$symbol_token = (identifier, integer_constant, unknown,
			 invalid, end_of_file, text_string,
			 character,

			 plus_symbol, minus_symbol, star_symbol,
			 fslash_symbol, equal_symbol, left_paren_symbol,
			 right_paren_symbol, semicolon_symbol,
			 colon_symbol, comma_symbol, dot_symbol,

			 prefix_keyword, ident_keyword, message_keyword,
			 end_keyword, fao_keyword, description_keyword,
			 name_keyword, room_keyword, north_keyword,
			 south_keyword, east_keyword, west_keyword,
			 north_east_keyword, south_west_keyword,
			 south_east_keyword, north_west_keyword,
			 up_keyword, down_keyword, in_keyword,
			 out_keyword, object_keyword,
			 detail_keyword, strength_keyword, capacity_keyword,
			 area_keyword, mass_keyword, volume_keyword,
			 size_keyword, generic_keyword, specific_keyword,
			 static_keyword, initial_keyword, infinite_keyword,
			 bold_keyword, reverse_keyword, blink_keyword,
			 underline_keyword, readable_keyword,
			 openable_keyword, door_keyword, lockable_keyword,
			 startable_keyword, cognizant_keyword, machine_keyword,
			 flexible_keyword, class_keyword);

	$symbol_set = set of $symbol_token;
	$symbol_value = [unsafe] integer;
	$symbol_string = varying[132] of char;

	$symbol_desc = record
			string : $symbol_string;
			token : $symbol_token;
			value : $symbol_value;
			error : boolean;
			end;

	$error_code = (error_strtrm, error_invchr, error_syntax,
		       error_expect, error_sync, error_skip,
		       error_muldef);

end.
