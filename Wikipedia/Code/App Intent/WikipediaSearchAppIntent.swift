import AppIntents

@available(iOS 16.0, *)
struct WikipediaSearchAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Wikipedia"
    static var description = IntentDescription("Search for articles on Wikipedia")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Search Term", description: "What would you like to search for on Wikipedia?")
    var searchTerm: String?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Search Wikipedia for \(\.$searchTerm)")
    }
    
    func perform() async throws -> some IntentResult {
        guard let searchTerm = searchTerm?.trimmingCharacters(in: .whitespacesAndNewlines), !searchTerm.isEmpty else {
            
            let searchURL = URL(string: "wikipedia://search")!
            await MainActor.run {
                UIApplication.shared.open(searchURL)
            }
            return .result()
        }
        
        var components = URLComponents(string: "wikipedia://search")!
        components.queryItems = [URLQueryItem(name: "q", value: searchTerm)]
        
        let searchURL = components.url ?? URL(string: "wikipedia://search")!
        
        await MainActor.run {
            UIApplication.shared.open(searchURL)
        }
        
        return .result()
    }
}

// MARK: - App Shortcuts Provider

@available(iOS 16.0, *)
struct WikipediaAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: WikipediaSearchAppIntent(),
            phrases: [
                "Search Wikipedia",
                "Search \(.applicationName)",
                "Look up on Wikipedia",
                "Find on Wikipedia"
            ],
            shortTitle: "Search Wikipedia",
            systemImageName: "magnifyingglass"
        )
    }
}
