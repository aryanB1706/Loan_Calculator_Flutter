# Design decisions

Why the project is built the way it is. Use this when you need to explain or
defend the code in a review or walkthrough. Each decision points at a file you
can open.

1. **Strict layering.** Backend: route -> controller -> service -> model.
   Mobile: repository -> controller -> view. Rules live in one layer, so a
   change (say, a new eligibility rule) touches one file and is testable without
   HTTP or UI. *See* `backend/src/services/eligibility.service.js`.

2. **Eligibility is decided on the server.** The app shows the result but can't
   change it. `apply` re-runs the same check against the stored profile, so a
   modified client or a stale screen can't get a loan through. The server
   returns readable `reasons`, so the app doesn't need to know the rules.

3. **Tokens: short access + rotating refresh.** The access token lives 15
   minutes; the refresh token lives 7 days, is stored hashed on the user, and is
   replaced on every refresh, so a stolen old one stops working. In the app a
   single shared refresh is in flight at a time and the failed request is
   replayed once. *See* `mobile/lib/core/network/api_client.dart`.

4. **Loan status is a state machine.** One map in `loanWorkflow.service.js`
   lists the only legal moves. Admin API, simulator and auto-decision all go
   through the same function, so an illegal jump (e.g. `submitted ->
   disbursed`) is a `409` everywhere, and every move is recorded in
   `statusHistory`, which is what the timeline renders.

5. **Event-driven side effects.** A status change emits `loan.status.changed`;
   the workflow doesn't know who listens. Today nothing subscribes because push
   notifications aren't built; a notifier can be added as a listener without
   editing the workflow. *See* `backend/src/events/loanEvents.js`.

6. **OTP delivery behind an interface.** `auth.service` calls an `OtpSender`.
   `demo`, `console` and `sms` are interchangeable via `OTP_MODE`. Hashing,
   expiry, attempt limits and rate limiting are identical in every mode.
   `demo` is refused when `NODE_ENV=production`.

7. **Rules are constants, not scattered numbers.** Loan limits, the 12% rate,
   eligibility thresholds, credit-score changes and bands each live in one
   constants file, so the calculator, eligibility and request validation can't
   disagree, and the rules are easy to audit. *See*
   `backend/src/constants/`.

8. **GetX controllers own screen state.** Each screen has a controller (state
   and actions), a binding (builds its dependencies) and a view (just
   renders). Views only read observables, controllers never import widgets, and
   controllers are tested with fake repositories.
