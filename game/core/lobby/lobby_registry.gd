extends RefCounted
## Pure, host-owned M0 lobby state. No transport, device routing or persistence.
const CAPACITY := 4
const PROTOCOL_VERSION := 1
const SAVE_SCHEMA := 1
const TTL_MS := 60000

var _slots: Dictionary = {}
var _pairs: Dictionary = {}
var _characters: Dictionary = {}
var _next_id: int = 1
var _revision: int = 0

func _result(ok: bool, code: String, extra: Dictionary = {}) -> Dictionary:
    var result := {"ok": ok, "error_code": code, "revision": _revision}
    result.merge(extra)
    return result

func _token_hash(token: String) -> String:
    return token.sha256_text()

func _pair(peer_id: int, local_slot_id: int) -> String:
    return "%d:%d" % [peer_id, local_slot_id]

func reserve(peer_id: int, local_slot_id: int, protocol_version: int, now_ms: int, token: String) -> Dictionary:
    if peer_id <= 0 or local_slot_id < 0 or local_slot_id > 3:
        return _result(false, "INVALID_ID")
    if protocol_version != PROTOCOL_VERSION:
        return _result(false, "PROTOCOL_MISMATCH")
    if token.is_empty():
        return _result(false, "INVALID_TOKEN")
    var key := _pair(peer_id, local_slot_id)
    if _pairs.has(key):
        return _result(false, "SLOT_OCCUPIED")
    if _slots.size() >= CAPACITY:
        return _result(false, "LOBBY_FULL")
    var digest := _token_hash(token)
    for existing in _slots.values():
        if existing["token_hash"] == digest:
            return _result(false, "TOKEN_REUSED")
    var id := _next_id
    _next_id += 1
    _revision += 1
    _slots[id] = {"peer_id": peer_id, "local_slot_id": local_slot_id, "token_hash": digest,
        "expires_at_ms": now_ms + TTL_MS, "state": "RESERVED", "character_id": "",
        "owner_profile_id": "", "revision": _revision}
    _pairs[key] = id
    return _result(true, "OK", {"session_player_id": id, "reservation_token": token})

func select_character(sender_peer_id: int, id: int, token: String, owner_profile_id: String,
        character_id: String, save_schema: int, save_revision: int, now_ms: int) -> Dictionary:
    if not _slots.has(id):
        return _result(false, "NOT_FOUND")
    var slot: Dictionary = _slots[id]
    if slot["peer_id"] != sender_peer_id or slot["token_hash"] != _token_hash(token):
        return _result(false, "UNAUTHORIZED")
    if slot["state"] != "RESERVED":
        return _result(false, "INVALID_STATE")
    if now_ms >= slot["expires_at_ms"]:
        _release(id)
        return _result(false, "EXPIRED")
    if owner_profile_id.is_empty() or character_id.is_empty() or save_revision < 0:
        return _result(false, "INVALID_CHARACTER")
    if save_schema != SAVE_SCHEMA:
        return _result(false, "SAVE_SCHEMA_MISMATCH")
    if _characters.has(character_id):
        return _result(false, "CHARACTER_OCCUPIED")
    _revision += 1
    slot["owner_profile_id"] = owner_profile_id
    slot["character_id"] = character_id
    slot["state"] = "CHARACTER_SELECTED"
    slot["expires_at_ms"] = now_ms + TTL_MS
    slot["revision"] = _revision
    _characters[character_id] = id
    return _result(true, "OK")

func advance_state(sender_peer_id: int, id: int, token: String, expected_revision: int,
        next_state: String, now_ms: int) -> Dictionary:
    if not _slots.has(id):
        return _result(false, "NOT_FOUND")
    var slot: Dictionary = _slots[id]
    if slot["peer_id"] != sender_peer_id or slot["token_hash"] != _token_hash(token):
        return _result(false, "UNAUTHORIZED")
    if slot["revision"] != expected_revision:
        return _result(false, "STALE_REVISION")
    if slot["state"] == "CHARACTER_SELECTED" and next_state == "READY":
        if now_ms >= slot["expires_at_ms"]:
            _release(id)
            return _result(false, "EXPIRED")
    elif slot["state"] == "READY" and next_state == "ACTIVE":
        if now_ms >= slot["expires_at_ms"]:
            _release(id)
            return _result(false, "EXPIRED")
    else:
        return _result(false, "INVALID_TRANSITION")
    _revision += 1
    if next_state == "READY":
        slot["expires_at_ms"] = now_ms + TTL_MS
    slot["state"] = next_state
    slot["revision"] = _revision
    return _result(true, "OK")

func slot_revision(id: int) -> int:
    if not _slots.has(id):
        return -1
    return _slots[id]["revision"]

func release(sender_peer_id: int, id: int, token: String) -> Dictionary:
    if not _slots.has(id):
        return _result(true, "OK")
    var slot: Dictionary = _slots[id]
    if slot["peer_id"] != sender_peer_id or slot["token_hash"] != _token_hash(token):
        return _result(true, "OK")
    _release(id)
    return _result(true, "OK")

func release_peer(peer_id: int) -> void:
    for id in _slots.keys():
        if _slots[id]["peer_id"] == peer_id:
            _release(id)

func refresh_pending(sender_peer_id: int, id: int, token: String, now_ms: int) -> Dictionary:
    if not _slots.has(id):
        return _result(false, "NOT_FOUND")
    var slot: Dictionary = _slots[id]
    if slot["peer_id"] != sender_peer_id or slot["token_hash"] != _token_hash(token):
        return _result(false, "UNAUTHORIZED")
    if slot["state"] != "CHARACTER_SELECTED":
        return _result(false, "INVALID_STATE")
    if now_ms >= slot["expires_at_ms"]:
        _release(id)
        return _result(false, "EXPIRED")
    # Only trusted, validated join progress may invoke this method.
    slot["expires_at_ms"] = now_ms + TTL_MS
    _revision += 1
    slot["revision"] = _revision
    return _result(true, "OK")

func expire(now_ms: int) -> void:
    for id in _slots.keys():
        if _slots[id]["state"] in ["RESERVED", "CHARACTER_SELECTED", "READY"] and now_ms >= _slots[id]["expires_at_ms"]:
            _release(id)

func _release(id: int) -> void:
    var slot: Dictionary = _slots[id]
    _pairs.erase(_pair(slot["peer_id"], slot["local_slot_id"]))
    if not slot["character_id"].is_empty():
        _characters.erase(slot["character_id"])
    _slots.erase(id)
    _revision += 1

func snapshot() -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    for id in _slots.keys():
        var slot: Dictionary = _slots[id]
        out.append({"session_player_id": id, "peer_id": slot["peer_id"],
            "local_slot_id": slot["local_slot_id"], "state": slot["state"],
            "revision": slot["revision"]})
    return out
