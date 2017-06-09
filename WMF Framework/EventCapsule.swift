import Foundation

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
