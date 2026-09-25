import UIKit
import WMFData

@MainActor
public final class WMFSemanticSearchResultViewModel: ObservableObject, Identifiable {

    struct LocalizedStrings {
        let readInArticleTitle: String
        let contributorsFormat: String
        let referencesFormat: String
        let lastUpdatedFormat: String
    }

    public let result: WMFSemanticSearchResult
    public let project: WMFProject
    /// The passage as plain text, for VoiceOver.
    let passageText: String
    let localizedStrings: LocalizedStrings

    @Published private(set) var thumbnail: UIImage?
    @Published private(set) var attribution: WMFSemanticSearchAttribution?

    static let passageLineLimit = 8

    /// Opening quotation mark of the passage per search language. Design asked for the same
    /// marks as the Android app for now.
    private static let quotationMarksByLanguageCode = ["ja": "\u{300E}", "ar": "\u{275D}", "fr": "\u{00AB}"]
    private static let defaultQuotationMark = "\u{275D}"
    private static let quotationMarkTrailingPadding: CGFloat = 6
    /// Ink height of the mark relative to the ascender of the passage font.
    private static let quotationMarkHeightRatio: CGFloat = 0.85

    private var loadTask: Task<Void, Never>?
    private var cachedQuotationMarkImage: (fontSize: CGFloat, color: UIColor, image: UIImage)?

    public var id: Int {
        result.pageID
    }

    private let readInArticleAction: @MainActor @Sendable (WMFSemanticSearchResult) -> Void

    init(
        result: WMFSemanticSearchResult,
        project: WMFProject,
        localizedStrings: LocalizedStrings,
        readInArticleAction: @escaping @MainActor @Sendable (WMFSemanticSearchResult) -> Void
    ) {
        self.result = result
        self.project = project
        self.passageText = WMFSemanticSearchSnippet.plainText(html: result.snippetHTML)
        self.localizedStrings = localizedStrings
        self.readInArticleAction = readInArticleAction
    }

    func readInArticle() {
        readInArticleAction(result)
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Presentation

    var quotationMark: String {
        guard let languageCode = project.languageCode else {
            return Self.defaultQuotationMark
        }
        return Self.quotationMarksByLanguageCode[languageCode] ?? Self.defaultQuotationMark
    }

    var isRightToLeft: Bool {
        guard let languageCode = project.languageCode else {
            return false
        }
        return Locale.Language(identifier: languageCode).characterDirection == .rightToLeft
    }

    var articlePath: String {
        [result.title, result.sectionTitle]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " | ")
    }

    /// The quotation mark drawn a little shorter than the ascender of `font`, in an image as
    /// tall as the ascender, so it sits on the baseline and opens the passage without raising
    /// the first line.
    func quotationMarkImage(font: UIFont, color: UIColor) -> UIImage {
        if let cachedQuotationMarkImage, cachedQuotationMarkImage.fontSize == font.pointSize, cachedQuotationMarkImage.color == color {
            return cachedQuotationMarkImage.image
        }

        let lineHeight = font.ascender
        let inkHeight = lineHeight * Self.quotationMarkHeightRatio
        let probeFont = font.withSize(100)
        let probeLine = CTLineCreateWithAttributedString(NSAttributedString(string: quotationMark, attributes: [.font: probeFont]))
        let probeInk = CTLineGetBoundsWithOptions(probeLine, .useGlyphPathBounds)
        let scale = probeInk.height > 0 ? inkHeight / probeInk.height : 1
        let drawFont = probeFont.withSize(100 * scale)
        let drawLine = CTLineCreateWithAttributedString(NSAttributedString(string: quotationMark, attributes: [.font: drawFont]))
        let ink = CTLineGetBoundsWithOptions(drawLine, .useGlyphPathBounds)

        // The padding sits between the mark and the text: after the mark in LTR, before it in RTL.
        let leadingPadding = isRightToLeft ? Self.quotationMarkTrailingPadding : 0
        let size = CGSize(width: ceil(ink.width) + Self.quotationMarkTrailingPadding, height: lineHeight)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            let origin = CGPoint(x: leadingPadding - ink.minX, y: lineHeight - drawFont.ascender + ink.minY)
            (quotationMark as NSString).draw(at: origin, withAttributes: [.font: drawFont, .foregroundColor: color])
        }
        cachedQuotationMarkImage = (font.pointSize, color, image)
        return image
    }

    /// The passage styled like the article, as an indication only: highlight behind the answer,
    /// links in the link color, links inside the highlight underlined, reference markers as
    /// superscripts. Nothing is tappable; the reader taps the card to read in the article.
    func attributedPassage(font: UIFont, textColor: UIColor, highlightColor: UIColor, highlightTextColor: UIColor, linkColor: UIColor) -> AttributedString {
        AttributedString(WMFSemanticSearchSnippet.attributedString(
            html: result.snippetHTML,
            font: font,
            textColor: textColor,
            highlightColor: highlightColor,
            highlightTextColor: highlightTextColor,
            linkColor: linkColor))
    }

    var contributorsText: String? {
        guard let count = attribution?.contributorCount else { return nil }

        return String.localizedStringWithFormat(localizedStrings.contributorsFormat, count)
    }

    var referencesText: String? {
        guard let count = attribution?.referenceCount else { return nil }

        return String.localizedStringWithFormat(localizedStrings.referencesFormat, count)
    }

    /// Shown where the reference count is not available yet, as month and year, e.g. `09/2026`.
    var lastUpdatedText: String? {
        lastUpdatedDate.map { String.localizedStringWithFormat(localizedStrings.lastUpdatedFormat, DateFormatter.monthYearNumericFormatter.string(from: $0))
        }
    }

    /// The same month and year spelled out, so VoiceOver does not read the numeric form.
    var lastUpdatedAccessibilityText: String? {
        lastUpdatedDate.map { String.localizedStringWithFormat(localizedStrings.lastUpdatedFormat, DateFormatter.monthYearSpelledOutFormatter.string(from: $0))
        }
    }

    private var lastUpdatedDate: Date? {
        guard attribution?.referenceCount == nil else { return nil }

        return attribution?.lastUpdated
    }

    // MARK: - Loading

    func loadDetailsIfNeeded() {
        guard loadTask == nil else { return }

        loadTask = Task { [weak self] in
            guard let self else { return }

            async let thumbnail = loadThumbnail()
            async let attribution = loadAttribution()

            let (loadedThumbnail, loadedAttribution) = await (thumbnail, attribution)

            guard !Task.isCancelled else { return }

            self.thumbnail = loadedThumbnail
            self.attribution = loadedAttribution
        }
    }

    private func loadThumbnail() async -> UIImage? {
        guard let thumbnailURL = result.thumbnailURL,
              let data = try? await WMFImageDataController.shared.fetchImageData(url: thumbnailURL)
        else { return nil }

        return UIImage(data: data)
    }

    private func loadAttribution() async -> WMFSemanticSearchAttribution? {
        try? await WMFSemanticSearchDataController.shared.fetchAttribution(title: result.title, project: project)
    }
}
