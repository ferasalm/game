class_name LayoutSettle
extends RefCounted
## purpose: Test helper: lays out Containers now (top-down), since tests measure before the deferred sort runs.


static func run(root: Node) -> void:
	if root is Container:
		(root as Container).notification(Container.NOTIFICATION_SORT_CHILDREN)
	for child: Node in root.get_children():
		run(child)
