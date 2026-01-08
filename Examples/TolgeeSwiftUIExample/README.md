# Tolgee SwiftUI Example

This example demonstrates how to integrate Tolgee SDK into a SwiftUI application.

## Features Demonstrated

- **SDK Initialization**: Shows how to initialize Tolgee with CDN URL and debug logging
- **Remote Translation Fetching**: Demonstrates fetching translations from Tolgee CDN
- **TolgeeText Component**: Uses the convenient `TolgeeText` view for displaying translations
- **Direct SDK Usage**: Shows how to use `Tolgee.shared.translate()` with the `locale` parameter for SwiftUI previews
- **Language Switching**: Implements a language picker that dynamically changes the app language using `setCustomLocale()`
- **Reactive Updates**: Uses `TolgeeSwiftUIUpdater` to automatically re-render views when translations are updated
- **Translation Observers**: Demonstrates observing translation updates with `onTranslationsUpdated()`
- **Log Forwarding**: Shows how to observe SDK logs with `onLogMessage()` for analytics integration

## Key Files

- **TolgeeSwiftUIExampleApp.swift**: SDK initialization and observer setup
- **ContentView.swift**: Main view demonstrating translation usage and language switching
- **LanguagePicker.swift**: Custom language picker component
- **Localizable.xcstrings**: Fallback translations bundled with the app

## Running the Example

1. Open `TolgeeSwiftUIExample.xcodeproj` in Xcode
2. Build and run the project
3. The app will automatically fetch the latest translations from the Tolgee CDN
4. Use the language picker to switch between different languages

## SwiftUI Previews

The example also demonstrates how to use SwiftUI previews with different locales by passing the `locale` parameter to the `translate()` method.

## Note

This example uses a public demo Tolgee project. For your own project, replace the CDN URL in `TolgeeSwiftUIExampleApp.swift` with your own project's CDN URL.
