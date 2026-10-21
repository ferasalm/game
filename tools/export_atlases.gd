extends SceneTree
## Exports the code-painted world atlases (PaintedAtlases) to PNG for the offline painterly bake. Image work only,
## so it runs headless: tools/run_godot.sh -s res://tools/export_atlases.gd -- [out_dir]
## then: python tools/art/painterly_bake.py (reads .bake/atlases, writes assets/textures/painted/<recipe>/).

const DEFAULT_OUT: String = "res://.bake/atlases"
## Loaded at run time: autoloads (ContentDB) exist only after this script has compiled.
const ATLASES_PATH: String = "res://features/world/view/painted_atlases.gd"


func _process(_delta: float) -> bool:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else DEFAULT_OUT
	var dir: String = ProjectSettings.globalize_path(out)
	DirAccess.make_dir_recursive_absolute(dir)
	var count: int = (load(ATLASES_PATH) as GDScript).call(&"export_to", dir)
	print("export_atlases: %d atlases in %s" % [count, dir])
	return true
