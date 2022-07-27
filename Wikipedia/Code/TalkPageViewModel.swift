import Foundation

final class TalkPageViewModel {

    // MARK: - Properties

    private let pageTitle: String
    private let siteURL: URL

    // MARK: - Lifecycle

    init(pageTitle: String, siteURL: URL) {
        self.pageTitle = pageTitle
        self.siteURL = siteURL
    }
    
    convenience init?(siteURL: URL) {
        guard let pageTitle = siteURL.wmf_title, let siteURL = siteURL.wmf_site else {
            return nil
        }

        self.init(pageTitle: pageTitle, siteURL: siteURL)
    }

    // MARK: - Public

}
