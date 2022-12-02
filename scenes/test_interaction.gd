extends StaticBody

func _ready():
	self.set_meta("interactable", true)

func interact():
	$Mesh.get_active_material(0).set_albedo(Color(randf(), randf(), randf()))
