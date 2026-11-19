"""Limites HTTP y proteccion basica de autenticacion (por proceso)."""
from collections import OrderedDict, deque
from threading import Lock
from time import monotonic

from starlette.responses import JSONResponse


class RateLimiter:
    def __init__(self, limit=20, window=60, capacity=4096, clock=monotonic):
        self.limit = limit
        self.window = window
        self.capacity = capacity
        self.clock = clock
        self.entries = OrderedDict()
        self.lock = Lock()

    def allow(self, key):
        with self.lock:
            now = self.clock()
            # Remove expired buckets before allocating; never evict live limits.
            while self.entries:
                first = next(iter(self.entries))
                if self.entries[first][-1] > now - self.window:
                    break
                self.entries.popitem(last=False)
            times = self.entries.get(key)
            if times is None:
                if len(self.entries) >= self.capacity:
                    return False
                times = self.entries[key] = deque()
            while times and times[0] <= now - self.window:
                times.popleft()
            if len(times) >= self.limit:
                return False
            times.append(now)
            self.entries.move_to_end(key)
            return True


class HttpSecurityMiddleware:
    """Reject oversized bodies before parsing; disable caching of API data."""
    def __init__(self, app, max_body=6 * 1024 * 1024, auth_limit=20):
        self.app = app
        self.max_body = max_body
        self.limiter = RateLimiter(limit=auth_limit)

    async def __call__(self, scope, receive, send):
        if scope['type'] != 'http':
            return await self.app(scope, receive, send)

        async def secure_send(message):
            if message['type'] == 'http.response.start':
                headers = [(k, v) for k, v in message.get('headers', [])
                           if k.lower() not in {b'cache-control', b'x-content-type-options', b'x-frame-options', b'referrer-policy'}]
                headers.extend([(b'cache-control', b'no-store'),
                                (b'x-content-type-options', b'nosniff'),
                                (b'x-frame-options', b'DENY'),
                                (b'referrer-policy', b'no-referrer')])
                message = {**message, 'headers': headers}
            await send(message)

        async def reject(status, detail, headers=None):
            await JSONResponse({'detail': detail}, status_code=status, headers=headers)(scope, receive, secure_send)

        method = scope['method']
        path = scope['path'].rstrip('/')
        if method == 'POST' and path in {'/auth/login', '/auth/token', '/usuarios/registro', '/auth/recuperar', '/usuarios/me/recuperacion'}:
            client = scope.get('client')
            ip = client[0] if client else 'unknown'
            if not self.limiter.allow(ip):
                return await reject(429, 'Demasiadas solicitudes. Intente en un minuto', {'Retry-After': '60'})
        lengths = [v for k, v in scope.get('headers', []) if k.lower() == b'content-length']
        if lengths:
            if len(lengths) != 1 or not lengths[0].isdigit() or len(lengths[0]) > 20:
                return await reject(400, 'Longitud de solicitud invalida')
            if int(lengths[0]) > self.max_body:
                return await reject(413, 'Solicitud demasiado grande')
        # Count actual bytes as well, including chunked requests. Replay only bounded data.
        body = bytearray()
        while True:
            message = await receive()
            if message['type'] == 'http.disconnect':
                return
            chunk = message.get('body', b'')
            if len(body) + len(chunk) > self.max_body:
                return await reject(413, 'Solicitud demasiado grande')
            body.extend(chunk)
            if not message.get('more_body', False):
                break
        delivered = False

        async def replay():
            nonlocal delivered
            if delivered:
                return await receive()
            delivered = True
            return {'type': 'http.request', 'body': bytes(body), 'more_body': False}

        await self.app(scope, replay, secure_send)
