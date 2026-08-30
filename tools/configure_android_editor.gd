@tool
extends SceneTree

func _initialize() -> void:
	var settings := EditorInterface.get_editor_settings()
	settings.set_setting("export/android/java_sdk_path", "C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot")
	settings.set_setting("export/android/android_sdk_path", "C:/Users/klehv/AppData/Local/Android/Sdk")
	settings.set_setting("export/android/debug_keystore", "C:/Users/klehv/AppData/Roaming/Godot/keystores/debug.keystore")
	settings.set_setting("export/android/debug_keystore_user", "androiddebugkey")
	settings.set_setting("export/android/debug_keystore_pass", "android")
	settings.save()
	print("Configured Godot Android editor paths")
	quit(0)
