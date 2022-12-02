extends Node

func get_camera_target(camera_ray):
	return camera_ray.get_collider()

func interact_node(node):
	if node != null and node.has_meta("interactable") and node.get_meta("interactable"):
		node.interact()
