extension ArticleViewController {
    #if DEBUG
    // Debug-only shake to clear cache
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else {
            return
        }
        Session.clearTemporaryCache()
        showError(NSError(domain: "org.wikimedia", code: 49, userInfo: [NSLocalizedDescriptionKey: "Cache cleared"]))
    }
    #endif
}
