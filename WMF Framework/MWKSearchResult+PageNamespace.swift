import Foundation

extension MWKSearchResult {
    public var pageNamespace: PageNamespace? {
        return PageNamespace(namespaceValue: titleNamespace?.intValue)
    }
}
