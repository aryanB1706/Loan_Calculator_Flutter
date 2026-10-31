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

## Loans API

| Method | Endpoint                     | Auth                | Body                                                                     |
| ------ | ---------------------------- | ------------------- | ------------------------------------------------------------------------ |
| POST   | `/api/loans/calculate`       | No                  | `{ "amount": 100000, "tenureMonths": 12 }`                               |
| POST   | `/api/loans/eligibility`     | Bearer access token | `{ "amount": 100000, "tenureMonths": 12 }`                               |
| POST   | `/api/loans/apply`           | Bearer access token | `{ "amount": 100000, "tenureMonths": 12, "purpose": "Home renovation" }` |
| GET    | `/api/loans?page=1&limit=10` | Bearer access token | none                                                                     |
| GET    | `/api/loans/:id`             | Bearer access token | none                                                                     |

`calculate` is public: it only depends on the amount and tenure, returns no
personal data, and lets a user explore EMIs before creating an account.
`eligibility`, `apply` and the retrieval endpoints are authenticated because
they use the signed-in user's profile or applications.

```bash
curl -X POST http://localhost:5000/api/loans/calculate \
  -H "Content-Type: application/json" \
  -d '{"amount":100000,"tenureMonths":12}'

curl -X POST http://localhost:5000/api/loans/eligibility \
  -H "Authorization: Bearer <accessToken>" \
  -H "Content-Type: application/json" \
  -d '{"amount":100000,"tenureMonths":12}'
```

The calculator responds with:

```json
{
  "emi": 8884.88,
  "totalPayable": 106618.56,
  "totalInterest": 6618.56,
  "interestRate": 12
}
```

The eligibility response always has the same shape. `reasons` is empty only
when `eligible` is `true`:

```json
{
  "eligible": false,
  "maxEligibleAmount": 400000,
  "reasons": [
    "The maximum loan amount you are eligible for is ₹4,00,000, but you requested ₹4,50,000."
  ]
}
```

### Applications

Submitting an application re-runs the eligibility service on the server using
the stored profile. The client cannot skip or override any rule. The saved
application records the server-calculated rate, EMI and total payable.

```bash
# Submit an application
curl -X POST http://localhost:5000/api/loans/apply \
  -H "Authorization: Bearer <accessToken>" \
  -H "Content-Type: application/json" \
  -d '{"amount":100000,"tenureMonths":12,"purpose":"Home renovation"}'

# My applications, newest first
curl "http://localhost:5000/api/loans?page=1&limit=10" \
  -H "Authorization: Bearer <accessToken>"

# One application, including its status history
curl http://localhost:5000/api/loans/<applicationId> \
  -H "Authorization: Bearer <accessToken>"
```

A successful application returns `201` with a readable number such as
`LN-2026-000123`, the quote snapshot, `status: "submitted"` and the first
`statusHistory` entry. The list response includes
`pagination: { page, limit, total, totalPages }`.

**Duplicate active applications:** one user can have only one application in
`submitted` or `under_review`. A second request is rejected with `409` and the
existing application number. This avoids accidental double applications and
duplicate credit checks while an application is still being processed.
`approved`, `rejected` and `disbursed` are terminal for this rule, so a new
application is allowed after the previous one leaves the active states. The
service check gives the readable message; a partial unique index on the Loan
collection also prevents two concurrent requests from both creating an active
application.

## Loan Rules

All numbers and limits live in `src/constants/loanRules.js`, so the calculator,
eligibility check and request validation cannot drift apart.

### Calculator

- **Amount:** ₹10,000 to ₹5,00,000 (whole rupees).
- **Tenure:** 3 to 60 months.
- **Interest rate:** a flat **12% p.a.**, converted to a monthly rate of
  `12 / 12 / 100 = 0.01`. A credit-score-based rate was intentionally not used
  here: the public calculator has no credit profile to read, and one fixed rate
  keeps the estimate deterministic and easy to explain. Eligibility uses the
  same rate, so the quoted EMI and the eligibility decision always agree. If
  credit-band pricing is added later, only this constant changes.
- **EMI:** standard reducing-balance formula

  ```
  EMI = P * r * (1 + r)^n / ((1 + r)^n - 1)
  ```

  where `P` is the principal, `r` is the monthly rate and `n` is the tenure in
  months.

- **Totals:** `totalPayable = EMI * tenureMonths` and
  `totalInterest = totalPayable - amount`, all rounded to 2 decimal places.
  Total payable uses the rounded EMI, so the returned numbers add up exactly.

### Eligibility

The check returns `eligible`, `maxEligibleAmount` and a `reasons` array. Every
failed rule adds one plain-language reason; the app can display the array as-is.

| Rule                    | Requirement                                                            |
| ----------------------- | ---------------------------------------------------------------------- |
| Profile completed       | `profileCompleted` must be `true`.                                     |
| Valid PAN               | PAN must be present and match `ABCDE1234F`.                            |
| Age                     | Between 21 and 60 years inclusive (calculated from `dob`).             |
| Minimum income          | Monthly income of at least ₹15,000.                                    |
| Credit score            | At least 600.                                                          |
| FOIR                    | EMI must be at most 50% of monthly income.                             |
| Maximum eligible amount | `min(10 x monthly income, ₹5,00,000)`; the request cannot exceed this. |

FOIR means Fixed Obligation to Income Ratio: the part of monthly income that
would go towards the EMI. Above 50%, the loan is treated as unaffordable.
`maxEligibleAmount` is a profile-level cap based on income. A specific amount
can still fail the FOIR rule, especially over a short tenure, even when it is
below the cap.

### Applications

Statuses follow the lifecycle `submitted -> under_review -> approved/rejected ->
disbursed`. Applications start as `submitted` with a matching first entry in
`statusHistory`. Application numbers use a yearly atomic counter, formatted as
`LN-<year>-<six-digit sequence>`.

Only one application may be in `submitted` or `under_review` at a time; see the
duplicate rule above.

## Structure

```
src/
  config/       env validation + MongoDB connection
  constants/    HTTP status codes, shared messages and loan rules
  controllers/  request/response handling only
  middlewares/  auth, validation, rate limiting, 404 and global errors
  models/       Mongoose schemas (User, Otp, Loan, Counter)
  routes/       Express routers
  services/     business logic (auth, OTP, EMI, eligibility and applications)
  utils/        AppError, asyncHandler, tokens, phone, date, PAN and OTP helpers
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
