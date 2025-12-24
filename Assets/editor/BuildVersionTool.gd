@tool
extends EditorScript

func _run():
	var file := ConfigFile.new()
	var err := file.load("res://build_info.cfg")
	if err != OK:
		file.set_value("build", "number", 0)
	var num := int(file.get_value("build", "number", 0))
	num += 1
	file.set_value("build", "number", num)
	file.save("res://build_info.cfg")

	var version_string := "0.1.%d" % num
	ProjectSettings.set_setting("application/config/version", version_string)
	ProjectSettings.save()
	print("Updated build to %s" % version_string)
