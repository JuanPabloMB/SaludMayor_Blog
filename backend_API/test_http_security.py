"""Pruebas sin MySQL para limites HTTP."""
import asyncio
import unittest
from core.http_security import HttpSecurityMiddleware, RateLimiter


async def request(chunks, headers=(), path='/blog', method='POST', middleware=None):
    sent = []
    async def endpoint(scope, receive, send):
        message = await receive()
        await send({'type': 'http.response.start', 'status': 200, 'headers': []})
        await send({'type': 'http.response.body', 'body': message['body']})
    app = middleware or HttpSecurityMiddleware(endpoint, max_body=8)
    queue = iter([{'type': 'http.request', 'body': chunk, 'more_body': i < len(chunks)-1}
                  for i, chunk in enumerate(chunks)])
    async def receive():
        return next(queue)
    async def send(message):
        sent.append(message)
    await app({'type':'http', 'method':method, 'path':path, 'headers':list(headers),
               'client':('127.0.0.1', 1)}, receive, send)
    return sent


class SecurityTests(unittest.TestCase):
    def test_headers_and_replay(self):
        result = asyncio.run(request([b'ab', b'cd']))
        self.assertEqual(result[0]['status'], 200)
        self.assertIn((b'cache-control', b'no-store'), result[0]['headers'])
        self.assertIn((b'x-content-type-options', b'nosniff'), result[0]['headers'])
        self.assertEqual(result[1]['body'], b'abcd')

    def test_declared_limit(self):
        self.assertEqual(asyncio.run(request([b''], [(b'content-length', b'9')]))[0]['status'], 413)

    def test_chunked_limit(self):
        self.assertEqual(asyncio.run(request([b'12345', b'6789']))[0]['status'], 413)

    def test_invalid_length(self):
        self.assertEqual(asyncio.run(request([b''], [(b'content-length', b'-1')]))[0]['status'], 400)

    def test_rate_limit(self):
        now = [0]
        limiter = RateLimiter(limit=2, clock=lambda: now[0])
        self.assertTrue(limiter.allow('ip'))
        self.assertTrue(limiter.allow('ip'))
        self.assertFalse(limiter.allow('ip'))
        self.assertTrue(limiter.allow('other'))
        now[0] = 60
        self.assertTrue(limiter.allow('ip'))

    def test_capacity(self):
        limiter = RateLimiter(capacity=1)
        self.assertTrue(limiter.allow('a'))
        self.assertFalse(limiter.allow('b'))


if __name__ == '__main__':
    unittest.main()
