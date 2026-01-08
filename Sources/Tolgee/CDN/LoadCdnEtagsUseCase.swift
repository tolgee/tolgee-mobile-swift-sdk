import Foundation

final class LoadCdnEtagsUseCase: Sendable {
    private let language: String
    private let namespaces: Set<String>
    private let cdnURL: String
    private let cache: CacheProtocol

    init(
        language: String,
        namespaces: Set<String>,
        cdnURL: String,
        cache: CacheProtocol
    ) {
        self.language = language
        self.namespaces = namespaces
        self.cdnURL = cdnURL
        self.cache = cache
    }

    func callAsFunction() -> [String: String] {
        var etags: [String: String] = [:]

        if let etag = cache.loadCdnEtag(
            for: .init(language: language, cdn: cdnURL))
        {
            etags[""] = etag
        }

        for namespace in namespaces {
            if let etag = cache.loadCdnEtag(
                for: .init(
                    language: language, namespace: namespace,
                    cdn: cdnURL))
            {
                etags[namespace] = etag
            }
        }

        return etags
    }
}
