import Foundation

struct EventCapsule {
    
    let event: Dictionary<String, Any>
    let schema: String
    let revision: Int
    let wiki: String
    
    public init(event: Dictionary<String, Any>, schema: String, revision: Int, wiki: String) {
        self.event = event
        self.schema = schema
        self.revision = revision
        self.wiki = wiki
    }
}
