import Foundation

@objc(WMFEventCapsule)
class EventCapsule : NSObject, NSCoding {
    
    var event: Dictionary<String, Any>
    var schema: String
    var revision: Int
    var wiki: String
    
    public init(event: Dictionary<String, Any>, schema: String, revision: Int, wiki: String) {
        self.event = event
        self.schema = schema
        self.revision = revision
        self.wiki = wiki
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let schema = aDecoder.decodeObject(forKey: "schema") as? String,
              let wiki = aDecoder.decodeObject(forKey: "wiki") as? String,
              let event = aDecoder.decodeObject(forKey: "event") as? Dictionary<String, Any> else {
                return nil
        }
        
        let revision = aDecoder.decodeInt32(forKey: "revision")
        self.init(event: event, schema: schema, revision: Int(revision), wiki: wiki)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(event, forKey: "event")
        aCoder.encode(schema, forKey: "schema")
        aCoder.encode(schema, forKey: "wiki")
        aCoder.encode(revision, forKey: "revision")
    }
}
