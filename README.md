# ShootLater

ShootLater is a local-first iOS 26+ SwiftUI app for quickly saving photography scouting spots.

## Project

- Generate the Xcode project with `xcodegen generate`.
- Open `ShootLater.xcodeproj` after generation.
- Main app bundle: `com.anthonycadena.ShootLater`.
- Widget/control extension bundle: `com.anthonycadena.ShootLater.widgets`.
- Shared app group: `group.com.anthonycadena.ShootLater`.

## Verification

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  test \
  -project ShootLater.xcodeproj \
  -scheme ShootLater \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' \
  -derivedDataPath DerivedData
```
