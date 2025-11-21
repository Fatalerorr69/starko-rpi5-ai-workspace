from flask import request
import time

class SecurityMiddleware:
    def __init__(self, app):
        self.app = app
        
    def __call__(self, environ, start_response):
        # Rate limiting
        client_ip = environ.get('REMOTE_ADDR')
        if self.is_rate_limited(client_ip):
            return self.rate_limit_response(start_response)
        
        # Security headers
        def custom_start_response(status, headers, exc_info=None):
            # Přidat bezpečnostní hlavičky
            security_headers = [
                ('X-Content-Type-Options', 'nosniff'),
                ('X-Frame-Options', 'DENY'),
                ('X-XSS-Protection', '1; mode=block'),
                ('Strict-Transport-Security', 'max-age=31536000; includeSubDomains'),
            ]
            headers.extend(security_headers)
            return start_response(status, headers, exc_info)
        
        return self.app(environ, custom_start_response)
    
    def is_rate_limited(self, ip):
        # Jednoduchý rate limiting - v produkci použijte Redis
        return False
    
    def rate_limit_response(self, start_response):
        start_response('429 Too Many Requests', [('Content-Type', 'text/plain')])
        return [b'Rate limit exceeded']