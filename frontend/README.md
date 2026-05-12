# AI Exam Assistant Frontend

Flutter app for Android, iOS, and Windows.

## Local Development

Start the FastAPI backend first:

```powershell
cd "..\backend"
.\.venv\Scripts\Activate.ps1
uvicorn main:app --reload
```

Run the Windows app:

```powershell
flutter run -d windows
```

Run on an Android emulator:

```powershell
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8010
```

For iOS simulator on macOS, run:

```bash
flutter run -d ios --dart-define=API_BASE_URL=https://your-api.example.com
```

For real Android and iOS devices, deploy the backend to an HTTPS URL and build with:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.example.com
flutter build ios --release --dart-define=API_BASE_URL=https://your-api.example.com
```

When the backend is hosted online, backend changes update all installed apps automatically after redeploy. UI changes require a new app release.

The local release APK is generated at:

```text
build\app\outputs\flutter-apk\app-release.apk
```
