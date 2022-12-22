import Foundation

struct Link {
    let page: String
    let label: String?
    let exists: Bool

    init?(page: String?, label: String?, exists: Bool?) {
        guard let page = page else {
            assertionFailure("Attempting to create a Link without a page")
            return nil
        }
        guard let exists = exists else {
            assertionFailure("Attempting to create a Link without information about whether it's an existing link")
            return nil
        }
        self.page = page
        self.label = label
        self.exists = exists
    }

    var hasLabel: Bool {
        return label != nil
    }

    func articleURL(for siteURL: URL) -> URL? {
        guard exists else {
            return nil
        }
        return siteURL.wmf_URL(withTitle: page)
    }
}

