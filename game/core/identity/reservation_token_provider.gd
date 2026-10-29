extends RefCounted
## Host-only token generation. Tests may inject deterministic tokens into the pure registry.
## Production callers must generate tokens here, never accept tokens from RPC payloads.
const TOKEN_BYTES := 16

func generate_token() -> String:
    var bytes: PackedByteArray = Crypto.new().generate_random_bytes(TOKEN_BYTES)
    if bytes.size() != TOKEN_BYTES:
        push_error("Secure reservation token generation failed")
        return ""
    return bytes.hex_encode()
