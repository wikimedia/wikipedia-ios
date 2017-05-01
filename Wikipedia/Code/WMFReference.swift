
@objc class WMFReference: NSObject {
    
    let html:String
    let refId:String
    let rect:CGRect
    let text:String
    
    init(html:String, refId:String, rect:CGRect, text:String) {
        self.html = html
        self.refId = refId
        self.rect = rect
        self.text = text
        super.init()
    }
    
    convenience init?(scriptMessageDict: NSDictionary) {
        guard let rectDict = scriptMessageDict["rect"] as? NSDictionary, let rect =  CGRect.init(dictionaryRepresentation:rectDict) else {
            assertionFailure("'CGRectMakeWithDictionaryRepresentation' failed or Expected 'rect' dictionary not found in 'scriptMessageDict'")
            return nil
        }
        
        var htmlString = ""
        if let html = scriptMessageDict["html"] as? String {
            htmlString = html
        }else{
            assertionFailure("Expected 'html' string not found in 'scriptMessageDict'")
        }

        var refIdString = ""
        if let refId = scriptMessageDict["id"] as? String {
            refIdString = refId
        }else{
            assertionFailure("Expected 'id' string not found in 'scriptMessageDict'")
        }

        var textString = ""
        if let text = scriptMessageDict["text"] as? String {
            textString = text
        }else{
            assertionFailure("Expected 'text' string not found in 'scriptMessageDict'")
        }
        
        self.init(html:htmlString, refId:refIdString, rect:rect, text:textString)
    }
}
