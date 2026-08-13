import Foundation

/// Parses the URL the web Visual Editor uses to hand the user back to the app after publishing or abandoning an edit, e.g.
/// `wikipedia://en.wikipedia.org/wiki/Cat?saved=true&revision=12345`.
/// Also recognizes a return mid-edit through Safari's native app banner, where the
/// incoming URL is the editing URL itself (`?veaction=edit&returntoapp=1`).
struct VisualEditorReturnJourney {

    /// Whether the edit was published (`saved=true`) or abandoned (`saved=false`).
    let saved: Bool

    /// The newly published revision, when the web included one. Always nil for abandoned edits.
    let revisionID: UInt64?

    /// The article URL with the return journey query items stripped.
    let articleURL: URL

    private static let savedQueryItemName = "saved"
    private static let revisionQueryItemName = "revision"
    private static let visualEditorActionQueryItemName = "veaction"
    private static let returnToAppQueryItemName = "returntoapp"
    private static let sectionQueryItemName = "section"
    private static let useFormatQueryItemName = "useformat"

    init?(url: URL) {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }

        let savedValue = queryItems.first(where: { $0.name == Self.savedQueryItemName })?.value
        let revisionValue = queryItems.first(where: { $0.name == Self.revisionQueryItemName })?.value
        let revisionID = revisionValue.flatMap { UInt64($0) }

        let isEditingContext = queryItems.contains { $0.name == Self.visualEditorActionQueryItemName || $0.name == Self.returnToAppQueryItemName }

        let saved: Bool
        switch savedValue?.lowercased() {
        case "true", "1":
            saved = true
        case "false", "0":
            saved = false
        default:
            if revisionID != nil {
                // Treat a revision with a missing or malformed saved value as a publish,
                // since the web only knows the new revision after saving.
                saved = true
            } else if isEditingContext {
                // The editing URL itself came back (e.g. Safari's native app banner tapped
                // mid-edit), so nothing was published.
                saved = false
            } else {
                return nil
            }
        }

        let visualEditorQueryItemNames: Set<String> = [
            Self.savedQueryItemName,
            Self.revisionQueryItemName,
            Self.visualEditorActionQueryItemName,
            Self.returnToAppQueryItemName,
            Self.sectionQueryItemName,
            Self.useFormatQueryItemName
        ]

        let remainingQueryItems = queryItems.filter { !visualEditorQueryItemNames.contains($0.name) }
        components.queryItems = remainingQueryItems.isEmpty ? nil : remainingQueryItems

        guard let articleURL = components.url else { return nil }

        self.saved = saved
        self.revisionID = saved ? revisionID : nil
        self.articleURL = articleURL
    }
}
