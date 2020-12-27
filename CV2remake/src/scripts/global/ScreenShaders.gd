extends CanvasLayer

signal black_fadein_complete
signal black_fadeout_complete

func black_fadein(length: int) -> void:
	$BlackOverlay.visible = true
	for i in range(length):
		$BlackOverlay.color.a = float(i)/float(length)
		yield(get_tree().create_timer(1.0/60), "timeout")
	$BlackOverlay.color.a = 1.0
	emit_signal("black_fadein_complete")

func black_fadeout(length: int) -> void:
	for i in range(length):
		$BlackOverlay.color.a = 1.0 - float(i)/float(length)
		yield(get_tree().create_timer(1.0/60), "timeout")
	$BlackOverlay.color.a = 0.0
	$BlackOverlay.visible = false
	emit_signal("black_fadeout_complete")
