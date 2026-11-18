"""Hash de contrasenas y JWT de SaludMayor."""
from datetime import datetime, timezone, timedelta
from uuid import uuid4, UUID
import jwt
from pwdlib import PasswordHash
from core.config import settings

password_hash = PasswordHash.recommended()
DUMMY_HASH = password_hash.hash(str(uuid4()))

def utc_now():
    return datetime.now(timezone.utc).replace(tzinfo=None, microsecond=0)

def hash_password(password: str) -> str:
    return password_hash.hash(password)

def verify_password(password: str, hashed: str) -> bool:
    try:
        return password_hash.verify(password, hashed)
    except (ValueError, TypeError):
        return False

def create_token(user_id: int, transport: str):
    now = datetime.now(timezone.utc).replace(microsecond=0)
    exp = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    jti = str(uuid4())
    token = jwt.encode({'sub': str(user_id), 'jti': jti, 'iat': now, 'exp': exp,
                        'iss': 'saludmayor', 'aud': 'saludmayor-api', 'transport': transport},
                       settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return token, jti, now.replace(tzinfo=None), exp.replace(tzinfo=None)

def decode_token(token: str, transport: str):
    claims = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM],
                        issuer='saludmayor', audience='saludmayor-api',
                        options={'require': ['sub','jti','iat','exp','iss','aud','transport']})
    if claims['transport'] != transport or not claims['sub'].isdigit() or not 1 <= int(claims['sub']) <= 4294967295:
        raise jwt.InvalidTokenError('Claims invalidos')
    if str(UUID(claims['jti'])) != claims['jti']:
        raise jwt.InvalidTokenError('JTI invalido')
    return claims
