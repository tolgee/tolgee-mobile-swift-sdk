import Foundation
import OSLog

public enum TolgeeError: Error {
    case invalidJSONString
    case translationNotFound
}
/// The main Tolgee SDK class for handling localization and translations.
///
/// Tolgee provides a modern localization solution that supports:
/// - Remote translation loading from CDN
/// - ICU plural form handling for different languages
/// - Namespace-based translation organization
/// - Automatic caching and background updates
/// - Fallback to bundle-based localizations
/// - Automatic language detection from device settings
///
/// ## Quick Start
/// ```swift
/// // Automatic language detection (recommended)
/// Tolgee.shared.initialize(
///     cdn: URL(string: "https://cdn.tolgee.io/your-project-id")!
/// )
///
/// // Manual language specification (useful for testing)
/// Tolgee.shared.initialize(
///     cdn: URL(string: "https://cdn.tolgee.io/your-project-id")!,
///     language: "en"
/// )
///
/// // Use translations in your app
/// let greeting = Tolgee.shared.translate("hello_world")
/// let personalGreeting = Tolgee.shared.translate("hello_name", "Alice")
/// ```
@MainActor
public final class Tolgee {
    /// Shared singleton instance of Tolgee for convenient access throughout your app.
    ///
    /// This is the recommended way to access Tolgee functionality. The shared instance
    /// is configured with default URL session and file-based caching.
    ///
    /// ## Usage
    /// ```swift
    /// // Initialize with automatic language detection
    /// Tolgee.shared.initialize()
    ///
    /// // Or initialize with specific language for testing
    /// Tolgee.shared.initialize(language: "en")
    ///
    /// // Use translations
    /// let text = Tolgee.shared.translate("my_key")
    /// ```
    public static let shared = Tolgee(urlSession: URLSession.shared, cache: FileCache())

    // table - [key - TranslationEntry]
    private var translations: [String: [String: TranslationEntry]] = [:]
    private var cdnURL: URL?
    private var isFetchingFromCdn = false

    private var language: String?
    private var namespaces: Set<String> = []

    // Logger for Tolgee operations
    private let logger = Logger(subsystem: "com.tolgee.ios", category: "Tolgee")

    // CDN fetching service
    private let fetchCdnService: FetchCdnService

    private let cache: CacheProcotol

    // App lifecycle observer
    private let lifecycleObserver: AppLifecycleObserverProtocol

    private(set) var isInitialized = false
    private(set) var lastFetchDate: Date?

    /// Internal initializer for testing with custom URL session, cache, and lifecycle observer
    /// - Parameters:
    ///   - urlSession: Custom URL session for testing
    ///   - cache: Custom cache implementation for testing
    ///   - lifecycleObserver: Custom lifecycle observer for testing
    init(
        urlSession: URLSessionProtocol, cache: CacheProcotol,
        lifecycleObserver: AppLifecycleObserverProtocol = AppLifecycleObserver()
    ) {
        self.fetchCdnService = FetchCdnService(urlSession: urlSession)
        self.cache = cache
        self.lifecycleObserver = lifecycleObserver
        lifecycleObserver.startObserving { [weak self] in
            self?.fetch()
        }
    }

    deinit {
        lifecycleObserver.stopObserving()
    }

    /// Gets the preferred language from the device's locale settings.
    ///
    /// This method extracts the language code from the device's preferred locale,
    /// which is typically set by the user in their device settings.
    ///
    /// - Returns: The language code (e.g., "en", "es", "cs") based on device settings
    ///
    /// ## Examples
    /// - Device set to English: returns "en"
    /// - Device set to Spanish (Spain): returns "es"
    /// - Device set to Czech: returns "cs"
    private func getPreferredLanguage() -> String {
        // Get the preferred language from the device's locale
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"

        // Extract just the language code (before any region/script modifiers)
        let languageCode =
            Locale(identifier: preferredLanguage).language.languageCode?.identifier ?? "en"

        logger.debug(
            "Detected preferred language: \(languageCode) from device locale: \(preferredLanguage)")
        return languageCode
    }

