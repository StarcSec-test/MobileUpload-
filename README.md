# MobileUpload

Minimal Android app (Kotlin) that shows **Hello, StarcSec!** on one screen. It exists only to produce a debug APK for testing the StarcSec mobile app upload API.

## Run locally

Requirements: JDK 17 and the Android SDK (platform 34). Android Studio installs both.

**Android Studio:** open this folder, pick an emulator or device, press Run.

**Command line:**

```sh
./gradlew assembleDebug
```

The APK is written to `app/build/outputs/apk/debug/app-debug.apk`. Install it on a connected device or emulator with:

```sh
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

## CI/CD

`.github/workflows/build-and-upload.yml` runs on every push to `main`:

1. Check out the repository.
2. Set up Java 17 and Gradle.
3. Build the debug APK (`./gradlew assembleDebug`).
4. Run `./upload-mobile-app.sh app/build/outputs/apk/debug/app-debug.apk "Hello StarcSec"`.

The upload step runs only after the build succeeds. If either step fails, the workflow fails.

### Credentials

No GitHub Actions secrets are used. `upload-mobile-app.sh` has the `Organisationid` and `Authorization` headers written directly in the script. Before pushing, replace the `Basic ******` placeholder with the real value. Until then the upload returns an auth error and the workflow fails.

Anything committed to the repository stays in git history, so keep this repository private and rotate the token if it ever leaks.

## Upload script

`upload-mobile-app.sh <FILE_PATH> <UPLOAD_NAME>` splits the file into 95 MB chunks and posts each chunk to `https://api-dev.starcsec.com/v1/integration/mobileAsset/upload`. The name sent to the API is `<UPLOAD_NAME>_<unix timestamp>`. It exits non-zero if any chunk gets an HTTP status other than 200 or 201, so a green workflow run means every chunk request was accepted.
