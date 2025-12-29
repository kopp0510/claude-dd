# 認證模式範例

## JWT 安全實作

```javascript
const jwt = require('jsonwebtoken');

class SecureJWT {
  constructor() {
    this.accessTokenSecret = process.env.JWT_ACCESS_SECRET;
    this.refreshTokenSecret = process.env.JWT_REFRESH_SECRET;
    this.accessTokenExpiry = '15m';
    this.refreshTokenExpiry = '7d';
  }

  generateTokenPair(user) {
    const payload = {
      userId: user.id,
      email: user.email,
      roles: user.roles,
      sessionId: crypto.randomUUID()
    };

    const accessToken = jwt.sign(payload, this.accessTokenSecret, {
      expiresIn: this.accessTokenExpiry,
      issuer: 'my-app',
      audience: 'my-app-users',
      algorithm: 'HS256'
    });

    const refreshToken = jwt.sign(
      { userId: user.id, sessionId: payload.sessionId },
      this.refreshTokenSecret,
      { expiresIn: this.refreshTokenExpiry }
    );

    return { accessToken, refreshToken };
  }

  verifyAccessToken(token) {
    return jwt.verify(token, this.accessTokenSecret, {
      issuer: 'my-app',
      audience: 'my-app-users'
    });
  }
}
```

## OAuth2 with PKCE

```javascript
class OAuth2Client {
  generatePKCE() {
    const codeVerifier = crypto.randomBytes(32).toString('base64url');
    const codeChallenge = crypto
      .createHash('sha256')
      .update(codeVerifier)
      .digest('base64url');

    return { codeVerifier, codeChallenge };
  }

  getAuthorizationUrl(state, scopes = ['openid', 'profile', 'email']) {
    const { codeVerifier, codeChallenge } = this.generatePKCE();
    this.storeCodeVerifier(state, codeVerifier);

    const params = new URLSearchParams({
      response_type: 'code',
      client_id: this.clientId,
      redirect_uri: this.redirectUri,
      scope: scopes.join(' '),
      state: state,
      code_challenge: codeChallenge,
      code_challenge_method: 'S256'
    });

    return `${this.authEndpoint}?${params.toString()}`;
  }
}
```

## 安全 Headers

```javascript
function securityHeaders(req, res, next) {
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Permissions-Policy', 'camera=(), microphone=()');

  if (req.secure) {
    res.setHeader('Strict-Transport-Security',
      'max-age=31536000; includeSubDomains; preload');
  }

  // Content Security Policy
  const csp = [
    "default-src 'self'",
    "script-src 'self' https://trusted-cdn.com",
    "style-src 'self' 'unsafe-inline'",
    "frame-ancestors 'none'"
  ].join('; ');

  res.setHeader('Content-Security-Policy', csp);
  next();
}
```

## Rate Limiting

```javascript
const rateLimit = require('express-rate-limit');

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 分鐘
  max: 5, // 最多 5 次嘗試
  message: { error: 'Too many login attempts, please try again later' },
  standardHeaders: true,
  legacyHeaders: false,
});

app.post('/login', loginLimiter, loginHandler);
```
