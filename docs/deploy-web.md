# Deploy the Flutter app as a website

The same Flutter code that makes the Android app also builds a website. Hosting
that website gives reviewers a link they can open in any browser, with nothing to
install. It talks to the deployed backend (`https://credit-sea-api.onrender.com`)
exactly like the phone app does.

On a laptop the app appears as a centred phone-width column, so it looks like the
mobile design instead of stretching across the screen.

## 1. Build

```bash
cd mobile
flutter build web --release
```

The site is in `mobile/build/web` (about 40 MB, most of it the Flutter rendering
engine). The first build takes a few minutes. The build is git-ignored; you
rebuild whenever the app changes.

The app address is baked in at build time (`mobile/lib/core/config/app_config.dart`).
To point the site at another backend:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://<your-service>.onrender.com
```

## 2. Host it

Any static host works. The app uses hash URLs (`/#/home`), so no redirect rules
are needed.

### Netlify (easiest: drag and drop, no CLI)

1. Open <https://app.netlify.com/drop> and sign in (a free account is enough).
2. Drag the **`mobile/build/web` folder** onto the page.
3. Netlify gives you a link like `https://random-name-123.netlify.app`. Rename it
   under **Site configuration -> Change site name** (for example
   `credit-sea-app`, giving `https://credit-sea-app.netlify.app`).

To update later, open the site's **Deploys** tab and drag the new `build/web`
folder in again.

### Vercel

Vercel has no drag-and-drop page, so it uses the CLI. Deploy the build folder
itself, from inside it, so that `index.html` is at the top:

```bash
cd mobile/build/web
npx vercel login          # once; opens the browser
npx vercel --prod
```

Answer the prompts: set up and deploy `y`, link to an existing project `n`,
project name `credit-sea-app`, code directory `./`, and keep the detected
settings. It prints a production URL such as `https://credit-sea-app.vercel.app`.

Vercel's own build servers do not have the Flutter SDK, so connecting the Git
repository will not work; always build locally and deploy `build/web`.

To update: `flutter build web --release` again, then repeat the deploy from
`mobile/build/web`. The build recreates that folder and can delete the
`.vercel` link inside it, so when asked "Link to existing project?" answer `y`
and pick the same project, or Vercel will create a second one.

### GitHub Pages

The site lives under `/<repo>/`, so build with a matching base path:

```bash
flutter build web --release --base-href /<repo-name>/
```

Then publish the contents of `build/web` to the `gh-pages` branch (or point Pages
at a `docs`-style folder).

### Firebase Hosting

`firebase init hosting` (public directory `build/web`, single-page app: yes), then
`firebase deploy`. This is the one option that needs the Firebase CLI.

## 3. Check it

1. Open the link. The splash screen shows for about a second and a half, then the
   login screen.
2. Enter a mobile number, request the OTP, and enter `123456` (the screen shows
   the demo hint).
3. Walk through the profile and a loan application.

Things to know:

- **First load after a pause is slow.** The backend runs on Render's free plan and
  sleeps when idle. Open `https://credit-sea-api.onrender.com/api/health` in a tab
  first, wait for it to answer, then use the app.
- **Hard refresh after an update.** The site caches itself. After deploying a new
  build, press Ctrl+Shift+R (Cmd+Shift+R on a Mac) once to load it.
- **HTTPS is required.** Both Netlify and Vercel serve HTTPS, which the app's
  secure token storage needs in a browser.
- **Session is per browser.** Tokens are kept in that browser's storage, so
  clearing site data logs the user out.
- **CORS** is already open on the backend (`CORS_ORIGIN=*`). To lock it down,
  set `CORS_ORIGIN` on Render to your site's address, for example
  `https://credit-sea-app.netlify.app`.

## Troubleshooting

| Symptom                                         | Likely cause and fix                                                                         |
| ----------------------------------------------- | -------------------------------------------------------------------------------------------- |
| White screen, nothing loads                     | Wrong folder uploaded. Upload `build/web` itself (it must contain `index.html` at the top).   |
| White screen on GitHub Pages                    | Built without `--base-href /<repo-name>/`.                                                   |
| Old version still showing                       | Hard refresh (Ctrl+Shift+R), or open in a private window.                                    |
| "No internet connection" on the first action    | The free backend was asleep. Open `/api/health`, wait, then tap **Try again**.               |
| Requests blocked in the browser console (CORS)  | `CORS_ORIGIN` on Render is set to a different address than the site's.                       |
| Logged out on every visit                       | The browser blocks site storage (private mode or strict settings).                           |
