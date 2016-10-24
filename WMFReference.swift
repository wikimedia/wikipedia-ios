
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
            let html = scriptMessageDict["html"],
            let refId = scriptMessageDict["id"],
            let text = scriptMessageDict["text"],
            let rectDict = scriptMessageDict["rect"] where
            CGRectMakeWithDictionaryRepresentation(rectDict as! CFDictionary, &rect) == true else {
                assert(false, "Expected keys not present in 'scriptMessageDict'")
                self.init()
        }
        self.init(html:html as! String, refId:refId as! String, rect:rect, text:text as! String)
    }
}
