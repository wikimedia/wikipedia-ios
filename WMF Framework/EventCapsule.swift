import Foundation

//@objc(WMFEventCapsule)
//
//
////typealias EventCapsule = Dictionary<String, Any>
//
//class EventCapsule : NSMutableDictionary {
//    
//    var event: Dictionary<String, Any>? {
//        get { return self.object(forKey: "event") as? Dictionary<String, Any> }
//        set { self.setObject(newValue ?? nil, forKey: "event" as NSString) }
//    }
//    var schema: String?
//    var revision: Int?
//    var wiki: String?
//    
////    public init(event: Dictionary<String, Any>, schema: String, revision: Int, wiki: String) {
////        self.event = event
////        self.schema = schema
////        self.revision = revision
////        self.wiki = wiki
////    }
////    
////    required convenience init(dictionaryLiteral elements: (Any, Any)...) {
////        fatalError("init(dictionaryLiteral:) has not been implemented")
////    }
////    
////    required convenience init(dictionaryLiteral elements: (Any, Any)...) {
////        fatalError("init(dictionaryLiteral:) has not been implemented")
////    }
//    
//}
////    required convenience init?(coder aDecoder: NSCoder) {
////        guard let schema = aDecoder.decodeObject(forKey: "schema") as? String,
////              let wiki = aDecoder.decodeObject(forKey: "wiki") as? String,
////              let event = aDecoder.decodeObject(forKey: "event") as? Dictionary<String, Any> else {
////                return nil
////        }
////        
////        let revision = aDecoder.decodeInt32(forKey: "revision")
////        self.init(event: event, schema: schema, revision: Int(revision), wiki: wiki)
////    }
////    
////    func encode(with aCoder: NSCoder) {
////        aCoder.encode(event, forKey: "event")
////        aCoder.encode(schema, forKey: "schema")
////        aCoder.encode(schema, forKey: "wiki")
////        aCoder.encode(revision, forKey: "revision")
////    }
////}


extension NSDictionary {
    
    @objc(wmf_eventCapsuleWithEvent:schema:revision:wiki:)
    public class func eventCapsule(event: Dictionary<String, Any>, schema: String, revision: Int, wiki: String) -> NSDictionary {
        let d: NSDictionary =
            ["event": event,
             "schema": schema,
             "revision": revision,
             "wiki": wiki]
        return d
        
    }
}
