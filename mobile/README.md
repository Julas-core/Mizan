# Mizan Mobile

This app depends on the local backend API. The steps below are the exact setup that worked with a physical Android phone.

## Run the app (working flow)

### 1) Start backend API first

From the project root (`D:\Projects\Mizan`):

```powershell
cd backend
py -3.11 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --log-level debug
```

Keep this terminal running.

### 2) Find your PC Wi-Fi IPv4 address

```powershell
ipconfig
```

Use the `IPv4 Address` under your active Wi-Fi adapter (example: `10.196.132.247`).

### 3) Verify backend is reachable on LAN (optional but recommended)

```powershell
Invoke-WebRequest -UseBasicParsing http://<YOUR_PC_IP>:8000/api/v1/health/ | Select-Object -ExpandProperty Content
```

Expected response:

```json
{"status":"ok","project":"Mizan Backend","version":"1.0.0"}
```

### 4) Run Flutter app with API base URL

In a second terminal:

```powershell
cd mobile
flutter run --dart-define=API_BASE_URL=http://<YOUR_PC_IP>:8000/api/v1
```

Example that worked:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.196.132.247:8000/api/v1
```

### 5) One-command helper (recommended)

From the `mobile` folder:

```powershell
.\run-mobile-lan.ps1
```

What it does:
- Detects your active local IPv4 automatically.
- Builds `API_BASE_URL` for Flutter.
- Verifies backend health endpoint before launching.
- Runs `flutter run` with the correct `--dart-define`.

Optional flags:

```powershell
.\run-mobile-lan.ps1 -BackendHostIp 10.196.132.247
.\run-mobile-lan.ps1 -DeviceId <flutter-device-id>
.\run-mobile-lan.ps1 -SkipHealthCheck
```

## Notes

- Phone and PC must be on the same Wi-Fi network.
- If your IP changes, update `<YOUR_PC_IP>` in the `flutter run` command.
- If connection fails, check Windows Firewall allows inbound port `8000`.
