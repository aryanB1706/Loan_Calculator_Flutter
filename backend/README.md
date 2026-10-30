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
npm test       # Jest + Supertest
npm run lint   # ESLint
```

The API listens on `http://localhost:5000` by default.

Health check:

```bash
curl http://localhost:5000/api/health
```

```json
{
  "success": true,
  "message": "Service is healthy",
  "data": { "status": "ok", "uptime": 3, "timestamp": "2026-10-31T00:00:00.000Z" }
}
```

## Structure

```
src/
  config/       env validation + MongoDB connection
  constants/    HTTP status codes and shared messages
  controllers/  request/response handling only
  middlewares/  rate limiting, 404 and global error handling
  models/       Mongoose schemas (added in later steps)
  routes/       Express routers
  services/     business logic (added in later steps)
  utils/        AppError, asyncHandler, response helpers
  validators/   request validation schemas (added in later steps)
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
