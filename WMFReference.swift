
@objc class WMFReference: NSObject {
    
    var html:String? = ""
    var refId:String? = ""
    var rect:CGRect = CGRectZero
    var text:String? = ""
    
    init(html:String, refId:String, rect:CGRect, text:String) {
        super.init()
        self.html = html
        self.refId = refId
        self.rect = rect
        self.text = text
    }
    
    override init() {
        super.init()
    }

    convenience init(scriptMessageDict: NSDictionary) {
        var rect = CGRectZero
        guard
            let html = scriptMessageDict["html"] as? String,
            let refId = scriptMessageDict["id"] as? String,
            let text = scriptMessageDict["text"] as? String,
            let rectDict = scriptMessageDict["rect"] where
            CGRectMakeWithDictionaryRepresentation(rectDict as! CFDictionary, &rect) == true else {
                assert(false, "Expected keys not present in 'scriptMessageDict'")
                self.init()
        }
        self.init(html:html, refId:refId, rect:rect, text:text)
    }
}
