import WMF
import WMFData
import CocoaLumberjackSwift

extension ArticleViewController {
    func saveCategories(categories: [String], articleTitle: String, project: WMFProject) {
        let cleanedCategories = removeNamespaceFromCategoryTitles(titles: categories)
        guard !cleanedCategories.isEmpty else { return }
        Task {
            do {
                try await WMFCategoriesDataController().addCategories(categories: cleanedCategories, articleTitle: articleTitle, project: project)
            } catch {
                DDLogError("Error saving article categories: \(error)")
            }
        }
    }
    
    private func removeNamespaceFromCategoryTitles(titles: [String]) -> [String] {
        guard let categoryNamespace = PageNamespace.init(rawValue: 14),
              let languageCode = articleURL.wmf_languageCode else {
            return []
        }
        
        var prefix: String?
        guard let lookup = WikipediaURLTranslations.lookupTable(for: languageCode) else {
            return []
        }
        
        for (namespaceTitle, namespaceID) in lookup.namespace {
            if namespaceID == PageNamespace.category {
                prefix = namespaceTitle
                break
            }
        }
        
        if let prefix {
            return titles.map {
                $0.replacingOccurrences(of: "^\(NSRegularExpression.escapedPattern(for: prefix)):", with: "")
            }
        } else {
            return titles
        }
    }
}

private extension String {
    func replacingOccurrences(
        of pattern: String,
        with replacement: String,
        options: NSRegularExpression.Options = [.caseInsensitive]
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return self
        }
        let range = NSRange(self.startIndex..., in: self)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replacement)
    }
}
