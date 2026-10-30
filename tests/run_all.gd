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
    var token_script: Script = load("res://game/core/identity/reservation_token_provider.gd") as Script
    check(token_script != null, "secure token provider loads")
    if token_script != null:
        var provider: Variant = token_script.new()
        var secure_a: String = provider.generate_token()
        var secure_b: String = provider.generate_token()
        check(secure_a.length() == 32, "secure token has 128-bit hex length")
        check(secure_a != secure_b, "two secure tokens differ")
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
        check(lobby.snapshot().size() == before_private.size() - 1,
            "authorized release actually removes its seat")
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
    var auth_script: Script = load("res://game/core/network/m0_request_authorizer.gd") as Script
    check(auth_script != null, "M0 request authorizer loads")
    if auth_script != null:
        var auth: Variant = auth_script.new()
        var request: Dictionary = {"request_id": "r1", "local_slot_id": 0, "protocol_version": 1}
        var issued: Dictionary = auth.request_slot(1, request, 0)
        check(issued["ok"] and issued["reservation_token"].length() == 32,
            "trusted host generates reservation token")
        check(auth.request_slot(1, request, 0) == issued, "identical replay returns cached result")
        check(auth.registry_snapshot().size() == 1, "replayed reservation does not allocate again")
        check(auth.request_slot(1, {"request_id": "r1", "local_slot_id": 1,
            "protocol_version": 1}, 0)["error_code"] == "REQUEST_ID_CONFLICT",
            "conflicting replay rejected")
        check(auth.request_slot(1, {"request_id": "bad", "local_slot_id": "0",
            "protocol_version": 1}, 0)["error_code"] == "INVALID_MESSAGE",
            "invalid field types rejected")
        check(auth.request_slot(1, {"request_id": "extra", "local_slot_id": 1,
            "protocol_version": 1, "peer_id": 2}, 0)["error_code"] == "INVALID_MESSAGE",
            "untrusted sender field rejected")
        var selection: Dictionary = {"request_id": "s1",
            "session_player_id": issued["session_player_id"],
            "reservation_token": issued["reservation_token"], "owner_profile_id": "owner-a",
            "character_id": "char-a", "save_schema": 1, "save_revision": 0}
        check(auth.select_character(2, selection, 0)["error_code"] == "UNAUTHORIZED",
            "sender identity is supplied by trusted adapter")
        check(auth.select_character(1, selection, 0)["ok"], "authorized character selection succeeds")
        check(auth.select_character(1, selection, 0)["ok"], "character selection replay is idempotent")
        var revision: int = auth.registry_snapshot()[0]["revision"]
        var advance: Dictionary = {"request_id": "a1",
            "session_player_id": issued["session_player_id"],
            "reservation_token": issued["reservation_token"],
            "expected_revision": revision - 1, "next_state": "READY"}
        check(auth.advance_state(1, advance, 0)["error_code"] == "STALE_REVISION",
            "stale revision rejected")
        advance["request_id"] = "a2"
        advance["expected_revision"] = revision
        check(auth.advance_state(1, advance, 0)["ok"], "READY transition accepted")
        check(auth.advance_state(1, advance, 0)["ok"], "READY replay is idempotent")
        advance["request_id"] = "a3"
        advance["expected_revision"] = auth.registry_snapshot()[0]["revision"]
        advance["next_state"] = "ACTIVE"
        check(auth.advance_state(1, advance, 0)["ok"], "ACTIVE transition accepted")
        check(auth.registry_snapshot()[0]["state"] == "ACTIVE", "ACTIVE state recorded")
        auth.host_expire(999999)
        check(auth.registry_snapshot().size() == 1, "ACTIVE slot exempt from join timeout")
        auth.host_disconnect(1)
        check(auth.registry_snapshot().is_empty(), "host disconnect cleans up active seat")
        var release_auth: Variant = auth_script.new()
        var release_issued: Dictionary = release_auth.request_slot(11,
            {"request_id": "rel-reserve", "local_slot_id": 0, "protocol_version": 1}, 0)
        var release_payload: Dictionary = {"request_id": "rel-1",
            "session_player_id": release_issued["session_player_id"],
            "reservation_token": release_issued["reservation_token"]}
        var release_before: Array[Dictionary] = release_auth.registry_snapshot()
        check(release_auth.release_slot(12, release_payload, 0)["ok"],
            "foreign release is non-disclosing")
        check(release_auth.registry_snapshot() == release_before,
            "foreign release leaves ownership unchanged")
        check(release_auth.release_slot(11, {"request_id": "rel-invalid",
            "session_player_id": release_issued["session_player_id"],
            "reservation_token": 123}, 0)["error_code"] == "INVALID_MESSAGE",
            "release rejects invalid token types")
        check(release_auth.release_slot(11, release_payload, 0)["ok"],
            "authorized release via authorizer succeeds")
        check(release_auth.registry_snapshot().is_empty(),
            "authorized release via authorizer frees seat")
        check(release_auth.release_slot(11, release_payload, 0)["ok"],
            "release request replay is idempotent")
        release_payload["request_id"] = "rel-2"
        check(release_auth.release_slot(11, release_payload, 0)["ok"],
            "release with a new request ID is idempotent")
        var ready_auth: Variant = auth_script.new()
        var ready_slot: Dictionary = ready_auth.request_slot(7,
            {"request_id": "ready-r", "local_slot_id": 0, "protocol_version": 1}, 0)
        check(ready_auth.select_character(7,
            {"request_id": "ready-s", "session_player_id": ready_slot["session_player_id"],
             "reservation_token": ready_slot["reservation_token"],
             "owner_profile_id": "owner-ready", "character_id": "character-ready",
             "save_schema": 1, "save_revision": 0}, 0)["ok"], "READY test selection succeeds")
        check(ready_auth.advance_state(7,
            {"request_id": "ready-a", "session_player_id": ready_slot["session_player_id"],
             "reservation_token": ready_slot["reservation_token"],
             "expected_revision": ready_auth.registry_snapshot()[0]["revision"],
             "next_state": "READY"}, 100)["ok"], "READY starts a fresh pending deadline")
        ready_auth.host_expire(60099)
        check(ready_auth.registry_snapshot().size() == 1, "READY survives before deadline")
        ready_auth.host_expire(60100)
        check(ready_auth.registry_snapshot().is_empty(), "abandoned READY seat expires")
        var retry_auth: Variant = auth_script.new()
        var retry_request: Dictionary = {"request_id": "retry-r", "local_slot_id": 0,
            "protocol_version": 1}
        var retry_first: Dictionary = retry_auth.request_slot(8, retry_request, 0)
        check(retry_auth.request_slot(8, retry_request, 59999) == retry_first,
            "reservation replay preserves original token within retry window")
        retry_auth.host_expire(60000)
        check(retry_auth.request_slot(8, retry_request, 60000)["ok"],
            "expired replay entries cannot permanently block requests")
    var device_script: Script = load("res://game/core/input/device_registry.gd") as Script
    check(device_script != null, "M1 local device registry loads")
    if device_script != null:
        var devices: Variant = device_script.new()
        check(devices.bind_device(10, 0)["ok"], "first device claims local slot")
        check(devices.bind_device(11, 1)["ok"], "second device claims separate local slot")
        check(devices.bind_device(10, 2)["error_code"] == "DEVICE_ASSIGNED",
            "assigned device cannot claim a second slot")
        check(devices.bind_device(12, 1)["error_code"] == "SLOT_OCCUPIED",
            "two devices cannot control one slot")
        check(devices.bind_device(12, 4)["error_code"] == "INVALID_ID",
            "out-of-range local slot rejected")
        check(devices.bind_device(-1, 2)["error_code"] == "INVALID_ID",
            "negative device ID rejected")
        check(devices.disconnect_device(10)["ok"] and not devices.device_is_connected(10),
            "disconnect pauses device without releasing ownership")
        check(devices.slot_for_device(10) == 0 and devices.device_for_slot(0) == 10,
            "disconnect retains device and slot identity")
        check(devices.bind_device(12, 0)["error_code"] == "SLOT_OCCUPIED",
            "disconnected device slot cannot be silently stolen")
        check(devices.reconnect_device(10)["ok"] and devices.device_is_connected(10),
            "same device reconnect restores connected state")
        check(devices.unbind_device(10)["ok"] and devices.slot_for_device(10) == -1,
            "explicit unbind frees device ownership")
        check(devices.bind_device(12, 0)["ok"], "released slot is reusable")
        check(devices.assignments().size() == 2,
            "assignment snapshot includes only current devices")
    if "--self-test-failure" in OS.get_cmdline_user_args():
        check(false, "intentional runner failure probe")
    print("RESULT: %d checks, %d failures" % [checks, failures])
    quit(1 if failures else 0)
