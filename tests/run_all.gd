extends SceneTree
## M0 project-shell and pure lobby contract checks.
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
    var lobby_script: Script = load("res://game/core/lobby/lobby_registry.gd") as Script
    check(lobby_script != null, "M0 lobby registry script loads")
    if lobby_script != null:
        var lobby: Variant = lobby_script.new()
        var first: Dictionary = lobby.reserve(1, 0, 1, 0, "token-a")
        check(first["ok"], "first slot reservation succeeds")
        check(lobby.reserve(1, 0, 1, 0, "token-b")["error_code"] == "SLOT_OCCUPIED",
            "duplicate local slot rejected")
        check(lobby.reserve(2, 0, 1, 0, "token-a")["error_code"] == "TOKEN_REUSED",
            "duplicate reservation token rejected")
        var second: Dictionary = lobby.reserve(2, 0, 1, 0, "token-b")
        check(second["ok"], "second peer reserves same local index")
        check(not lobby.select_character(2, first["session_player_id"], "token-a",
            "profile-a", "character-a", 1, 0, 0)["ok"], "foreign sender rejected")
        check(lobby.select_character(1, first["session_player_id"], "token-a",
            "profile-a", "character-a", 1, 0, 0)["ok"], "owner selects character")
        check(lobby.select_character(2, second["session_player_id"], "token-b",
            "profile-b", "character-a", 1, 0, 0)["error_code"] == "CHARACTER_OCCUPIED",
            "duplicate character rejected")
        check(lobby.snapshot().size() == 2, "snapshot includes both reservations")
        lobby.release_peer(1)
        check(lobby.select_character(2, second["session_player_id"], "token-b",
            "profile-b", "character-a", 1, 0, 0)["ok"], "disconnect releases character lock")
        check(lobby.release(2, second["session_player_id"], "token-b")["ok"],
            "owner release succeeds")
        check(lobby.release(2, second["session_player_id"], "token-b")["error_code"] == "OK",
            "release is idempotent")
        var expiring: Dictionary = lobby.reserve(3, 0, 1, 0, "token-c")
        lobby.expire(60000)
        check(lobby.snapshot().is_empty(), "reservation expires at deadline")
        check(lobby.reserve(3, 0, 1, 60000, "token-d")["session_player_id"] >
            expiring["session_player_id"], "session player IDs are not reused")
        var private_seat: Dictionary = lobby.reserve(4, 0, 1, 60000, "token-private")
        var before_private: Array[Dictionary] = lobby.snapshot()
        var foreign_release: Dictionary = lobby.release(99, private_seat["session_player_id"], "wrong")
        var unknown_release: Dictionary = lobby.release(99, 99999, "wrong")
        check(foreign_release == unknown_release, "foreign and unknown release responses are identical")
        check(lobby.snapshot() == before_private, "foreign release does not mutate state")
        check(lobby.release(4, private_seat["session_player_id"], "token-private")["ok"],
            "owner can release seat")
        var pending: Dictionary = lobby.reserve(5, 0, 1, 0, "token-pending")
        check(lobby.select_character(5, pending["session_player_id"], "token-pending",
            "profile-p", "character-p", 1, 0, 100)["ok"], "selection begins inactivity deadline")
        lobby.expire(60099)
        check(lobby.snapshot().size() == 2, "selected seat survives before deadline")
        check(lobby.refresh_pending(5, pending["session_player_id"], "token-pending", 60099)["ok"],
            "valid progress refreshes selected-seat timeout")
        lobby.expire(120098)
        check(lobby.snapshot().size() == 1, "refreshed seat survives until deadline")
        lobby.expire(120099)
        check(lobby.snapshot().is_empty(), "selected seat expires at refreshed deadline")
        var reuse: Dictionary = lobby.reserve(6, 0, 1, 120099, "token-reuse")
        check(lobby.select_character(6, reuse["session_player_id"], "token-reuse",
            "profile-r", "character-p", 1, 0, 120099)["ok"],
            "expired character lock is released")
        lobby.release_peer(6)
        lobby.release_peer(3)
        var capacity: Variant = lobby_script.new()
        for slot_id in range(4):
            check(capacity.reserve(1, slot_id, 1, 0, "cap-%d" % slot_id)["ok"],
                "one peer reserves slot %d" % slot_id)
        var full_before: Array[Dictionary] = capacity.snapshot()
        check(capacity.reserve(2, 0, 1, 0, "cap-extra")["error_code"] == "LOBBY_FULL",
            "fifth reservation rejected")
        check(capacity.snapshot() == full_before, "capacity rejection does not mutate state")
        for distribution in [[3, 1], [2, 1, 1], [1, 1, 1, 1]]:
            var matrix: Variant = lobby_script.new()
            var peer_id: int = 1
            for count in distribution:
                for local_id in range(count):
                    check(matrix.reserve(peer_id, local_id, 1, 0,
                        "matrix-%d-%d" % [peer_id, local_id])["ok"],
                        "capacity distribution %s peer %d local %d" % [str(distribution), peer_id, local_id])
                peer_id += 1
            check(matrix.snapshot().size() == 4, "distribution %s fills four seats" % str(distribution))
    if "--self-test-failure" in OS.get_cmdline_user_args():
        check(false, "intentional runner failure probe")
    print("RESULT: %d checks, %d failures" % [checks, failures])
    quit(1 if failures else 0)
