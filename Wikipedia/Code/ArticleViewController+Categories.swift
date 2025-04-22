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
        var finalTitles = titles
        guard let languageCode = articleURL.wmf_languageCode else {
            return []
        }
        
        guard let lookup = WikipediaURLTranslations.lookupTable(for: languageCode) else {
            return []
        }
        
        var namespacePrefixes: [String] = ["Category"]
        for (namespaceTitle, namespaceID) in lookup.namespace {
            if namespaceID == PageNamespace.category {
                namespacePrefixes.append(namespaceTitle)
            }
        }
        
        for prefix in namespacePrefixes {
            finalTitles = finalTitles.map {
                $0.replacingOccurrences(of: "^\(NSRegularExpression.escapedPattern(for: prefix)):", with: "")
            }
        }
        
        return finalTitles
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
