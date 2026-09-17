# Android manifest additions (apply after `flutter create .`)

This repo ships only `lib/` and `pubspec.yaml` — no `android/` or `ios/`
folder — because generating that scaffolding correctly requires the actual
`flutter` CLI, which isn't available in the sandbox this was built in (no
internet access to fetch the Flutter SDK). This is a one-time, two-minute
step on your machine (see SETUP section in PROJECT_README.md).

After you run `flutter create .` inside this folder (it fills in
`android/`, `ios/`, etc. without touching your existing `lib/`), open
`android/app/src/main/AndroidManifest.xml` and add:

```xml
<manifest ...>
    <!-- Talk to the FastAPI backend -->
    <uses-permission android:name="android.permission.INTERNET" />

    <!-- Voice search (speech_to_text -> Android SpeechRecognizer) -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />

    <!-- Android 11+ (API 30+) needs this so the app can see that a speech
         recognition service exists on the device at all -->
    <queries>
        <intent>
            <action android:name="android.speech.RecognitionService" />
        </intent>
    </queries>

    <application ...>
        ...
    </application>
</manifest>
```

`INTERNET` and `RECORD_AUDIO` go as direct children of `<manifest>`
(siblings of `<application>`), and `<queries>` is also a direct child of
`<manifest>`, not inside `<application>`.

## Emulator vs real device — the ONE line you must edit

`lib/core/api_endpoints.dart` → `ApiConfig.baseUrl`:

- **Android emulator**, backend running on your PC: `http://10.0.2.2:8000`
  (10.0.2.2 is the emulator's alias for your host machine's localhost —
  `127.0.0.1` from inside the emulator means the emulator itself, not your PC).
- **Real phone**, same Wi-Fi as your PC: `http://<your-PC's-LAN-IP>:8000`
  (find it with `ipconfig` on Windows / `ifconfig` or `ip addr` on
  Mac/Linux — something like `192.168.1.42`). You'll also need to start
  uvicorn with `--host 0.0.0.0` so it accepts connections from other
  devices, not just localhost.

Voice recognition (speech_to_text) only works on a **real device** or an
emulator image with Google Play Services + a working microphone routed
through it — most bare AOSP emulator images will report "not available."
Test voice search on a real phone.
