# Tolgee Mobile Swift SDK (Alpha) 🐁

[![Tolgee](https://img.shields.io/badge/Tolgee-f06695)](https://tolgee.io/)
![Android](https://img.shields.io/badge/iOS-Supported-green?logo=ios)
![language](https://img.shields.io/github/languages/top/tolgee/tolgee-mobile-swift-sdk)
[![github release](https://img.shields.io/github/v/release/tolgee/tolgee-mobile-swift-sdk?label=GitHub%20Release)](https://github.com/tolgee/tolgee-mobile-swift-sdk/releases/latest)
![Licence](https://img.shields.io/github/license/tolgee/tolgee-mobile-swift-sdk)
[![github stars](https://img.shields.io/github/stars/tolgee/tolgee-mobile-swift-sdk?style=social&label=Tolgee%20Mobile%20Swift%20SDK)](https://github.com/tolgee/tolgee-mobile-swift-sdk)
[![github stars](https://img.shields.io/github/stars/tolgee/tolgee-platform?style=social&label=Tolgee%20Platform)](https://github.com/tolgee/tolgee-platform)
[![Github discussions](https://img.shields.io/github/discussions/tolgee/tolgee-platform)](https://github.com/tolgee/tolgee-platform/discussions)
[![Dev.to](https://img.shields.io/badge/Dev.to-tolgee_i18n?logo=devdotto&logoColor=white)](https://dev.to/tolgee_i18n)
[![Read the Docs](https://img.shields.io/badge/Read%20the%20Docs-8CA1AF?logo=readthedocs&logoColor=fff)](https://docs.tolgee.io/)
[![Slack](https://img.shields.io/badge/Slack-4A154B?logo=slack&logoColor=fff)](https://tolg.ee/slack)
[![YouTube](https://img.shields.io/badge/YouTube-%23FF0000.svg?logo=YouTube&logoColor=white)](https://www.youtube.com/@tolgee)
[![LinkedIn](https://custom-icon-badges.demolab.com/badge/LinkedIn-0A66C2?logo=linkedin-white&logoColor=fff)](https://www.linkedin.com/company/tolgee/)
[![X](https://img.shields.io/badge/X-%23000000.svg?logo=X&logoColor=white)](https://x.com/Tolgee_i18n)

## What is Tolgee?

[Tolgee](https://tolgee.io/) is a powerful localization platform that simplifies the translation process for your applications.
This SDK provides integration for iOS and macOS projects.

## ✨ Features

- 🌍 **Remote translation loading** from Tolgee CDN with automatic updates
- 📦 **Namespace-based organization** for scalable translation management  
- 💾 **Intelligent caching** with ETag support and background synchronization
- 🔄 **Automatic fallback** to bundle-based localizations when offline
- 🎯 **Smart language detection** from device settings with manual override
- ⚡ **Modern async/await API** for Swift concurrency
- 🔧 **SwiftUI integration** with reactive updates and `TolgeeText` component
- 📱 **Multi-platform support** for iOS, macOS, tvOS, and watchOS
- 🔍 **Advanced debugging** with comprehensive logging 


## Installation

> [!NOTE]
> For managing static translations (used as fallback), check out [tolgee-cli](https://github.com/tolgee/tolgee-cli).
> It provides tools for updating and syncing your static translation files.
>
> In each demo project you can find an example of `.tolgeerc` configuration file.



## 🚀 Quick Start

Here's a quick example of initializing Tolgee in an iOS application:

```swift
import Tolgee

// Initialize with your Tolgee CDN URL
let cdnURL = URL(string: "https://cdn.tolgee.io/your-project-id")!
Tolgee.shared.initialize(cdn: cdnURL)

// Fetch latest translations asynchronously
await Tolgee.shared.remoteFetch()

// Use translations throughout your app
let greeting = Tolgee.shared.translate("hello_world")
let personalGreeting = Tolgee.shared.translate("hello_name", "Alice")
```

## 📦 Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tolgee/tolgee-mobile-swift-sdk", from: "1.0.0")
]
```

Or through Xcode:
1. File → Add Package Dependencies...
2. Enter: `https://github.com/tolgee/tolgee-mobile-swift-sdk`
3. Choose version and add to your target

## 🎯 Basic Usage

### Initialization

```swift
import Tolgee

// Set the CDN format to Apple in your Tolgee project
let cdnURL = URL(string: "https://cdn.tolgee.io/your-project-id")!
Tolgee.shared.initialize(cdn: cdnURL)
```

Refer to our SwiftUI and UIKit examples for a complete setup.

### Advanced Initialization

```swift
// Initialize with specific language and namespaces
Tolgee.shared.initialize(
    cdn: URL(string: "https://cdn.tolgee.io/your-project-id")!,
    language: "es", // Force Spanish instead of auto-detection
    namespaces: ["buttons", "errors", "onboarding"], // Organize translations
    enableDebugLogs: true // Enable detailed logging for development
)
```

### Fetch Remote Translations
You have to explicitly call the `fetch` method to fetch translations from the CDN.
```swift
await Tolgee.shared.remoteFetch()
```

### Basic Translation

```swift
// Simple string translation
let title = Tolgee.shared.translate("app_title")

// Translation with arguments
let welcomeMessage = Tolgee.shared.translate("welcome_user", "John")
let itemCount = Tolgee.shared.translate("items_count", 5)
let nameAndAge = Tolgee.shared.translate("My name is %@ and I'm %lld years old", "John", 30)
```

> [!NOTE]
> Strings with multiple pluralized parameters are currently **not supported**, for example `Tolgee.shared.translate("I have %lld apples and %lld oranges", 2, 3)`

### 🔧 SwiftUI Integration

Tolgee is designed to work great with SwiftUI and SwiftUI previews.

```swift
import SwiftUI
import Tolgee

struct ContentView: View {
    @State private var userName = "Alice"
    @State private var itemCount = 5
    
    var body: some View {
        VStack {
            // Simple text translation
            TolgeeText("welcome_title")
            
            // Text with arguments
            TolgeeText("hello_user", userName)
            
            // Text with pluralization
            TolgeeText("item_count", itemCount)
        }
    }
}
```

### Reactive Updates

Tolgee provides a hook to allow the consumer of the SDK to be notified about when the translation cache has been updated.

```swift
Task {
    for await _ in Tolgee.shared.onTranslationsUpdated() {
        // update your UI
    }
}
```

When using SwiftUI, Tolgee offers a convenience utility that automatically triggers a redraw of a view when the translations cache has been updated.

```swift
struct ContentView: View {
    
    // This will automatically re-render the view when
    // the localization cache is updated from a CDN.
    @StateObject private var updater = TolgeeSwiftUIUpdater()
    
    var body: some View {
        VStack {
            TolgeeText("My name is %@ and I have %lld apples", "John", 3)
        }
    }
}
```

### Swizzling of Apple's APIs
Tolgee optionally supports swizzling of `Bundle.localizedString`, which is being used by `NSLocalizedString` function. In order to enable swizzling, set enviromental variable `TOLGEE_ENABLE_SWIZZLING=true` in your scheme settings. Refer to our UIKit example.


## 🌐 Advanced Features

### Custom Tables/Namespaces
Tolgee iOS SDK supports loading of local translations from multiple local tables by providing the `table` parameter. When using `.xcstrings` files, the names of the tables match the names of your files without the extension. You do not need to provide the table name when loading strings stored in the default `Localizable.xcstrings` file.

To have the OTA updates working properly, make sure that you have enabled namespaces for your Tolgee project and that you have created namespaces matching the names of your local tables.

```swift
// Initialize with multiple namespaces for better organization
Tolgee.shared.initialize(
    cdn: cdnURL,
    namespaces: ["common", "auth", "profile", "settings"]
)

// Use translations from specific namespaces
let commonGreeting = Tolgee.shared.translate("hello", table: "common")
// or for SwiftUI
TolgeeText("hello", table: "common")
```

### Custom Bundles

You may have your strings resources stored in a dedicated XCFramework or a Swift Package.

```swift
let bundle: Bundle = ... // access the bundle

// Use the SDK directly
let commonGreeting = Tolgee.shared.translate("hello", bundle: bundle)
// or for SwiftUI
TolgeeText("hello", bundle: bundle)
```

### Log Forwarding
Tolgee allows forwarding of logs that are printed to the console by default.
You can use this feature to forward errors and other logs into your analytics.

```swift
for await logMessage in Tolgee.shared.onLogMessage() {
    // Here you can forward logs from Tolgee SDK to your analytics SDK.
}
```


## 📱 Platform Support

| Platform | Minimum Version | 
|----------|----------------|
| iOS      | 16.0+          |
| macOS    | 13.0+          |
| tvOS     | 16.0+          |
| watchOS  | 6.0+           |

## ⚙️ Requirements

- **Swift:** 6.0+
- **Xcode:** 16.3+

## 🧵 Thread-safety

Tolgee SDK is designed to be used synchronously on the main actor (except the `fetch` method). Access to the SDK from other actors generally has to be awaited.

```swift
Task.deattached {
    // notice that the call has to be awaited outside of the main actor
    let str = await Tolgee.shared.translate("key")
}
```

## 🤝 Why Choose Tolgee?

**Tolgee saves a lot of time** you would spend on localization tasks otherwise. It enables you to provide **perfectly translated software**.

### All-in-one localization solution for your iOS application 🙌
### Translation management platform 🎈
### Open-source 🔥

[Learn more on the Tolgee website →](https://tolgee.io)

## 📚 Examples & Demos

Check out our example projects:
- [SwiftUI Integration](Examples/TolgeeSwiftUIExample)
- [UIKit Integration](Examples/TolgeeUIKitExample)

## 🆘 Need Help?

- 📖 [Documentation](https://docs.tolgee.io)
- 💬 [Community Slack](https://tolg.ee/slack)
- 🐛 [Report Issues](https://github.com/petrpavlik/tolgee-ios/issues)
- 💡 [Feature Requests](https://github.com/petrpavlik/tolgee-ios/discussions)

## 🏗️ Contributing

Contributions are welcome!

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <a href="https://tolgee.io">
    <img src="https://user-images.githubusercontent.com/18496315/188628892-33fcc282-44f1-4926-8be4-d0db5a2420ca.png" alt="Tolgee" />
  </a>
</p>

<p align="center">
Made with ❤️ by the <a href="https://github.com/tolgee">Tolgee team</a>
</p>
