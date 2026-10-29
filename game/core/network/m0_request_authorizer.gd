extends RefCounted
## Pure M0 boundary. sender_peer_id and now_ms MUST come from trusted host adapters.
## This class is not an RPC endpoint. Do not pass client-declared sender identity.
const Registry = preload("res://game/core/lobby/lobby_registry.gd")
const TokenProvider = preload("res://game/core/identity/reservation_token_provider.gd")
const PROTOCOL_VERSION := 1
const MAX_REQUESTS := 4096

var _registry: RefCounted
var _token_provider: RefCounted
var _responses: Dictionary = {}

func _init(registry: RefCounted = null, token_provider: RefCounted = null) -> void:
    _registry = registry if registry != null else Registry.new()
    _token_provider = token_provider if token_provider != null else TokenProvider.new()

func _fail(code: String) -> Dictionary:
    return {"ok": false, "error_code": code}

func _valid_request(payload: Dictionary, required: Array[String]) -> bool:
    if payload.size() != required.size():
        return false
    for key in required:
        if not payload.has(key):
            return false
    if typeof(payload["request_id"]) != TYPE_STRING:
        return false
    var request_id: String = payload["request_id"]
    if request_id.is_empty() or request_id.length() > 64:
        return false
    return true

func _replay_key(sender_peer_id: int, request_id: String) -> String:
    return "%d:%s" % [sender_peer_id, request_id]

func _invoke(sender_peer_id: int, payload: Dictionary, required: Array[String],
        action: String, now_ms: int) -> Dictionary:
    if sender_peer_id <= 0 or not _valid_request(payload, required):
        return _fail("INVALID_MESSAGE")
    var key := _replay_key(sender_peer_id, payload["request_id"])
    if _responses.has(key):
        var previous: Dictionary = _responses[key]
        if previous["action"] != action or previous["payload"] != payload:
            return _fail("REQUEST_ID_CONFLICT")
        return previous["response"].duplicate(true)
    if _responses.size() >= MAX_REQUESTS:
        return _fail("REQUEST_LIMIT")
    var result: Dictionary
    match action:
        "reserve":
            if typeof(payload["local_slot_id"]) != TYPE_INT or typeof(payload["protocol_version"]) != TYPE_INT:
                return _fail("INVALID_MESSAGE")
            var token: String = _token_provider.generate_token()
            if token.length() != 32:
                return _fail("TOKEN_GENERATION_FAILED")
            result = _registry.reserve(sender_peer_id, payload["local_slot_id"],
                payload["protocol_version"], now_ms, token)
        "select":
            if typeof(payload["session_player_id"]) != TYPE_INT or typeof(payload["reservation_token"]) != TYPE_STRING or typeof(payload["owner_profile_id"]) != TYPE_STRING or typeof(payload["character_id"]) != TYPE_STRING or typeof(payload["save_schema"]) != TYPE_INT or typeof(payload["save_revision"]) != TYPE_INT:
                return _fail("INVALID_MESSAGE")
            if payload["reservation_token"].length() != 32 or payload["owner_profile_id"].length() > 64 or payload["character_id"].length() > 64:
                return _fail("INVALID_MESSAGE")
            result = _registry.select_character(sender_peer_id, payload["session_player_id"],
                payload["reservation_token"], payload["owner_profile_id"], payload["character_id"],
                payload["save_schema"], payload["save_revision"], now_ms)
        "advance":
            if typeof(payload["session_player_id"]) != TYPE_INT or typeof(payload["reservation_token"]) != TYPE_STRING or typeof(payload["expected_revision"]) != TYPE_INT or typeof(payload["next_state"]) != TYPE_STRING:
                return _fail("INVALID_MESSAGE")
            if payload["reservation_token"].length() != 32 or not payload["next_state"] in ["READY", "ACTIVE"]:
                return _fail("INVALID_MESSAGE")
            result = _registry.advance_state(sender_peer_id, payload["session_player_id"],
                payload["reservation_token"], payload["expected_revision"], payload["next_state"], now_ms)
        _:
            return _fail("UNKNOWN_ACTION")
    _responses[key] = {"action": action, "payload": payload.duplicate(true),
        "response": result.duplicate(true)}
    return result.duplicate(true)

func request_slot(sender_peer_id: int, payload: Dictionary, now_ms: int) -> Dictionary:
    return _invoke(sender_peer_id, payload, ["request_id", "local_slot_id", "protocol_version"], "reserve", now_ms)

func select_character(sender_peer_id: int, payload: Dictionary, now_ms: int) -> Dictionary:
    return _invoke(sender_peer_id, payload, ["request_id", "session_player_id", "reservation_token",
        "owner_profile_id", "character_id", "save_schema", "save_revision"], "select", now_ms)

func advance_state(sender_peer_id: int, payload: Dictionary, now_ms: int) -> Dictionary:
    return _invoke(sender_peer_id, payload, ["request_id", "session_player_id", "reservation_token",
        "expected_revision", "next_state"], "advance", now_ms)

func registry_snapshot() -> Array[Dictionary]:
    return _registry.snapshot()

func host_expire(now_ms: int) -> void:
    _registry.expire(now_ms)

func host_disconnect(peer_id: int) -> void:
    _registry.release_peer(peer_id)
    # A disconnected peer's cached responses cannot authorize new actions.
    for key in _responses.keys():
        if key.begins_with("%d:" % peer_id):
            _responses.erase(key)
