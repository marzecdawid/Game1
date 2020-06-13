extends Node2D


func _enter_tree():
	randomize()


func _on_game_over():
	$LeftSegment.reset()
	$RightSegment.reset()


# TODOs:
# - add some visual indicator when boost is ready
# - add touch input for using boost
# - make bot use boost
# - make difficulty scaling based on distance, not time
# - add score based on distance
# - add simple input buffer; save last input for like 0.5s
# - ?? maybe smooth out boost and the way other objects move when player gets to high,
#		using Camera2D seems to be the best for that
# - MAKE SOME ART!
