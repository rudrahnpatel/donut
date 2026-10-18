# Setting up Google sync

Donut talks to Google with **your own** OAuth clients, so nothing goes through a third
party. This takes about 15 minutes, once.

## 1. Create a Google Cloud project

1. Open <https://console.cloud.google.com/> and create a project (e.g. "Donut").
2. **APIs & Services → Library**: enable **Google Drive API** and **Google Calendar API**.

## 2. OAuth consent screen

1. **APIs & Services → OAuth consent screen** (Google Auth Platform → Branding/Audience).
2. User type **External**, app name "Donut", your email as support and developer contact.
3. **Data access → Add scopes**. Add these (use "Manually add scopes" if one isn't listed):
   - `https://www.googleapis.com/auth/drive.appdata`: the hidden app folder (device sync)
   - `https://www.googleapis.com/auth/calendar.app.created`: create and manage only the
     "Donut" calendar
   - `https://www.googleapis.com/auth/calendar.calendarlist.readonly`: list your calendars
   - `https://www.googleapis.com/auth/calendar.events.freebusy`: busy times only (ghost arcs)
   - `email`: show which account is signed in (desktop)
4. **Audience → Publish app** ("In production"). You do **not** need verification for
   personal use. While an app is in *Testing*, Google expires its refresh tokens after
   7 days, which would sign the desktop app out every week. You'll see an "unverified app"
   warning when signing in; choose *Advanced → Go to Donut*.

## 3. OAuth clients

**APIs & Services → Credentials → Create credentials → OAuth client ID**, three times:

| Type | Settings | Used for |
|---|---|---|
| **Android** | Package name `dev.rudra.donut`; SHA-1 from the command below | Lets the Android app sign in |
| **Web application** | No redirect URIs needed | Its client id is the Android `serverClientId` |
| **Desktop app** | — | Linux / Windows sign-in (browser + localhost redirect) |

SHA-1 of the key the APKs are signed with (the debug key, for now):

```sh
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey \
  -storepass android -keypass android | grep SHA1
```

## 4. Put the ids in `google.json`

In the project root (it is git-ignored):

```json
{
  "GOOGLE_SERVER_CLIENT_ID": "<web client id>.apps.googleusercontent.com",
  "GOOGLE_DESKTOP_CLIENT_ID": "<desktop client id>.apps.googleusercontent.com",
  "GOOGLE_DESKTOP_CLIENT_SECRET": "<desktop client secret>"
}
```

The desktop "secret" is not confidential for installed apps (Google's own guidance); it
still stays out of git.

## 5. Build with it

```sh
flutter build apk --release --split-per-abi --dart-define-from-file=google.json
flutter build linux --release --dart-define-from-file=google.json
```

Then **Settings → Sync → Sign in with Google** and pick a mode:

- **Devices:** entries, tasks, to-dos, templates, repeats and settings sync through a hidden
  Drive folder only Donut can see. Each device writes its own file; the newest change to
  each item wins.
- **Calendar:** the above, plus saved entries mirrored to a "Donut" calendar (edit or delete
  them in Google Calendar and the change comes back), and busy times from your other
  calendars as faint arcs on the dial. Donut never reads what those events are.

Plan-mode sketches never sync until you tick ✓.

## Linux notes

Sign-in opens your browser and listens on a localhost port for the redirect. The sign-in is
stored in the desktop keyring (gnome-keyring / KWallet via libsecret). Without a keyring
running, it falls back to a file readable only by you in the app's data folder.
