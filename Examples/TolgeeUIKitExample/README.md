# Tolgee UIKit Example

This example demonstrates how to integrate Tolgee SDK into a UIKit application.

## Features Demonstrated

- **SDK Initialization**: Shows how to initialize Tolgee in `AppDelegate` with CDN URL and debug logging
- **Direct SDK Usage**: Demonstrates using `Tolgee.shared.translate()` for displaying translations in UILabel
- **Language Switching**: Implements a segmented control for dynamic language switching using `setCustomLocale()`
- **Reactive Updates**: Shows how to observe translation updates with `onTranslationsUpdated()` and update UI accordingly
- **Log Forwarding**: Demonstrates observing SDK logs with `onLogMessage()` for analytics integration
- **Bundle Swizzling**: Shows how to enable optional swizzling of Apple's `NSLocalizedString` API via environment variables

## Key Files

- **AppDelegate.swift**: SDK initialization and observer setup in `didFinishLaunchingWithOptions`
- **ViewController.swift**: Main view controller demonstrating translation usage and language switching
- **Localizable.xcstrings**: Fallback translations bundled with the app

## Running the Example

1. Open `TolgeeUIKitExample.xcodeproj` in Xcode
2. Build and run the project
3. The app will automatically fetch the latest translations from the Tolgee CDN
4. Use the segmented control to switch between different languages

## Bundle Swizzling

This example includes configuration for enabling Tolgee's optional swizzling of Apple's localization APIs. To enable it:

1. Go to **Product → Scheme → Edit Scheme...**
2. Select **Run** → **Arguments** tab
3. Ensure `TOLGEE_ENABLE_SWIZZLING=true` is set in the environment variables

When enabled, calls to `NSLocalizedString()` and `Bundle.main.localizedString(forKey:)` will be automatically backed by the Tolgee SDK.

**Note:** Pluralized strings are not currently supported with swizzling and will fall back to bundled translations.

## Note

This example uses a public demo Tolgee project. For your own project, replace the CDN URL in `AppDelegate.swift` with your own project's CDN URL.
