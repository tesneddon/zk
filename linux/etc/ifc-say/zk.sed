# zk.sed: pronunciation fixes for ZK, applied by ifc-say to the game's
# text before DECtalk reads it.  [ and ] have already been stripped from
# the game's text, so DECtalk commands added here are the only ones it
# sees.  One sed command per line; for example:
#
#   s/Nashua/Nash-oo-a/g
#   1s/^/[:rate 160] /
#
# After a change, empty the rendered cache so that old text is redone:
#   rm /var/lib/asterisk/sounds/zk/t*
s/\bOpenVMS\b/Open V M S/g
