import WMFData

public final class WMFFeedDidYouKnowFetcher: Fetcher {
    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore

    private func cachedFileName(for siteURL: URL) -> String {
        let host = siteURL.host ?? ""

        let fileNamePrefix: String
        if let languageVariantCode = siteURL.wmf_languageVariantCode {
            fileNamePrefix = "\(host)-\(languageVariantCode)"
        } else {
            fileNamePrefix = host
        }

        let unencodedFileName = "\(fileNamePrefix)"
        return unencodedFileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? unencodedFileName
    }

}
