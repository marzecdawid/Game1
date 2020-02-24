extends Node2D


func _enter_tree():
	randomize()


func _on_game_over():
	$LeftSegment.reset()
	$RightSegment.reset()


func _on_input_button_down(action):
	Input.action_press(action)