    /// Initializes the Tolgee SDK with automatic language detection.
    ///
    /// This method automatically detects the device's preferred language and uses it
    /// for translations. It's the recommended initialization method for production apps
    /// as it provides the best user experience by using the language the user has
    /// configured on their device.
    ///
    /// - Parameters:
    ///   - cdn: The base URL of the Tolgee CDN where translation files are hosted (optional)
    ///   - namespaces: A set of namespace identifiers for organizing translations into logical groups (defaults to empty set)
    ///
    /// ## Usage
    /// ```swift
    /// // Basic initialization with automatic language detection
    /// Tolgee.shared.initialize()
    ///
    /// // Initialize with CDN and namespaces (automatic language)
    /// let cdnURL = URL(string: "https://cdn.tolgee.io/your-project-id")!
    /// Tolgee.shared.initialize(
    ///     cdn: cdnURL,
    ///     namespaces: ["buttons", "messages", "errors"]
    /// )
    /// ```
    ///
    /// ## Behavior
    /// - Automatically detects device's preferred language
    /// - Loads cached translations immediately if available
    /// - Initiates background fetch for fresh translations from CDN
    /// - Prevents multiple initializations (subsequent calls are ignored)
    /// - Sets up automatic translation refresh when app enters foreground
    ///
    /// - Note: For testing with specific languages, use `initialize(cdn:language:namespaces:)` instead
    public func initialize(cdn: URL? = nil, namespaces: Set<String> = []) {
        let detectedLanguage = getPreferredLanguage()
        initialize(cdn: cdn, language: detectedLanguage, namespaces: namespaces)
    }

    /// Initializes the Tolgee SDK with a manually specified language.
    ///
    /// This method allows you to specify a particular language code, which is useful
    /// for testing, debugging, or when you want to override the device's language
    /// settings. For production apps, consider using `initialize(cdn:namespaces:)`
    /// which automatically detects the user's preferred language.
    ///
    /// - Parameters:
    ///   - cdn: The base URL of the Tolgee CDN where translation files are hosted (optional)
    ///   - language: The target language code (e.g., "en", "es", "cs") for translations
    ///   - namespaces: A set of namespace identifiers for organizing translations into logical groups (defaults to empty set)
    ///
    /// ## Usage
    /// ```swift
    /// // Manual language specification (useful for testing)
    /// Tolgee.shared.initialize(language: "en")
    ///
    /// // Initialize with CDN and specific language
    /// let cdnURL = URL(string: "https://cdn.tolgee.io/your-project-id")!
    /// Tolgee.shared.initialize(
    ///     cdn: cdnURL,
    ///     language: "es",
    ///     namespaces: ["buttons", "messages", "errors"]
    /// )
    /// ```
    ///
    /// ## Behavior
    /// - Uses the specified language regardless of device settings
    /// - Loads cached translations immediately if available
    /// - Initiates background fetch for fresh translations from CDN
    /// - Prevents multiple initializations (subsequent calls are ignored)
    /// - Sets up automatic translation refresh when app enters foreground
    ///
    /// - Note: This method is particularly useful for testing specific language scenarios
    public func initialize(cdn: URL? = nil, language: String, namespaces: Set<String> = []) {

        guard !isInitialized else {
            logger.warning("Tolgee is already initialized")
            return
        }

        cdnURL = cdn
        self.language = language
        self.namespaces = namespaces

        if let data = cache.loadRecords(for: CacheDescriptor(language: language)) {
            do {
                // Load cached translations
                let translations = try JSONParser.loadTranslations(from: data)
                self.translations[""] = translations
            } catch {
                logger.error("Failed to load cached translations: \(error)")
            }
        } else {
            logger.debug("No cached translations found for language: \(language)")
        }

        for namespace in namespaces {
            if let data = cache.loadRecords(
                for: CacheDescriptor(language: language, namespace: namespace))
            {
                do {
                    // Load cached translations for each namespace
                    let translations = try JSONParser.loadTranslations(from: data, table: namespace)
                    self.translations[namespace] = translations
                } catch {
                    logger.error(
                        "Failed to load cached translations for namespace '\(namespace)': \(error)")
                }
            } else {
                logger.debug(
                    "No cached translations found for language: \(language), namespace: \(namespace)"
                )
            }
        }

        isInitialized = true
        logger.debug("Tolgee initialized with language: \(language), namespaces: \(namespaces)")

        fetch()
    }

