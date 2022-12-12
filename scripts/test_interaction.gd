extends RigidBody

var interactions = [["interact1", "Interact 1"], ["interact2", "Interact 2"]]

func _ready():
	self.set_meta("interactable", true)
	self.set_meta("interaction", "TestInteraction")

func interact1():
	print(1)

func interact2():
	print(2)
