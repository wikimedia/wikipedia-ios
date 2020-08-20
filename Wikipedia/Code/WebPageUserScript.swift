/// PageUserScript uses the platform-appropriate WKUserScript initializer to create a user script in WKContentWorld.page
class PageUserScript: WKUserScript {
    override init(source: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool) {
        if #available(iOS 14.0, *) {
            // For some reason this crashes on iPadOS.
            // TODO: Revisit with later iOS 14 betas
            super.init(source: source, injectionTime: injectionTime, forMainFrameOnly: true, in: WKContentWorld.page)
        } else {
            super.init(source: source, injectionTime: injectionTime, forMainFrameOnly: true)
        }
    }
}
