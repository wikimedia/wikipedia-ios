public struct LegacyArticle {
    struct Section {
        let info: [String: Any]
        let html: String
        init?(sectionFolderURL: URL) {
            let sectionHTMLFileURL = sectionFolderURL.appendingPathComponent("Section.html")
            let sectionPlistFileURL = sectionFolderURL.appendingPathComponent("Section.plist")
            guard let htmlData = try? Data(contentsOf: sectionHTMLFileURL) else {
                return nil
            }
            guard let html = String(data: htmlData, encoding: .utf8) else {
                return nil
            }
            self.html = html
            guard let sectionInfo = NSDictionary(contentsOf: sectionPlistFileURL) as? [String: Any] else {
                return nil
            }
            self.info = sectionInfo
        }
    }
    let info: [String: Any]
    let sections: [Section]
    public init?(articleFolderURL: URL) {
        let articlePlistFileURL = articleFolderURL.appendingPathComponent("Article.plist")
        guard let articleInfo = NSDictionary(contentsOf: articlePlistFileURL) as? [String: Any] else {
            return nil
        }
        self.info = articleInfo
        let articleSectionsFolderURL = articleFolderURL.appendingPathComponent("sections")
        guard let sectionEnumerator = FileManager.default.enumerator(at: articleSectionsFolderURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants, errorHandler: { (fileURL, error) -> Bool in
            return true
        }) else {
            return nil
        }
        var sections: [Section] = []
        for item in sectionEnumerator {
            guard
                let sectionFolderURL = item as? URL,
                let section = Section(sectionFolderURL: sectionFolderURL)
            else {
                continue
            }
            sections.append(section)
        }
        self.sections = sections
    }
}
