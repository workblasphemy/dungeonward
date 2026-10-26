extends SceneTree
## Project-shell checks only; gameplay contract tests arrive with their implementations.
var checks: int = 0
var failures: int = 0

func check(condition: bool, description: String) -> void:
    checks += 1
    if condition:
        print("PASS: ", description)
    else:
        failures += 1
        push_error("FAIL: " + description)

func _initialize() -> void:
    var version: Dictionary = Engine.get_version_info()
    check(version.major == 4 and version.minor == 7 and version.patch == 2,
        "approved engine version is 4.7.2")
    check(ProjectSettings.get_setting("application/run/main_scene") == "res://game/main.tscn",
        "project boots the foundation scene")
    var packed: PackedScene = load("res://game/main.tscn") as PackedScene
    check(packed != null, "main scene loads")
    if packed != null:
        var scene: Node = packed.instantiate()
        root.add_child(scene)
        check(scene is Control, "main scene instantiates as the application shell")
        var status: Label = scene.get_node_or_null("FoundationStatus") as Label
        check(status != null and status.text.contains("M0 foundation"),
            "foundation status is visible in the scene")
        scene.free()
    if "--self-test-failure" in OS.get_cmdline_user_args():
        check(false, "intentional runner failure probe")
    print("RESULT: %d checks, %d failures" % [checks, failures])
    quit(1 if failures else 0)
