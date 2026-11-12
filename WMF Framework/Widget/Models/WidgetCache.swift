import Foundation

public struct WidgetCache: Codable {

	// MARK: - Properties

	public var settings: WidgetSettings
	public var featuredContent: WidgetFeaturedContent?

    /// What happened on the last featured content fetch, for the developer settings screen.
    /// Widgets have no logs a person can read, so this is the only trace of a bad day.
    public var lastFetchDiagnostics: WidgetFetchDiagnostics?

	// MARK: - Public

	public init(settings: WidgetSettings, featuredContent: WidgetFeaturedContent?, lastFetchDiagnostics: WidgetFetchDiagnostics? = nil) {
		self.settings = settings
		self.featuredContent = featuredContent
        self.lastFetchDiagnostics = lastFetchDiagnostics
	}

}

public struct WidgetFetchDiagnostics: Codable {

    // MARK: - Nested Types

    public enum Outcome: String, Codable {
        case success
        case partialSuccess
        case decodeFailure
        case networkFailure
    }

    // MARK: - Properties

    public var date: Date
    public var url: String
    public var outcome: Outcome
    public var httpStatusCode: Int?
    public var errorDescription: String?
    /// Sections present in the decoded content, by JSON key.
    public var decodedSections: [String]
    /// Sections that failed to decode, by JSON key, with the error.
    public var sectionErrors: [String: String]
    /// Elements dropped inside a section, by JSON key.
    public var droppedElementErrors: [String: [String]]
    /// True when the widgets were served the previous cache because of this outcome.
    public var servedFromCacheFallback: Bool

    // MARK: - Public

    public init(date: Date, url: String, outcome: Outcome, httpStatusCode: Int? = nil, errorDescription: String? = nil, decodedSections: [String] = [], sectionErrors: [String: String] = [:], droppedElementErrors: [String: [String]] = [:], servedFromCacheFallback: Bool = false) {
        self.date = date
        self.url = url
        self.outcome = outcome
        self.httpStatusCode = httpStatusCode
        self.errorDescription = errorDescription
        self.decodedSections = decodedSections
        self.sectionErrors = sectionErrors
        self.droppedElementErrors = droppedElementErrors
        self.servedFromCacheFallback = servedFromCacheFallback
    }

    public init(date: Date, url: String, httpStatusCode: Int?, content: WidgetFeaturedContent) {
        let sectionErrors = Dictionary(uniqueKeysWithValues: content.sectionDecodingErrors.map { ($0.key.rawValue, $0.value) })
        let droppedElementErrors = Dictionary(uniqueKeysWithValues: content.droppedElementErrors.map { ($0.key.rawValue, $0.value) })
        let decodedSections = WidgetFeaturedContent.Section.allCases.filter { content.hasContent(for: $0) }.map { $0.rawValue }
        let isClean = sectionErrors.isEmpty && droppedElementErrors.isEmpty
        self.init(date: date, url: url, outcome: isClean ? .success : .partialSuccess, httpStatusCode: httpStatusCode, errorDescription: nil, decodedSections: decodedSections, sectionErrors: sectionErrors, droppedElementErrors: droppedElementErrors)
    }

    /// Human-readable lines for the developer settings screen.
    public var summaryLines: [String] {
        var lines: [String] = []
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        lines.append("\(formatter.string(from: date)) — \(outcome.rawValue)" + (httpStatusCode.map { " (HTTP \($0))" } ?? ""))
        lines.append(url)
        if let errorDescription = errorDescription {
            lines.append("Error: \(errorDescription)")
        }
        lines.append("Decoded: " + (decodedSections.isEmpty ? "nothing" : decodedSections.joined(separator: ", ")))
        for (section, error) in sectionErrors.sorted(by: { $0.key < $1.key }) {
            lines.append("\(section): \(error)")
        }
        for (section, errors) in droppedElementErrors.sorted(by: { $0.key < $1.key }) {
            lines.append("\(section) dropped \(errors.count): " + errors.joined(separator: "; "))
        }
        if servedFromCacheFallback {
            lines.append("Widgets are showing the previous cache.")
        }
        return lines
    }

}
