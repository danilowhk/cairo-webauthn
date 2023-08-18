from hashlib import sha256
from ecdsa import SigningKey, NIST256p, util


def get_good_signature(message: bytes, hash=False):
    sk = SigningKey.generate(curve=NIST256p)
    vk = sk.get_verifying_key()

    signature = (
        sk.sign(message, hashfunc=sha256)
        if hash
        else sk.sign(message, hashfunc=my_hash, allow_truncate=False)
    )

    (px, py) = (vk.pubkey.point.x(), vk.pubkey.point.y())
    r, s = util.sigdecode_string(signature, sk.curve.order)

    return (px, py, r, s)


def get_raw_signature(message: bytes):
    sk = SigningKey.generate(curve=NIST256p)
    vk = sk.get_verifying_key()
    sig = sk.sign(message, hashfunc=sha256)
    (px, py) = (vk.pubkey.point.x(), vk.pubkey.point.y())
    return (sig, px, py)


def bytes_as_cairo_array(bytes: bytes, name: str = "msg") -> str:
    declare = [f"let mut {name}: Array<u8> = ArrayTrait::new();"]
    lines = [f"{name}.append({hex(b)});" for b in bytes]
    return "\n".join(declare + lines) + "\n"


# Dummy hash function returning a mock of a digestable object
def my_hash(message):
    return Digestable(message)


class Digestable:
    def __init__(self, val) -> None:
        self.val = val

    def digest(self):
        return self.val
