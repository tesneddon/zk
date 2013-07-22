[inherit('lib$:typedef',
	 'lib$:zk$obj', 
	 'lib$:zk$room')]
module zk$context_def;

(* Edit History:							    *)

(* 19-JUL-2013 TES Changed to add a length for username and full buffer of  *)
(*		   32 characters.					    *)
(*									    *)

type	$object_flags = [long, unsafe] record
				case integer of
				1: (long : unsigned);
				2: (
				generic :		[bit, pos(0)] boolean;
				static :		[bit, pos(1)] boolean;
				strength_infinite :	[bit, pos(2)] boolean;
				capacity_infinite : 	[bit, pos(3)] boolean;
				area_infinite : 	[bit, pos(4)] boolean;
				readable : 		[bit, pos(5)] boolean;
				openable : 		[bit, pos(6)] boolean;
				lockable : 		[bit, pos(7)] boolean;
				startable :		[bit, pos(8)] boolean;
				cognizant :		[bit, pos(9)] boolean;
				machine :		[bit, pos(10)] boolean;
				flexible :		[bit, pos(11)] boolean;
				room :			[bit, pos(12)] boolean;
				unused5 :		[bit, pos(13)] boolean;
				unused6 :		[bit, pos(14)] boolean;
				unused7 :		[bit, pos(15)] boolean;
				inside :		[bit, pos(16)] boolean;
				no_capacity :		[bit, pos(17)] boolean;
				no_area :		[bit, pos(18)] boolean;
				open :			[bit, pos(19)] boolean;
				locked :		[bit, pos(20)] boolean;
				on :			[bit, pos(21)] boolean;
				irritated :		[bit, pos(22)] boolean;
				shaken :		[bit, pos(23)] boolean;
				)
			end;

	$context_flags = [long, unsafe] record
				case integer of
				1: (long : unsigned);
				2: (
				start :		[bit, pos(0)] boolean;
				brief :		[bit, pos(1)] boolean;
				won :		[bit, pos(2)] boolean;
				quit :		[bit, pos(3)] boolean;
				died :		[bit, pos(4)] boolean;
				standing_on_doc :
						[bit, pos(5)] boolean;
				awarded_dtr :	[bit, pos(6)] boolean;
				lamp_on :	[bit, pos(7)] boolean;
				unused1 :	[bit, pos(8)] boolean;
				booted :	[bit, pos(9)] boolean;
				vms_installed :	[bit, pos(10)] boolean;
				cdd_installed :	[bit, pos(11)] boolean;
				dtr_installed :	[bit, pos(12)] boolean;
				field_service :	[bit, pos(13)] boolean;
				bp_taken :	[bit, pos(14)] boolean;
				weight_taken :	[bit, pos(15)] boolean;
				physical :	[bit, pos(16)] boolean;
				interview :	[bit, pos(17)] boolean;
				elevator_unlocked : [bit, pos(18)] boolean;
				messages_pending : [bit, pos(19)] boolean;
				multi_user :	[bit, pos(20)] boolean;
				)
			  end;

	$object_ptr = ^$object;
	$object = record
			number : integer;
			location : integer;
			flags : $object_flags;
			total_mass : integer;
			strength : integer;
			remaining_capacity : integer;
			fixed_volume : integer;
			remaining_area : integer;
			fixed_size : integer;
			contents : $object_ptr;
			owner : $object_ptr;
			link : $object_ptr;
			next : $object_ptr;
		  end;

	$room_info = record
			seen : boolean;
			class : integer;
			room : $object_ptr;
		     end;

	$room_array = array[1..zk$room_max] of $room_info;

	$context_block = record
				username : packed array[1..32] of char;
				username_length : $uword;
				flags : $context_flags;
				room : $room_array;

				location : integer;
				score : integer;
				moves : integer;
				seed : unsigned;
				combination : integer;
				officer_leave_time : integer;
				lamp_remaining : integer;
				card_remaining : integer;
				console_message : integer;
				fs_remaining : integer;
				questions_remaining : integer;
				current_question : integer;
				crew_location : integer;
				crew_last_location : integer;
				badge_issued : $uquad;
				question_asked : packed array[1..32]
							of boolean;

				self : $object_ptr;
				lights_ptr : $object_ptr;
				arm_ptr : $object_ptr;

				card_ptr : $object_ptr;
				tape_drive_ptr : $object_ptr;
				disk_drive_ptr : $object_ptr;
				lamp_ptr : $object_ptr;
			 end;
end.
