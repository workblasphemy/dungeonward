extends RefCounted
## Pure local Start×2 gesture. Never owns a host reservation or character identity.
## Caller must release any approved host reservation when INTENT_RELEASE_RESERVATION is returned.
const STATE_UNASSIGNED := "UNASSIGNED"
const STATE_CONFIRMING := "CONFIRMING"
const STATE_RESERVING := "RESERVING"
const STATE_SELECTING := "SELECTING"
const STATE_ASSIGNED := "ASSIGNED"
const INTENT_NONE := "NONE"
const INTENT_REQUEST_RESERVATION := "REQUEST_RESERVATION"
const INTENT_RELEASE_RESERVATION := "RELEASE_RESERVATION"
const INTENT_OPEN_MENU := "OPEN_MENU"

var _states: Dictionary = {}
var _deadlines: Dictionary = {}

func _state(device_id: int) -> String:
    return _states.get(device_id, STATE_UNASSIGNED)

func _result(ok: bool, code: String, state: String, intent: String = INTENT_NONE) -> Dictionary:
    return {"ok": ok, "error_code": code, "state": state, "intent": intent}

func get_device_state(device_id: int) -> String:
    return _state(device_id) if device_id >= 0 else STATE_UNASSIGNED

func start_pressed(device_id: int, now_ms: int, confirmation_window_ms: int, assigned: bool = false) -> Dictionary:
    if device_id < 0:
        return _result(false, "INVALID_ID", STATE_UNASSIGNED)
    var state := _state(device_id)
    if now_ms < 0:
        return _result(false, "INVALID_TIMESTAMP", state)
    if confirmation_window_ms <= 0:
        return _result(false, "INVALID_WINDOW", state)
    # The caller's registry observation cannot bypass host approval.
    if assigned and state != STATE_ASSIGNED:
        return _result(false, "ASSIGNMENT_MISMATCH", state)
    if state == STATE_ASSIGNED:
        if not assigned:
            return _result(false, "ASSIGNMENT_MISMATCH", state)
        return _result(true, "OK", state, INTENT_OPEN_MENU)
    match state:
        STATE_UNASSIGNED:
            _states[device_id] = STATE_CONFIRMING
            _deadlines[device_id] = now_ms + confirmation_window_ms
            return _result(true, "OK", STATE_CONFIRMING)
        STATE_CONFIRMING:
            if now_ms > int(_deadlines.get(device_id, -1)):
                _deadlines[device_id] = now_ms + confirmation_window_ms
                return _result(true, "OK", STATE_CONFIRMING)
            _deadlines.erase(device_id)
            _states[device_id] = STATE_RESERVING
            return _result(true, "OK", STATE_RESERVING, INTENT_REQUEST_RESERVATION)
        STATE_RESERVING, STATE_SELECTING:
            return _result(true, "OK", state)
    return _result(false, "INVALID_STATE", state)

func reservation_result(device_id: int, success: bool, error_code: String = "") -> Dictionary:
    if device_id < 0:
        return _result(false, "INVALID_ID", STATE_UNASSIGNED)
    if _state(device_id) != STATE_RESERVING:
        return _result(false, "INVALID_STATE", _state(device_id))
    if success:
        _states[device_id] = STATE_SELECTING
        return _result(true, "OK", STATE_SELECTING)
    _states.erase(device_id)
    return _result(false, error_code if not error_code.is_empty() else "RESERVATION_FAILED", STATE_UNASSIGNED)

func mark_assigned(device_id: int, binding_confirmed: bool = false) -> Dictionary:
    if device_id < 0:
        return _result(false, "INVALID_ID", STATE_UNASSIGNED)
    if _state(device_id) != STATE_SELECTING or not binding_confirmed:
        return _result(false, "ASSIGNMENT_NOT_APPROVED", _state(device_id))
    _states[device_id] = STATE_ASSIGNED
    return _result(true, "OK", STATE_ASSIGNED)

func cancel(device_id: int) -> Dictionary:
    if device_id < 0:
        return _result(false, "INVALID_ID", STATE_UNASSIGNED)
    var state := _state(device_id)
    if state == STATE_ASSIGNED:
        return _result(false, "CANNOT_CANCEL_ASSIGNED", state)
    _states.erase(device_id)
    _deadlines.erase(device_id)
    # RESERVING may race with an in-flight host approval: adapter must reconcile
    # late success and release it. SELECTING already owns a reservation.
    if state == STATE_RESERVING or state == STATE_SELECTING:
        return _result(true, "OK", STATE_UNASSIGNED, INTENT_RELEASE_RESERVATION)
    return _result(true, "OK", STATE_UNASSIGNED)

func disconnect_device(device_id: int) -> Dictionary:
    if device_id < 0:
        return _result(false, "INVALID_ID", STATE_UNASSIGNED)
    if _state(device_id) == STATE_ASSIGNED:
        # DeviceRegistry retains ownership while disconnected.
        return _result(true, "OK", STATE_ASSIGNED)
    return cancel(device_id)

func unbind_device(device_id: int, unbind_confirmed: bool = false) -> Dictionary:
    if device_id < 0:
        return _result(false, "INVALID_ID", STATE_UNASSIGNED)
    if _state(device_id) == STATE_ASSIGNED and not unbind_confirmed:
        return _result(false, "UNBIND_NOT_CONFIRMED", STATE_ASSIGNED)
    _states.erase(device_id)
    _deadlines.erase(device_id)
    return _result(true, "OK", STATE_UNASSIGNED)

func expire(now_ms: int) -> Dictionary:
    if now_ms < 0:
        return {"ok": false, "error_code": "INVALID_TIMESTAMP", "expired_devices": []}
    var expired: Array[int] = []
    for device_id in _deadlines.keys():
        if _state(device_id) == STATE_CONFIRMING and now_ms > int(_deadlines[device_id]):
            _states.erase(device_id)
            _deadlines.erase(device_id)
            expired.append(device_id)
    expired.sort()
    return {"ok": true, "error_code": "OK", "expired_devices": expired}
