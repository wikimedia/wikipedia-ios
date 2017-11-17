import Foundation

extension ReadingListEntry {
    func update(with json: [String: Any]) {
        if let listID = json["id"] as? Int64 {
            self.readingListEntryID = NSNumber(value: listID)
        }

        if
            let project = json["project"] as? String,
            let title = json["title"] as? String,
            let url = NSURL.wmf_URL(withDomain: project, language: nil, title: title, fragment: nil)
        {
            self.displayTitle = url.wmf_title
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

