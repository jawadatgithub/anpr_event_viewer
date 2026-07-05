# Google Sign-In Web Setup

After running `flutter create .`, open `web/index.html` and add this inside `<head>` if you prefer meta-tag configuration:

```html
<meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">
```

For this patched app, the safer development path is using dart-define:

```bash
flutter run -d chrome --web-hostname localhost --web-port 7357 --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_CLIENT_ID.apps.googleusercontent.com
```

Also add `http://localhost` and `http://localhost:7357` as Authorized JavaScript origins in Google Cloud Console.
