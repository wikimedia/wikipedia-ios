class PageUserScript: WKUserScript {
    override init(source: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool) {
        if #available(iOS 14.0, *) {
            super.init(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true, in: WKContentWorld.page)
        } else {
            super.init(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        }
    }
}
