/// PageUserScript uses the platform-appropriate WKUserScript initializer to create a user script in WKContentWorld.page
class PageUserScript: WKUserScript {
    override init(source: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool) {
        if #available(iOS 14.0, *) {
            super.init(source: source, injectionTime: injectionTime, forMainFrameOnly: true, in: WKContentWorld.page)
        } else {
            super.init(source: source, injectionTime: injectionTime, forMainFrameOnly: true)
        }
    }
}
