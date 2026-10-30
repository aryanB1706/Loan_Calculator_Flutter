# Loan Calculator — Backend

Node.js + Express + MongoDB API for the Loan Application mobile app.

## Requirements

- Node.js 18+
- MongoDB running locally (or a MongoDB Atlas URI)

## Setup

```bash
cd backend
npm install
cp .env.example .env
# edit .env and set a real MONGO_URI plus long random JWT secrets
```

## Run

```bash
npm run dev    # development (nodemon)
npm start      # production
npm test       # Jest + Supertest (requires MongoDB running)
npm run lint   # ESLint
```

The API listens on `http://localhost:5000` by default.

## Auth API

| Method | Endpoint              | Auth | Body                          |
| ------ | --------------------- | ---- | ----------------------------- |
| POST   | `/api/auth/send-otp`  | No   | `{ "phone": "9876543210" }`   |
| POST   | `/api/auth/verify-otp`| No   | `{ "phone": "...", "otp": "123456" }` |
| POST   | `/api/auth/refresh`   | No   | `{ "refreshToken": "..." }`   |
| POST   | `/api/auth/logout`    | Bearer access token | none          |

`send-otp` accepts 10 digit Indian numbers starting with 6-9, with an optional `+91`.
OTP rules: 5 minute expiry, 30 second resend cooldown, 3 wrong attempts max.
The same hashing, expiry, attempt limit and rate limiting apply in every mode.

### OTP modes

`OTP_MODE` selects how OTPs are delivered:

- `demo`: the OTP is always `123456` and no SMS is sent. Intended for local app
  testing. Rejected at startup when `NODE_ENV=production`.
- `console`: a random OTP is generated and printed in the server logs only.
  The API never returns the OTP.
- `sms`: a random OTP is sent through the configured SMS provider
  (`OTP_SMS_PROVIDER=fast2sms` or `msg91`) using the `OtpSender` interface.

In production use `OTP_MODE=sms`. The SMS senders are placeholders: add provider
credentials to `.env` and implement `src/services/otp/smsOtpSender.js`. The auth
service does not change because every sender follows the `OtpSender` contract.

### Try it with curl

```bash
# 1. Send OTP (OTP_MODE=demo always uses 123456)
curl -X POST http://localhost:5000/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone":"9876543210"}'

# 2. Verify OTP -> accessToken + refreshToken
curl -X POST http://localhost:5000/api/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"phone":"9876543210","otp":"123456"}'

# 3. Refresh (rotates both tokens)
curl -X POST http://localhost:5000/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken":"<refreshToken>"}'

# 4. Logout (revokes the refresh token)
curl -X POST http://localhost:5000/api/auth/logout \
  -H "Authorization: Bearer <accessToken>"
```

## Users API

Both endpoints require `Authorization: Bearer <accessToken>`.

| Method | Endpoint         | Body |
| ------ | ---------------- | ---- |
| GET    | `/api/users/me`  | none |
| PUT    | `/api/users/me`  | any subset of profile fields |

Profile fields: `fullName`, `dob` (ISO date), `gender` (`male|female|other`),
`pan` (format `ABCDE1234F`, uppercased automatically), `email`, `monthlyIncome`
(> 0), `employmentType` (`salaried|self-employed`), `city`.

`profileCompleted` becomes `true` once every field above is present. PAN must be
unique. The response never includes `refreshTokenHash` or `fcmTokens`.

```bash
curl http://localhost:5000/api/users/me \
  -H "Authorization: Bearer <accessToken>"

curl -X PUT http://localhost:5000/api/users/me \
  -H "Authorization: Bearer <accessToken>" \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "Aryan Kumar",
    "dob": "2000-01-15",
    "gender": "male",
    "pan": "ABCDE1234F",
    "email": "aryan@example.com",
    "monthlyIncome": 50000,
    "employmentType": "salaried",
    "city": "Delhi"
  }'
```

## Structure

```
src/
  config/       env validation + MongoDB connection
  constants/    HTTP status codes and shared messages
  controllers/  request/response handling only
  middlewares/  auth, validation, rate limiting, 404 and global errors
  models/       Mongoose schemas (User, Otp)
  routes/       Express routers
  services/     business logic (auth + pluggable OTP senders)
  utils/        AppError, asyncHandler, tokens, phone and OTP helpers
  validators/   Joi request schemas
  app.js        Express app
  server.js     starts server + DB connection
```

## Response format

Success:

```json
{ "success": true, "message": "...", "data": {} }
```

Error:

```json
{ "success": false, "message": "...", "errors": [] }
```
