import Foundation
import OSLog

public enum TolgeeError: Error {
    case invalidJSONString
    case translationNotFound
}
@MainActor
public final class Tolgee {
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
    private let lifecycleObserver: AppLifecycleObserver

    /// Internal initializer for testing with custom URL session, cache, and lifecycle observer
    /// - Parameters:
    ///   - urlSession: Custom URL session for testing
    ///   - cache: Custom cache implementation for testing
    ///   - lifecycleObserver: Custom lifecycle observer for testing
    internal init(
        urlSession: URLSessionProtocol, cache: CacheProcotol,
        lifecycleObserver: AppLifecycleObserver = AppLifecycleObserver()
    ) {
        self.fetchCdnService = FetchCdnService(urlSession: urlSession)
        self.cache = cache
        self.lifecycleObserver = lifecycleObserver
        setupForegroundObserver()
    }

    deinit {
        lifecycleObserver.stopObserving(target: self)
    }

    private func setupForegroundObserver() {
        lifecycleObserver.startObserving(target: self, selector: #selector(appWillEnterForeground))
    }

    @objc private func appWillEnterForeground() {
        logger.debug("App entering foreground, triggering translation fetch")
        fetch()
    }

    public func initialize(cdn: URL? = nil, language: String, namespaces: Set<String> = []) {
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
                            self.cache.saveRecords(data, for: descriptor)
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
        }
    }

    /// Load translations from JSON string (primarily for testing)
    /// - Parameters:
    ///   - jsonString: The JSON string containing translations
    ///   - table: The table name for the translations (defaults to base table)
    /// - Throws: Error if JSON parsing fails
    public func loadTranslations(from jsonString: String, table: String = "") throws {
        let translations = try JSONParser.loadTranslations(from: jsonString, table: table)
        self.translations[table] = translations
    }

    /// Load translations from JSON data (primarily for testing)
    /// - Parameters:
    ///   - jsonData: The JSON data containing translations
    ///   - table: The table name for the translations (defaults to base table)
    /// - Throws: Error if JSON parsing fails
    public func loadTranslations(from jsonData: Data, table: String = "") throws {
        let translations = try JSONParser.loadTranslations(from: jsonData, table: table)
        self.translations[table] = translations
    }

    public func translate(
        _ key: String, value: String? = nil, table: String? = nil, bundle: Bundle = .main
    ) -> String {
        // First try to get translation from loaded translations
        if let translationEntry = translations[table ?? ""]?[key] {
            switch translationEntry {
            case .simple(let string):
                return string
            case .plural(let pluralVariants):
                // For simple translation without arguments, return the "other" form
                return pluralVariants.other
            }
        }

        return bundle.localizedString(forKey: key, value: value, table: table)
    }

    @available(iOS 18.4, *)
    @available(macOS 15.4, *)
    public func translate(
        _ key: String, value: String? = nil, table: String? = nil, bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        // First try to get translation from loaded translations
        if let translationEntry = translations[table ?? ""]?[key] {
            switch translationEntry {
            case .simple(let string):
                return string
            case .plural(let pluralVariants):
                // For simple translation without arguments, return the "other" form
                return pluralVariants.other
            }
        }

        return bundle.localizedString(
            forKey: key, value: value, table: table, localizations: [locale.language])
    }

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