    func fetch() {
        guard let cdnURL, let language, !isFetchingFromCdn, language.isEmpty == false else {
            return
        }

        isFetchingFromCdn = true

        Task {
            do {
                // Construct file paths for all translation files
                var filePaths: [String] = ["\(language).json"]  // Base language file
                for namespace in namespaces {
                    filePaths.append("\(namespace)/\(language).json")  // Namespace files
                }

                // Use the FetchCdnService to get all translation data
                let fetchService = fetchCdnService
                let translationData = try await fetchService.fetchFiles(
                    from: cdnURL,
                    filePaths: filePaths
                )

                // Process the fetched translation data
                for (filePath, data) in translationData {
                    // Determine the table name from the file path
                    let table: String
                    if filePath == "\(language).json" {
                        table = ""  // Base table
                    } else {
                        // Extract table name from "table/language.json" format
                        table = String(filePath.prefix(while: { $0 != "/" }))
                    }
                    do {
                        let translations = try JSONParser.loadTranslations(from: data, table: table)

                        if self.translations[table] == translations {
                            logger.debug("Translations for table '\(table)' are already up-to-date")
                            continue
                        }

                        self.translations[table] = translations

                        // Cache the fetched data
                        let descriptor: CacheDescriptor
                        if table.isEmpty {
                            descriptor = CacheDescriptor(language: language)
                        } else {
                            descriptor = CacheDescriptor(language: language, namespace: table)
                        }

                        // Save to cache on background thread to avoid blocking
                        Task.detached {
                            do {
                                try self.cache.saveRecords(data, for: descriptor)
                            } catch {
                                self.logger.error("Failed to save translations to cache: \(error)")
                            }

                        }

                        logger.debug(
                            "Cached translations for language: \(language), namespace: \(table.isEmpty ? "base" : table)"
                        )
                    } catch {
                        logger.error("Error loading translations for table '\(table)': \(error)")
                    }
                }
            } catch {
                logger.error("Failed to fetch translations from CDN: \(error)")
            }

            isFetchingFromCdn = false
            lastFetchDate = Date()
            logger.debug(
                "Translations fetched successfully at \(self.lastFetchDate ?? .distantPast)")
        }
    }

    /// Load translations from JSON string (primarily for testing)
    /// - Parameters:
    ///   - jsonString: The JSON string containing translations
    ///   - table: The table name for the translations (defaults to base table)
    /// - Throws: Error if JSON parsing fails
    func loadTranslations(from jsonString: String, table: String = "") throws {
        let translations = try JSONParser.loadTranslations(from: jsonString, table: table)
        self.translations[table] = translations
    }

    /// Load translations from JSON data (primarily for testing)
    /// - Parameters:
    ///   - jsonData: The JSON data containing translations
    ///   - table: The table name for the translations (defaults to base table)
    /// - Throws: Error if JSON parsing fails
    func loadTranslations(from jsonData: Data, table: String = "") throws {
        let translations = try JSONParser.loadTranslations(from: jsonData, table: table)
        self.translations[table] = translations
    }

