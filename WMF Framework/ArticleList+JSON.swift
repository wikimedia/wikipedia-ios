import Foundation

extension ArticleList {
    func update(with json: [String: Any]) {
        if let listID = json["id"] as? Int64 {
            self.articleListID = listID
        }
        
        if let listName = json["name"] as? String {
            self.name = listName
        }
        
        if let listColor = json["color"] as? String {
            self.color = listColor
        }
        
        if let listImage = json["image"] as? String {
            self.imageName = listImage
        }
        
        if let listIcon = json["icon"] as? String {
            self.iconName = listIcon
        }
        
        if let createdDate = json.wmf_iso8601DateValue(for: "created") {
            self.createdDate = createdDate as NSDate
        }
        
        if let updatedDate = json.wmf_iso8601DateValue(for: "updated") {
            self.updatedDate = updatedDate as NSDate
        }
    }
}
