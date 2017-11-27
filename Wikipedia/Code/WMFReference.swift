
@objc class WMFReference: NSObject {
    
    @objc let html:String
    @objc let refId:String
    @objc let rect:CGRect
    @objc let text:String
    
    @objc init(html:String, refId:String, rect:CGRect, text:String) {
        self.html = html
        self.refId = refId
        self.rect = rect
        self.text = text
        super.init()
    }
    
    @objc convenience init?(scriptMessageDict: NSDictionary, yOffset: CGFloat) {
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
        
        self.init(html:htmlString, refId:refIdString, rect:rect.offsetBy(dx: 0, dy: yOffset), text:textString)
    }
}
