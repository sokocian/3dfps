extends RigidBody

var interactions = [["heal", "Heal"], ["pickup", "Pickup"]]

func _ready():
	self.set_meta("interactable", true)
	self.set_meta("interaction", "HealthKit")

func pickup():
	queue_free()

func heal():
	var player = get_node("/root/Master/Player")
	player.update_health(10)
	queue_free()
