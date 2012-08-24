define/key pf1 ""/set_state=gold

define/key pf2 "Inventory Self"/term
define/key pf2 "Inventory Room"/if_state=gold/term
define/key pf3 "Examine All"/term
define/key pf4 "Take All"/term
define/key pf4 "Drop All"/if_state=gold/term
define/key kp0 "Look"/term
define/key comma "in"/term
define/key comma "out"/if_State=gold/term
define/key period "say digital software engineering"/term/noecho

define/key kp7 "North West"/term
define/key kp8 "North"/term
define/key kp9 "North East"/term
define/key kp4 "West"/term
define/key kp5 "Down"/term
define/key kp5 "Up"/if_state=gold/term
define/key kp6 "East"/term
define/key kp1 "South West"/term
define/key kp2 "South"/term
define/key kp3 "South East"/term
