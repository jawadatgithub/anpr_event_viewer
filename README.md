# InSysOut ANPR Event Viewer

Minimal Flutter ANPR/LPR event viewer for integration testing and demos.

## Features

- Event list and detail screens
- JSON payload import
- XML payload import
- CSV payload import
- SQL `INSERT` payload import
- Manual protobuf binary/base64 parser placeholder
- Base64 image support, including `data:image/png;base64,...`
- Raw base64 image support
- URL image support
- Local file path image reference support
- Arabic and English field support
- Local file import using file picker
- Google Drive import using Google Sign-In + Drive API
- InSysOut branding and launcher icon configuration

## Import Sources

The import screen supports three flows:

1. **Paste** — paste JSON, XML, CSV, SQL, or base64 protobuf.
2. **Files** — choose one or more local files: `.json`, `.xml`, `.csv`, `.sql`, `.pb`, `.protobuf`, `.bin`, `.txt`.
3. **Google Drive** — sign in, list supported payload files, then download/import selected Drive files.

Important: the **Files** button can also pick files from Google Drive on Android/iOS if the Google Drive app or OS file provider is installed. This is the easiest zero-backend option.

The direct **Google Drive** button uses the Google Drive API and requires OAuth setup.

## Run

After extracting the project:

```bash
flutter create .
flutter pub get
dart run flutter_launcher_icons
flutter run
```

## Google Drive OAuth Setup

For direct Google Drive import, configure Google Sign-In for your app in Google Cloud Console.

You need:

- A Google Cloud project
- OAuth consent screen
- Android OAuth client using your Android package name and SHA-1
- iOS OAuth client if you build iOS
- Drive API enabled

The app requests read-only Drive access:

```dart
drive.DriveApi.driveReadonlyScope
```

For Android release builds, add internet permission if your generated manifest does not already include it:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

For iOS, follow `google_sign_in` setup and add the reversed client ID URL scheme to `Info.plist`.

## Supported File Types

| Type | Extensions | Content Type |
|---|---|---|
| JSON | `.json` | `application/json` |
| XML | `.xml` | `application/xml` |
| CSV | `.csv` | `text/csv` |
| SQL | `.sql` | `application/sql` |
| Protobuf | `.pb`, `.protobuf`, `.bin` | `application/x-protobuf` |

## Notes

- The protobuf parser is intentionally a manual placeholder so you can map your real vendor `.proto` schema later.
- For production protobuf, add the vendor `.proto` file, generate Dart classes, and replace the manual parser.
- Base64 vehicle images should be either raw base64 or `data:image/...;base64,...`.
- Large base64 images in CSV/SQL can make files heavy; JSON is recommended for demos.


## Import UX update

When users import one or more local files successfully, the import screen closes automatically and the main event list shows a success message. The same behavior is used after importing a selected Google Drive file.

## Google Drive import notes

The app supports two Google Drive paths:

1. **Recommended on Windows:** install Google Drive for desktop, sync a folder, then use **Files** import and select `.json`, `.xml`, `.csv`, `.sql`, `.pb`, `.protobuf`, or `.bin` files from the synced folder.
2. **Direct Google Drive OAuth:** supported on Android, iOS, macOS, and Web after OAuth configuration.

For Flutter Web, create a Google OAuth Web Client ID, add the local development origins in Google Cloud Console, then run with a fixed port:

```bash
flutter run -d chrome --web-hostname localhost --web-port 7357 --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_CLIENT_ID.apps.googleusercontent.com
```

In Google Cloud Console, add these Authorized JavaScript origins for local testing:

```text
http://localhost
http://localhost:7357
```

Without this configuration, the app now shows a clear message instead of crashing with `ClientID not set`.

## Free Version Daily Limit

The free version is limited to **10 ANPR events per event date**.

When the limit is reached, the app shows this message:

```text
Buy the pro version, which include unlimited events per day and custom schema definition.
for features request: contact hello@insysout.com
```

The limit is enforced by the event timestamp date. If an event has no timestamp, the app uses the current local date.

## Icon Update

This package includes a regenerated InSysOut icon set from the supplied 512x512 logo.

Generated assets include:

```text
assets/branding/insysout_logo.png
assets/branding/insysout_full_logo_512.png
assets/branding/insysout_full_logo_1024.png
assets/branding/insysout_app_icon.png
assets/branding/insysout_app_icon_transparent_1024.png
assets/branding/insysout_app_icon_solid_1024.png
web/favicon.png
web/favicon.ico
web/icons/Icon-192.png
web/icons/Icon-512.png
web/icons/Icon-maskable-192.png
web/icons/Icon-maskable-512.png
windows/runner/resources/app_icon.ico
```

After extracting, run:

```bash
flutter create .
flutter pub get
dart run flutter_launcher_icons
flutter clean
flutter run
```

If you run `flutter create .` after extracting, run `dart run flutter_launcher_icons` again so Android, iOS, Web, Windows, and macOS launcher icons are regenerated from the updated icon source.
