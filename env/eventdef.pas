[inherit('lib$:typedef')] module eventdef;

function time$map_event : unsigned;
	extern;

function time$put_event(
	event_code : char;
	var username : varying[$u1] of char;
	condition : unsigned;
	var message : varying[$u2] of char) : unsigned;
	extern;

function time$get_event(
	var reader : integer;
	var date_time : $quad;
	var event_code : char;
	var username : varying[$u1] of char;
	var condition : unsigned;
	var message : varying[$u2] of char) : unsigned;
	extern;

function time$unmap_event : unsigned;
	extern;

end.

