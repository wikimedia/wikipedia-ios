/// Legacy reference class for handling references passed across the JavaScript Bridge
/// Ideally this would be merged with the Reference struct in References.swift
@objc class WMFLegacyReference: NSObject {
    
    @objc var html: String
    let anchor: String
    @objc let refId: String
    @objc let rect: CGRect
    @objc let text: String
    
    @objc init(html: String, refId: String, anchor: String, rect: CGRect, text: String) {
        self.html = html
        self.refId = refId
        self.anchor = anchor
        self.rect = rect
        self.text = text
        super.init()
    }
    
    @objc convenience init?(scriptMessageDict: [String: Any]) {
        guard
            let rectDict = scriptMessageDict["rect"] as? [String: Double],
            let x = rectDict["x"],
            let y = rectDict["y"],
            let width = rectDict["width"],
            let height = rectDict["height"]
        else {
            assertionFailure("Expected 'rect' dictionary not found in 'scriptMessageDict'")
            return nil
        }
        let rect = CGRect(x: x, y: y, width: width, height: height)
        
        var htmlString = ""
        if let html = scriptMessageDict["html"] as? String {
            htmlString = html
        } else {
            assertionFailure("Expected 'html' string not found in 'scriptMessageDict'")
        }

        var refIdString = ""
        if let refId = scriptMessageDict["id"] as? String {
            refIdString = refId
        } else {
            assertionFailure("Expected 'id' string not found in 'scriptMessageDict'")
        }

        var textString = ""
        if let text = scriptMessageDict["text"] as? String {
            textString = text
        } else {
            assertionFailure("Expected 'text' string not found in 'scriptMessageDict'")
        }
        
        var anchor = ""
        if let href = scriptMessageDict["href"] as? String {
            anchor = URL(string: href)?.fragment ?? ""
        } else {
            assertionFailure("Expected 'href' string not found in 'scriptMessageDict'")
        }
        
        self.init(html:htmlString, refId:refIdString, anchor: anchor, rect:rect, text:textString)
    }
}
