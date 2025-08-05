import Combine
import Foundation

public enum TolgeeError: Error {
    case invalidJSONString
    case translationNotFound
}

/// The main Tolgee SDK class for handling localization and translations.
///
/// Tolgee provides a modern localization solution that supports:
/// - Remote translation loading from CDN
/// - Namespace-based translation organization
/// - Automatic caching and background updates
/// - Fallback to bundle-based localizations
/// - Automatic language detection from device settings
///
/// ## Quick Start
/// ```swift
/// // Automatic language detection (recommended for production)
/// Tolgee.shared.initialize(
///     cdn: URL(string: "https://cdn.tolgee.io/your-project-id")!
/// )
///
/// // Fetch latest translations
/// try await Tolgee.shared.remoteFetch()
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
    /// // Initialize with automatic language detection (production)
    /// Tolgee.shared.initialize()
    /// try await Tolgee.shared.remoteFetch()
    ///
    /// // Initialize with specific language (testing)
    /// Tolgee.shared.initialize(language: "en")
    /// try await Tolgee.shared.remoteFetch()
    ///
    /// // Use translations
    /// let text = Tolgee.shared.translate("my_key")
    /// ```
    public static let shared = Tolgee(
        urlSession: URLSession.shared,
        cache: FileCache(),
        appVersionSignature: getAppVersionSignature())

    // table - [key - TranslationEntry]
    private var translations: [String: [String: TranslationEntry]] = [:]
    private var cdnURL: URL?

    private var language: String?
    private var namespaces: Set<String> = []

    // Logger for Tolgee operations
    private let logger = TolgeeLog()

    private let fetchCdnService: FetchCdnService
    private let cache: CacheProtocol

    /// Indicates whether the Tolgee SDK has been initialized.
    ///
    /// This property becomes `true` after the first successful call to `initialize(cdn:language:namespaces:)`.
    /// Subsequent initialization attempts will be ignored while this remains `true`.
    private(set) public var isInitialized = false

    /// The timestamp of the last successful translation fetch from the CDN.
    ///
    /// This property is `nil` until the first successful CDN fetch completes. It's updated
    /// each time translations are successfully retrieved from the remote CDN, regardless
    /// of whether the translations actually changed.
    private(set) public var lastFetchDate: Date?

    private var appVersionSignature: String? = nil

    private let onInitializedSubject = PassthroughSubject<Void, Never>()
    private let onTranslationsUpdatedSubject = PassthroughSubject<Void, Never>()

    public var onInitialized: AnyPublisher<Void, Never> {
        onInitializedSubject.eraseToAnyPublisher()
    }

    public var onTranslationsUpdated: AnyPublisher<Void, Never> {
        onTranslationsUpdatedSubject.eraseToAnyPublisher()
    }

    init(
        urlSession: URLSessionProtocol, cache: CacheProtocol,
        appVersionSignature: String?
    ) {
        self.appVersionSignature = appVersionSignature
        self.fetchCdnService = FetchCdnService(urlSession: urlSession)
        self.cache = cache
    }

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

    /// Initializes the Tolgee SDK with automatic language detection or manual override.
    ///
    /// This method provides flexible initialization options:
    /// - **Automatic language detection** (recommended): When `language` is `nil`, automatically detects
    ///   the user's preferred language from device settings
    /// - **Manual language specification**: When `language` is provided, uses that specific language
    ///   regardless of device settings (useful for testing)
    ///
    /// The method loads cached translations immediately if available and initiates a background
    /// fetch for fresh translations from the CDN.
    ///
    /// - Parameters:
    ///   - cdn: The base URL of the Tolgee CDN where translation files are hosted (optional)
    ///   - language: The target language code (e.g., "en", "es", "cs"). If `nil`, automatically detects from device settings (optional)
    ///   - namespaces: A set of namespace identifiers for organizing translations into logical groups (defaults to empty set)
    ///
    /// ## Usage
    /// ```swift
    /// // Automatic language detection (recommended for production)
    /// Tolgee.shared.initialize()
    /// try await Tolgee.shared.remoteFetch()
    ///
    /// // Automatic detection with CDN
    /// let cdnURL = URL(string: "https://cdn.tolgee.io/your-project-id")!
    /// Tolgee.shared.initialize(cdn: cdnURL)
    /// try await Tolgee.shared.remoteFetch()
    ///
    /// // Manual language specification (useful for testing)
    /// Tolgee.shared.initialize(language: "en")
    /// try await Tolgee.shared.remoteFetch()
    ///
    /// // Full configuration with CDN, language, and namespaces
    /// Tolgee.shared.initialize(
    ///     cdn: cdnURL,
    ///     language: "es",
    ///     namespaces: ["buttons", "messages", "errors"]
    /// )
    /// try await Tolgee.shared.remoteFetch()
    /// ```
    ///
    /// ## Language Detection
    /// When `language` is `nil`, the method:
    /// - Reads the user's preferred language from `Locale.preferredLanguages`
    /// - Extracts the language code (e.g., "es" from "es-ES")
    /// - Provides debug logging to show detected language
    /// - Falls back to "en" if detection fails
    ///
    /// ## Behavior
    /// - **Automatic language**: Respects user's device language settings
    /// - **Manual language**: Uses specified language regardless of device settings
    /// - **Caching**: Loads cached translations immediately if available
    /// - **Initialization guard**: Prevents multiple initializations (subsequent calls are ignored)
    ///
    /// - Note: For production apps, omit the `language` parameter to provide the best user experience.
    ///   Use explicit `language` values primarily for testing specific language scenarios.
    ///   After initialization, call `remoteFetch()` to update translations from the CDN.
    public func initialize(
        cdn: URL? = nil, language: String? = nil, namespaces: Set<String> = [],
        enableDebugLogs: Bool = false
    ) {

        guard !isInitialized else {
            logger.error("Tolgee is already initialized")
            return
        }

        logger.enableDebugLogs = enableDebugLogs

        let language = language ?? getPreferredLanguage()

        cdnURL = cdn
        self.language = language
        self.namespaces = namespaces

        // Track whether we found any cached data for this app version
        var foundAnyCache = false

        if let data = cache.loadRecords(
            for: CacheDescriptor(
                language: language, appVersionSignature: appVersionSignature,
                cdn: cdn?.absoluteString ?? ""))
        {
            foundAnyCache = true
            do {
                // Load cached translations
                let translations = try JSONParser.loadTranslations(from: data)
                self.translations[""] = translations
                logger.debug(
                    "Loaded cached translations for language: \(language) and base namespace"
                )
            } catch {
                logger.error("Failed to load cached translations: \(error)")
            }
        } else {
            logger.debug("No cached translations found for language: \(language)")
        }

        for namespace in namespaces {
            if let data = cache.loadRecords(
                for: CacheDescriptor(
                    language: language, namespace: namespace,
                    appVersionSignature: appVersionSignature, cdn: cdn?.absoluteString ?? ""))
            {
                foundAnyCache = true
                do {
                    // Load cached translations for each namespace
                    let translations = try JSONParser.loadTranslations(from: data)
                    self.translations[namespace] = translations
                    logger.debug(
                        "Loaded cached translations for language: \(language), namespace: \(namespace)"
                    )
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

        // If no cache was found for the current app version, clear all cache
        // This ensures we wipe cache files from old app versions
        if !foundAnyCache {
            do {
                try cache.clearAll()
                logger.debug("Cleared all cache since no cache found for current app version")
            } catch {
                logger.error("Failed to clear cache: \(error)")
            }
        }

        isInitialized = true
        onInitializedSubject.send(())
        logger.debug("Tolgee initialized with language: \(language), namespaces: \(namespaces)")
    }

    /// Fetches the latest translations from the CDN.
    ///
    /// This method explicitly fetches translations from the configured CDN URL for the current
    /// language and namespaces. It will update cached translations and notify observers when
    /// the fetch completes.
    ///
    /// The method performs the following operations:
    /// - Constructs file paths for all required translation files
    /// - Fetches translation data from the CDN
    /// - Processes and caches the fetched translations
    /// - Updates the `lastFetchDate` property
    /// - Sends notifications via `onTranslationsUpdated`
    ///
    /// ## Usage
    /// ```swift
    /// // Initialize Tolgee first
    /// Tolgee.shared.initialize(cdn: cdnURL, language: "en")
    ///
    /// // Explicitly fetch latest translations
    /// try await Tolgee.shared.remoteFetch()
    ///
    /// // With error handling
    /// do {
    ///     try await Tolgee.shared.remoteFetch()
    /// } catch {
    ///     print("Failed to fetch translations: \(error)")
    /// }
    /// ```
    ///
    /// - Throws: An error if the fetch operation fails
    /// - Note: This method requires that Tolgee has been initialized with a CDN URL and language.
    ///   The method will return early if these prerequisites are not met.
    public func remoteFetch() async throws {
        guard let cdnURL, let language, language.isEmpty == false else {
            return
        }

        logger.debug(
            String(
                "Fetching translations from CDN for language: \(language), namespaces: \(namespaces)"
            ))

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
        for (filePath, result) in translationData {

            let data = result.0
            guard let response = result.1 as? HTTPURLResponse else {
                logger.error(
                    "Invalid response for file path: \(filePath). It's not an HTTP response.")
                continue
            }

            // Determine the table name from the file path
            let table: String
            if filePath == "\(language).json" {
                table = ""  // Base table
            } else {
                // Extract table name from "table/language.json" format
                table = String(filePath.prefix(while: { $0 != "/" }))
            }

            do {

                if response.statusCode == 304 {
                    logger.debug(
                        "No changes for table '\(table)' (304 status code), skipping update")
                    continue
                } else if response.statusCode != 200 {
                    logger.error(
                        "Failed to fetch translations for table '\(table)': HTTP \(response.statusCode)"
                    )
                    continue
                }

                let translations = try JSONParser.loadTranslations(from: data)

                if self.translations[table] == translations {
                    logger.debug("Translations for table '\(table)' are already up-to-date")
                    continue
                }

                self.translations[table] = translations

                // Cache the fetched data
                let descriptor: CacheDescriptor
                if table.isEmpty {
                    descriptor = CacheDescriptor(
                        language: language, appVersionSignature: self.appVersionSignature,
                        cdn: cdnURL.absoluteString)
                } else {
                    descriptor = CacheDescriptor(
                        language: language, namespace: table,
                        appVersionSignature: self.appVersionSignature,
                        cdn: cdnURL.absoluteString)
                }

                do {
                    try self.cache.saveRecords(data, for: descriptor)
                } catch {
                    self.logger.error("Failed to save translations to cache: \(error)")
                }

                if let etag = response.allHeaderFields["Etag"] as? String {
                    let etagDescriptor: CdnEtagDescriptor
                    if table.isEmpty {
                        etagDescriptor = CdnEtagDescriptor(
                            language: language,
                            cdn: cdnURL.absoluteString)
                    } else {
                        etagDescriptor = CdnEtagDescriptor(
                            language: language, namespace: table,
                            cdn: cdnURL.absoluteString)
                    }
                    try self.cache.saveCdnEtag(etagDescriptor, etag: etag)
                } else {
                    self.logger.warning(
                        "No etag header found for \(cdnURL.appending(component: filePath))")
                }

                logger.debug(
                    "Cached translations for language: \(language), namespace: \(table.isEmpty ? "base" : table)"
                )
            } catch {
                logger.error("Error loading translations for table '\(table)': \(error)")
            }
        }

        lastFetchDate = Date()
        onTranslationsUpdatedSubject.send(())
        logger.debug(
            "Translations fetched successfully at \(self.lastFetchDate ?? .distantPast)")
    }

    func loadTranslations(from jsonString: String, table: String = "") throws {

        guard let data = jsonString.data(using: .utf8) else {
            throw TolgeeError.invalidJSONString
        }

        let translations = try JSONParser.loadTranslations(from: data)
        self.translations[table] = translations
    }

    func loadTranslations(from jsonData: Data, table: String = "") throws {
        let translations = try JSONParser.loadTranslations(from: jsonData)
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
    public func translate(
        _ key: String, _ arguments: CVarArg..., table: String? = nil, bundle: Bundle = .main
    )
        -> String
    {
        let locale = Locale.current

        // First try to get translation from loaded translations
        if let translationEntry = translations[table ?? ""]?[key] {
            switch translationEntry {
            case .simple(let string):
                // If we have arguments, try to format the string
                if !arguments.isEmpty {
                    return String(format: string, locale: locale, arguments: arguments)
                }
                return string
            case .plural(let variants):
                let pluralRules = PluralRules(for: locale)
                if let number = arguments.compactMap({ $0 as? NSNumber }).first {
                    switch pluralRules.category(for: number.doubleValue) {
                    case .zero:
                        if let string = variants.zero {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .one:
                        if let string = variants.one {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .two:
                        if let string = variants.two {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .few:
                        if let string = variants.few {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .many:
                        if let string = variants.many {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .other:
                        if let string = variants.other {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    }
                }
            }
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
            switch translationEntry {
            case .simple(let string):
                // If we have arguments, try to format the string
                if !arguments.isEmpty {
                    return String(format: string, locale: locale, arguments: arguments)
                }
                return string
            case .plural(let variants):
                let pluralRules = PluralRules(for: locale)
                if let number = arguments.compactMap({ $0 as? NSNumber }).first {
                    switch pluralRules.category(for: number.doubleValue) {
                    case .zero:
                        if let string = variants.zero {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .one:
                        if let string = variants.one {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .two:
                        if let string = variants.two {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .few:
                        if let string = variants.few {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .many:
                        if let string = variants.many {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .other:
                        if let string = variants.other {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    }
                }
            }
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

    /// Clears all cached translations and ETag data.
    ///
    /// This method removes all cached files from the local cache,
    /// forcing fresh downloads on the next `remoteFetch()` call.
    ///
    /// - Throws: An error if the cache clearing operation fails.
    public func clearCaches() throws {
        try cache.clearAll()
        logger.debug("Successfully cleared all cached translations and ETag data")
    }
}