    /// Translates a given key to a localized string with optional format arguments.
    ///
    /// This method first attempts to find the translation in the loaded Tolgee translations,
    /// including support for ICU plural forms and format specifiers. If not found, it falls
    /// back to the bundle's localized string mechanism.
    ///
    /// - Parameters:
    ///   - key: The translation key to look up
    ///   - arguments: Variable arguments to substitute into the translated string (supports format specifiers like %@, %d, etc.)
    ///   - table: The name of the strings table to search (optional, defaults to base table)
    ///   - bundle: The bundle containing the strings file (defaults to main bundle)
    /// - Returns: The localized string for the given key with arguments formatted, or the fallback value
    ///
    /// ## Usage
    /// ```swift
    /// // Simple translation
    /// let greeting = tolgee.translate("hello_world")
    ///
    /// // Translation with arguments
    /// let personalGreeting = tolgee.translate("hello_name", "Alice")
    ///
    /// // Translation with plural forms
    /// let itemCount = tolgee.translate("item_count", 5)
    ///
    /// // Translation from specific table
    /// let buttonText = tolgee.translate("save_button", table: "Buttons")
    /// ```
    ///
    /// ## ICU Plural Support
    /// The method automatically handles ICU plural forms for different languages:
    /// ```json
    /// {
    ///   "item_count": "{0, plural, one {# item} other {# items}}"
    /// }
    /// ```
    ///
    /// - Note: Uses the current device locale for plural rule evaluation
    public func translate(
        _ key: String, _ arguments: CVarArg..., table: String? = nil, bundle: Bundle = .main
    )
        -> String
    {
        let locale = Locale.current

        // First try to get translation from loaded translations
        if let translationEntry = translations[table ?? ""]?[key] {
            return JSONParser.formatTranslation(translationEntry, with: arguments, locale: locale)
        }

        // Fallback to bundle.localizedString
        let localizedString = bundle.localizedString(forKey: key, value: nil, table: table)

        // If we have arguments, try to format the string
        if !arguments.isEmpty {
            return String(format: localizedString, locale: locale, arguments: arguments)
        }

        return localizedString
    }

    /// Translates a given key to a localized string with optional format arguments and custom locale.
    ///
    /// This method provides the same functionality as the basic translate method but allows you to
    /// specify a custom locale for both plural rule evaluation and bundle localization fallback.
    /// It first attempts to find the translation in the loaded Tolgee translations, including
    /// support for ICU plural forms and format specifiers. If not found, it falls back to the
    /// bundle's localized string mechanism using the specified locale.
    ///
    /// - Parameters:
    ///   - key: The translation key to look up
    ///   - arguments: Variable arguments to substitute into the translated string (supports format specifiers like %@, %d, etc.)
    ///   - table: The name of the strings table to search (optional, defaults to base table)
    ///   - bundle: The bundle containing the strings file (defaults to main bundle)
    ///   - locale: The locale to use for plural rule evaluation and bundle fallback (defaults to current locale)
    /// - Returns: The localized string for the given key with arguments formatted according to the specified locale
    ///
    /// ## Usage
    /// ```swift
    /// let spanishLocale = Locale(identifier: "es_ES")
    ///
    /// // Translation with custom locale
    /// let greeting = tolgee.translate("hello_name", "María", locale: spanishLocale)
    ///
    /// // Plural forms with specific locale
    /// let itemCount = tolgee.translate("item_count", 3, locale: spanishLocale)
    ///
    /// // Useful for testing different localizations
    /// let testLocale = Locale(identifier: "ja_JP")
    /// let japaneseText = tolgee.translate("welcome_message", locale: testLocale)
    /// ```
    ///
    /// ## Locale-Specific Plural Rules
    /// Different languages have different plural rules. This method ensures the correct
    /// plural form is selected based on the specified locale:
    /// - English: one/other (1 item vs 2 items)
    /// - Russian: one/few/many/other (1, 2-4, 5+, and other cases)
    /// - Japanese: other only (no plural distinction)
    ///
    /// - Note: Available on iOS 18.4+ and macOS 15.4+ due to the enhanced bundle localization API
    @available(iOS 18.4, *)
    @available(macOS 15.4, *)
    public func translate(
        _ key: String, _ arguments: CVarArg..., table: String? = nil, bundle: Bundle = .main,
        locale: Locale = .current
    )
        -> String
    {
        // First try to get translation from loaded translations
        if let translationEntry = translations[table ?? ""]?[key] {
            return JSONParser.formatTranslation(translationEntry, with: arguments, locale: locale)
        }

        // Fallback to bundle.localizedString
        let localizedString = bundle.localizedString(
            forKey: key, value: nil, table: table, localizations: [locale.language])

        // If we have arguments, try to format the string
        if !arguments.isEmpty {
            return String(format: localizedString, locale: locale, arguments: arguments)
        }

        return localizedString
    }
}
