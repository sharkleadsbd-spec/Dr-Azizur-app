# Dr. Azizur — Flutter Android Demo

This is a Flutter source project for an offline appointment-manager demo.

## Included
- Dr. Azizur branding and the supplied doctor portrait as app image
- Separate demo Doctor and Assistant login
- Local SQLite appointment storage
- New Patient / Old Patient classification
- Daily serial number generation (001, 002, ...)
- Today's dashboard counts and appointment list
- Appointment history
- Bangla speech-to-text dictation into the patient-name field for review
- SMS sending is not included

## Demo login
- Doctor: `doctor` / `doctor123`
- Assistant: `assistant` / `assistant123`

These are demo credentials only. Before real clinical use, replace this demo login with a properly secured authentication flow and restrict access to patient data.

## Build APK
1. Install Flutter SDK and Android Studio (Android SDK).
2. Extract this project.
3. Open a terminal in the project folder.
4. Run:
   ```bash
   flutter pub get
   flutter create .
   flutter run
   flutter build apk --release
   ```
5. APK output:
   `build/app/outputs/flutter-apk/app-release.apk`

If `flutter create .` regenerates Android scaffolding, make sure `android/app/src/main/AndroidManifest.xml` includes the RECORD_AUDIO permission and application label `Dr. Azizur`.

## Important limitations of this demo
- SQLite data is stored only on the device. Uninstalling the app or losing the phone may delete the records.
- No cloud sync: different phones do not share records.
- Voice recognition depends on Android speech services and internet/device language support. Dictated text goes into the name field for manual review; age and phone must be checked/entered manually.
- This is a demonstration build, not a validated medical-record system. Do not enter real patient data until security, backups, access controls, and privacy requirements have been reviewed.
