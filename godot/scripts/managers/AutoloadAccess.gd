extends RefCounted

## Resolve project autoloads without global identifier references (headless-safe compile).
## Use via: const AutoloadAccessLib := preload("res://scripts/managers/AutoloadAccess.gd")


static func get_autoload(name: String) -> Node:
	var tree := Engine.get_main_loop()
	if tree == null or not (tree is SceneTree):
		return null
	var scene_tree: SceneTree = tree
	var root: Window = scene_tree.root
	if root == null:
		return null
	return root.get_node_or_null("/root/" + name)


static func call_method(autoload_name: String, method: String, args: Array = []) -> Variant:
	var node := get_autoload(autoload_name)
	if node == null or not node.has_method(method):
		return null
	return node.callv(method, args)


static func get_property(autoload_name: String, property: String, default: Variant = null) -> Variant:
	var node := get_autoload(autoload_name)
	if node == null or not property in node:
		return default
	return node.get(property)


static func set_property(autoload_name: String, property: String, value: Variant) -> void:
	var node := get_autoload(autoload_name)
	if node == null or not property in node:
		return
	node.set(property, value)
