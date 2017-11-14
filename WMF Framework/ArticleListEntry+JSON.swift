import Foundation

extension ArticleListEntry {
    func update(with json: [String: Any]) {
        if let listID = json["id"] as? Int64 {
            self.articleListEntryID = listID
        }
        
        if let project = json["project"] as? String {
            self.project = project
        }
        
        if let title = json["title"] as? String {
            self.title = title
        }
        
        if
            let project = self.project,
            let title = self.title,
            let url = NSURL.wmf_URL(withDomain: project, language: nil, title: title, fragment: nil)
        {
            self.articleKey = url.wmf_articleDatabaseKey
        }
        
        if let createdDate = json.wmf_iso8601DateValue(for: "created") {
            self.createdDate = createdDate as NSDate
        }
        
        if let updatedDate = json.wmf_iso8601DateValue(for: "updated") {
            self.updatedDate = updatedDate as NSDate
        }
    }
}

