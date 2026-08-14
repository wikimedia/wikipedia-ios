import UIKit
import CocoaLumberjackSwift
import WMF
import WMFComponents
import WMFNativeLocalizations
import WMFVisualEditorKit

/// Spike playground for the native visual editor engine (WMFVisualEditorKit).
///
/// Fetches the article's Parsoid HTML — the exact document the web visual editor
/// edits — parses it through the native engine and renders the linear model
/// natively. Editing is live: every keystroke becomes a character-level
/// transaction against the linear model (with exact undo/redo); edits that would
/// touch structure or opaque nodes are rejected. No web view is involved at any
/// point. The info button shows the model inspector.
final class NativeVisualEditorPlaygroundViewController: ThemeableViewController, WMFNavigationBarConfiguring {

    // MARK: - Nested Types

    /// One applied edit, carrying what is needed to undo it exactly.
    private struct EditRecord {
        let insertedRange: Range<Int>
        let removedItems: [WMFVisualEditorLinearItem]
    }

    private struct RenderResult {
        let attributedString: NSAttributedString
        /// For every UTF-16 unit of the rendered string, the linear model index
        /// of the character it renders — nil for decorations (newlines, list
        /// prefixes, opaque node placeholders).
        let linearIndexByRenderedUTF16: [Int?]
        /// Image attachments awaiting their asynchronously loaded pictures.
        let imageLoads: [(attachment: NSTextAttachment, url: URL)]
    }

    // MARK: - Properties

    private let articleURL: URL
    /// Called after a successful publish with the new revision ID; the owner
    /// dismisses the editor and refreshes the article.
    private let didPublish: (UInt64?) -> Void

    private var document: WMFVisualEditorDocument?
    /// Revision and etag of the fetched Parsoid HTML — sent back with the
    /// html→wikitext transform so the server can run selective serialization
    /// (selser) against the exact base revision, keeping wikitext diffs clean.
    private var fetchedETag: String?
    private var fetchedRevisionID: String?
    private var editConfirmationSavedData: EditSaveViewController.SaveData?
    /// UTF-16 unit → linear model index map for the currently displayed text.
    /// Kept in sync incrementally on edits; rebuilt on full re-renders.
    private var renderedMap: [Int?] = []
    private var undoStack: [EditRecord] = []
    private var redoStack: [EditRecord] = []
    /// After a structural change (split/undo/redo) the caret may sit where only
    /// decorations render — e.g. inside a freshly created empty paragraph. The
    /// rendered map cannot resolve those positions, so the authoritative linear
    /// caret is remembered until the user moves the selection elsewhere.
    private var pendingCaretContext: (renderedLocation: Int, linearIndex: Int)?
    private var parseDuration: TimeInterval?
    private var loadTask: Task<Void, Never>?
    private var imageLoadTask: Task<Void, Never>?
    /// Last known status per image URL — surfaced in the model inspector so
    /// load failures are visible on screen, not just in logs.
    private var imageLoadStatuses: [String: String] = [:]

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.delegate = self
        textView.inputAccessoryView = formattingToolbar
        return textView
    }()

    private lazy var formattingToolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))

        func annotationItem(_ systemImageName: String, _ action: Selector, accessibilityLabel: String) -> UIBarButtonItem {
            let item = UIBarButtonItem(image: UIImage(systemName: systemImageName), style: .plain, target: self, action: action)
            item.accessibilityLabel = accessibilityLabel
            return item
        }

        toolbar.items = [
            annotationItem("bold", #selector(boldButtonTapped(_:)), accessibilityLabel: "Bold"),
            .flexibleSpace(),
            annotationItem("italic", #selector(italicButtonTapped(_:)), accessibilityLabel: "Italic"),
            .flexibleSpace(),
            annotationItem("link", #selector(linkButtonTapped(_:)), accessibilityLabel: "Link"),
            .flexibleSpace(),
            annotationItem("underline", #selector(underlineButtonTapped(_:)), accessibilityLabel: "Underline"),
            .flexibleSpace(),
            annotationItem("strikethrough", #selector(strikethroughButtonTapped(_:)), accessibilityLabel: "Strikethrough"),
            .flexibleSpace(),
            annotationItem("textformat.superscript", #selector(superscriptButtonTapped(_:)), accessibilityLabel: "Superscript"),
            .flexibleSpace(),
            annotationItem("textformat.subscript", #selector(subscriptButtonTapped(_:)), accessibilityLabel: "Subscript"),
            .flexibleSpace(),
            annotationItem("chevron.left.forwardslash.chevron.right", #selector(codeButtonTapped(_:)), accessibilityLabel: "Computer code")
        ]
        return toolbar
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        return activityIndicator
    }()

    // MARK: - Lifecycle

    init(articleURL: URL, theme: Theme, didPublish: @escaping (UInt64?) -> Void) {
        self.articleURL = articleURL
        self.didPublish = didPublish
        super.init(nibName: nil, bundle: nil)
        self.theme = theme
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        loadTask?.cancel()
        imageLoadTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(textView)
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        applyThemeColors()
        load()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        applyThemeColors()
        rerender(restoringCaretAtLinearIndex: nil)
    }

    private func applyThemeColors() {
        view.backgroundColor = theme.colors.paperBackground
        textView.backgroundColor = theme.colors.paperBackground
        activityIndicator.color = theme.colors.primaryText
    }

    // MARK: - Navigation Bar

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: "Native VE Playground", customView: nil, alignment: .centerCompact)

        var closeConfig: WMFLargeCloseButtonConfig?
        if navigationController?.viewControllers.first === self {
            closeConfig = WMFLargeCloseButtonConfig(imageType: .plainX, target: self, action: #selector(closeButtonTapped(_:)), alignment: .leading)
        }

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)

        let publishButton = UIBarButtonItem(title: CommonStrings.publishTitle, style: .done, target: self, action: #selector(publishButtonTapped(_:)))
        let inspectorButton = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: self, action: #selector(inspectorButtonTapped(_:)))
        inspectorButton.accessibilityLabel = "Model inspector"
        let redoButton = UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.forward"), style: .plain, target: self, action: #selector(redoButtonTapped(_:)))
        redoButton.accessibilityLabel = "Redo"
        let undoButton = UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.backward"), style: .plain, target: self, action: #selector(undoButtonTapped(_:)))
        undoButton.accessibilityLabel = "Undo"
        navigationItem.setRightBarButtonItems([publishButton, inspectorButton, redoButton, undoButton], animated: false)
    }

    // MARK: - Loading

    private func load() {
        guard let percentEncodedTitle = articleURL.wmf_title?.percentEncodedPageTitleForPathComponents,
              let baseParsoidHTMLURL = Configuration.current.pageContentServiceAPIURLForURL(articleURL, appending: ["page", "html", percentEncodedTitle]),
              var urlComponents = URLComponents(url: baseParsoidHTMLURL, resolvingAgainstBaseURL: false) else {
            showError(message: "Could not construct the Parsoid HTML URL for this article.")
            return
        }
        // stash=true keeps the original HTML server-side, keyed by the returned
        // etag — required for the html→wikitext transform to run selective
        // serialization (selser) and produce a clean wikitext diff on publish.
        urlComponents.queryItems = [URLQueryItem(name: "stash", value: "true")]
        guard let parsoidHTMLURL = urlComponents.url else {
            showError(message: "Could not construct the Parsoid HTML URL for this article.")
            return
        }

        activityIndicator.startAnimating()

        loadTask = Task { [weak self] in
            do {
                let (data, response) = try await URLSession.shared.data(from: parsoidHTMLURL)
                if let httpResponse = response as? HTTPURLResponse {
                    guard (200...299).contains(httpResponse.statusCode) else {
                        throw RequestError.http(httpResponse.statusCode)
                    }
                    // etag format: W/"123456/uuid" — the revision the HTML was
                    // rendered from, needed for clean selser on the way back.
                    if let etag = httpResponse.value(forHTTPHeaderField: "etag") {
                        self?.fetchedETag = etag
                        let trimmed = etag.replacingOccurrences(of: "W/", with: "").trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                        self?.fetchedRevisionID = trimmed.components(separatedBy: "/").first
                    }
                }
                guard let html = String(data: data, encoding: .utf8) else {
                    throw RequestError.invalidParameters
                }

                let parseStart = Date()
                let document = try WMFVisualEditorDocument.parse(parsoidHTML: html)
                let parseDuration = Date().timeIntervalSince(parseStart)

                guard let self, !Task.isCancelled else {
                    return
                }
                self.document = document
                self.parseDuration = parseDuration
                self.activityIndicator.stopAnimating()
                self.rerender(restoringCaretAtLinearIndex: nil)
            } catch {
                guard let self, !Task.isCancelled else {
                    return
                }
                self.activityIndicator.stopAnimating()
                DDLogError("NativeVisualEditorPlayground: failed to load or parse: \(error)")
                self.showError(message: "Failed to load or parse Parsoid HTML: \(error.localizedDescription)")
            }
        }
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Playground error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: CommonStrings.okTitle, style: .default))
        present(alert, animated: true)
    }

    // MARK: - Rendering

    private func rerender(restoringCaretAtLinearIndex caretLinearIndex: Int?) {
        guard let document else {
            return
        }
        let result = render(document: document)
        renderedMap = result.linearIndexByRenderedUTF16
        textView.attributedText = result.attributedString
        loadImages(result.imageLoads)
        if let caretLinearIndex {
            let location = renderedLocation(forLinearCaret: caretLinearIndex)
            let caretRange = NSRange(location: location, length: 0)
            pendingCaretContext = (renderedLocation: location, linearIndex: caretLinearIndex)
            textView.selectedRange = caretRange
            textView.scrollRangeToVisible(caretRange)
        }
    }

    /// Applies an edit to the displayed text surgically — the way native typing
    /// behaves — so scroll position and caret stay put, and updates the
    /// UTF-16 → linear map incrementally instead of re-rendering the document.
    private func applySurgicalRender(renderedRange: NSRange, replacementText: String, linearRange: Range<Int>, linearDelta: Int) {
        let storage = textView.textStorage

        var attributes: [NSAttributedString.Key: Any] = [:]
        if storage.length > 0 {
            let attributeLocation = min(max(renderedRange.location - 1, 0), storage.length - 1)
            attributes = storage.attributes(at: attributeLocation, effectiveRange: nil)
        }
        storage.replaceCharacters(in: renderedRange, with: NSAttributedString(string: replacementText, attributes: attributes))

        // Inserted characters occupy the first linear slots of the new slice.
        var insertedMapValues: [Int?] = []
        var linearIndex = linearRange.lowerBound
        for character in replacementText {
            insertedMapValues.append(contentsOf: Array(repeating: linearIndex, count: String(character).utf16.count))
            linearIndex += 1
        }
        renderedMap.replaceSubrange(renderedRange.location..<(renderedRange.location + renderedRange.length), with: insertedMapValues)
        if linearDelta != 0 {
            for index in renderedMap.indices {
                if let value = renderedMap[index], value >= linearRange.upperBound {
                    renderedMap[index] = value + linearDelta
                }
            }
        }

        textView.selectedRange = NSRange(location: renderedRange.location + (replacementText as NSString).length, length: 0)
    }

    /// Renders the linear model into an attributed string plus the UTF-16 →
    /// linear index map that editing relies on. Consecutive characters with
    /// identical annotations are coalesced into runs so rendering stays fast.
    private func render(document: WMFVisualEditorDocument) -> RenderResult {
        let output = NSMutableAttributedString()
        var map: [Int?] = []
        var imageLoads: [(attachment: NSTextAttachment, url: URL)] = []

        let bodyFont = WMFFont.for(.body, compatibleWith: traitCollection)
        let calloutFont = WMFFont.for(.callout, compatibleWith: traitCollection)
        let headingFonts: [Int: UIFont] = [
            1: WMFFont.for(.boldTitle1, compatibleWith: traitCollection),
            2: WMFFont.for(.boldTitle1, compatibleWith: traitCollection),
            3: WMFFont.for(.boldTitle3, compatibleWith: traitCollection)
        ]

        var blockFont = bodyFont
        var listItemPrefix: String?
        var orderedListCounter: Int?
        var pendingRun = ""
        var pendingRunLinearIndices: [Int?] = []
        var pendingAnnotations: [WMFVisualEditorAnnotation] = []

        func appendDecoration(_ string: String, font: UIFont, color: UIColor) {
            output.append(NSAttributedString(string: string, attributes: [.font: font, .foregroundColor: color]))
            map.append(contentsOf: Array(repeating: nil, count: (string as NSString).length))
        }

        func flushRun() {
            guard !pendingRun.isEmpty else {
                return
            }
            if let prefix = listItemPrefix {
                appendDecoration(prefix, font: blockFont, color: theme.colors.secondaryText)
                listItemPrefix = nil
            }

            var attributes: [NSAttributedString.Key: Any] = [
                .font: blockFont,
                .foregroundColor: theme.colors.primaryText
            ]
            var traits: UIFontDescriptor.SymbolicTraits = []
            var useMonospacedFont = false
            for annotation in pendingAnnotations {
                switch annotation.kind {
                case .bold:
                    traits.insert(.traitBold)
                case .italic:
                    traits.insert(.traitItalic)
                case .link:
                    attributes[.foregroundColor] = theme.colors.link
                    if let target = annotation.target,
                       let resolved = URL(string: target, relativeTo: articleURL) {
                        attributes[.link] = resolved.absoluteURL
                    }
                case .superscripted:
                    attributes[.baselineOffset] = blockFont.pointSize * 0.33
                case .subscripted:
                    attributes[.baselineOffset] = -blockFont.pointSize * 0.2
                case .strikethrough:
                    attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                case .underline:
                    attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                case .code:
                    useMonospacedFont = true
                }
            }
            var renderFont = blockFont
            if useMonospacedFont {
                renderFont = UIFont.monospacedSystemFont(ofSize: blockFont.pointSize * 0.9, weight: .regular)
            }
            if pendingAnnotations.contains(where: { $0.kind == .superscripted || $0.kind == .subscripted }) {
                renderFont = renderFont.withSize(renderFont.pointSize * 0.75)
            }
            if !traits.isEmpty, let descriptor = renderFont.fontDescriptor.withSymbolicTraits(renderFont.fontDescriptor.symbolicTraits.union(traits)) {
                renderFont = UIFont(descriptor: descriptor, size: renderFont.pointSize)
            }
            attributes[.font] = renderFont

            output.append(NSAttributedString(string: pendingRun, attributes: attributes))
            map.append(contentsOf: pendingRunLinearIndices)
            pendingRun = ""
            pendingRunLinearIndices = []
        }

        func appendOpaquePlaceholder(_ preservedContent: WMFParsoidNode?) {
            let rawText = preservedContent?.displayTextContent.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !rawText.isEmpty else {
                return
            }
            let collapsed = rawText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
            let excerpt = collapsed.count > 160 ? String(collapsed.prefix(160)) + "…" : collapsed
            appendDecoration("⧉ \(excerpt)\n\n", font: calloutFont, color: theme.colors.secondaryText)
        }

        for (linearIndex, item) in document.linearModel.enumerated() {
            switch item {
            case .character(let character, let annotations):
                if annotations != pendingAnnotations {
                    flushRun()
                    pendingAnnotations = annotations
                }
                pendingRun.append(character)
                pendingRunLinearIndices.append(contentsOf: Array(repeating: linearIndex, count: String(character).utf16.count))

            case .open(let type, let attributes, let preservedContent):
                flushRun()
                switch type {
                case "paragraph":
                    blockFont = bodyFont
                case "heading":
                    let level = Int(attributes["level"] ?? "2") ?? 2
                    blockFont = headingFonts[level] ?? headingFonts[3]!
                case "list":
                    orderedListCounter = attributes["style"] == "number" ? 1 : nil
                case "listItem":
                    blockFont = bodyFont
                    if let counter = orderedListCounter {
                        listItemPrefix = "\(counter). "
                        orderedListCounter = counter + 1
                    } else {
                        listItemPrefix = "•  "
                    }
                case "mwImage":
                    // Real image rendering: reserve correctly-sized space now,
                    // load the picture asynchronously. The attachment always
                    // carries an image (placeholder first) — TextKit must never
                    // see a nil-image attachment.
                    let attachment = NSTextAttachment()
                    let displayWidth: CGFloat = 260
                    var displayHeight: CGFloat = 180
                    if let widthString = attributes["width"], let heightString = attributes["height"],
                       let width = Double(widthString), let height = Double(heightString), width > 0 {
                        displayHeight = CGFloat(height / width) * displayWidth
                    }
                    let displaySize = CGSize(width: displayWidth, height: min(displayHeight, 340))
                    attachment.bounds = CGRect(origin: .zero, size: displaySize)
                    attachment.image = Self.placeholderImage(size: displaySize, color: theme.colors.midBackground)
                    output.append(NSAttributedString(attachment: attachment))
                    map.append(nil)
                    appendDecoration("\n", font: calloutFont, color: theme.colors.secondaryText)
                    if let caption = attributes["caption"], !caption.isEmpty {
                        appendDecoration("\(caption)\n\n", font: calloutFont, color: theme.colors.secondaryText)
                    } else {
                        appendDecoration("\n", font: bodyFont, color: theme.colors.primaryText)
                    }
                    if var source = attributes["src"] {
                        if source.hasPrefix("//") {
                            source = "https:" + source
                        }
                        if let url = URL(string: source) {
                            imageLoads.append((attachment, url))
                        }
                    }
                case "mwTransclusion", "alien":
                    appendOpaquePlaceholder(preservedContent)
                default:
                    break
                }

            case .close(let type):
                flushRun()
                switch type {
                case "paragraph", "heading":
                    appendDecoration("\n\n", font: bodyFont, color: theme.colors.primaryText)
                case "listItem":
                    appendDecoration("\n", font: bodyFont, color: theme.colors.primaryText)
                    listItemPrefix = nil
                case "list":
                    appendDecoration("\n", font: bodyFont, color: theme.colors.primaryText)
                    orderedListCounter = nil
                default:
                    break
                }
            }
        }
        flushRun()

        return RenderResult(attributedString: output, linearIndexByRenderedUTF16: map, imageLoads: imageLoads)
    }

    /// Sequential, staggered loading with retry: image servers rate-limit
    /// request bursts (observed 429s), so images load one at a time with a
    /// small gap and 429/failure backoff. A load finishing for an attachment
    /// that is no longer displayed is a no-op: repainting locates the
    /// attachment by identity.
    private func loadImages(_ imageLoads: [(attachment: NSTextAttachment, url: URL)]) {
        imageLoadTask?.cancel()
        imageLoadTask = Task { [weak self] in
            for (attachment, url) in imageLoads {
                guard !Task.isCancelled else {
                    return
                }
                await self?.loadSingleImage(attachment: attachment, url: url)
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
        }
    }

    private func loadSingleImage(attachment: NSTextAttachment, url: URL) async {
        var request = URLRequest(url: url)
        request.setValue("WikipediaApp-NativeVisualEditorSpike/1.0", forHTTPHeaderField: "User-Agent")

        for attempt in 1...3 {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    imageLoadStatuses[url.lastPathComponent] = "HTTP \(httpResponse.statusCode) (attempt \(attempt))"
                    try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_200_000_000)
                    continue
                }
                guard let image = UIImage(data: data) else {
                    imageLoadStatuses[url.lastPathComponent] = "undecodable (\(data.count) bytes)"
                    return
                }
                attachment.image = image
                repaintAttachment(attachment)
                imageLoadStatuses[url.lastPathComponent] = "ok"
                return
            } catch {
                imageLoadStatuses[url.lastPathComponent] = "\(error.localizedDescription) (attempt \(attempt))"
                try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_200_000_000)
            }
        }
        DDLogError("NativeVisualEditorPlayground: image load gave up for \(url): \(imageLoadStatuses[url.lastPathComponent] ?? "?")")
    }

    private static func placeholderImage(size: CGSize, color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// Repaints a single attachment in place (1:1 replacement — the rendered
    /// map and the scroll position are unaffected).
    private func repaintAttachment(_ attachment: NSTextAttachment) {
        let storage = textView.textStorage
        storage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: storage.length)) { value, range, stop in
            if let found = value as? NSTextAttachment, found === attachment {
                storage.replaceCharacters(in: range, with: NSAttributedString(attachment: attachment))
                stop.pointee = true
            }
        }
    }

    /// Rendered UTF-16 location for a caret sitting before the character at
    /// `caretLinearIndex` (or after the previous character when that exact
    /// index is not rendered, e.g. at the end of a paragraph).
    private func renderedLocation(forLinearCaret caretLinearIndex: Int) -> Int {
        if let location = renderedMap.firstIndex(where: { $0 == caretLinearIndex }) {
            return location
        }
        // After the last character before the caret (e.g. caret at end of block,
        // or at the start of a still-empty block created by a split)…
        if let location = renderedMap.lastIndex(where: { ($0 ?? Int.max) < caretLinearIndex }) {
            return location + 1
        }
        // …or before the next character after it.
        if let location = renderedMap.firstIndex(where: { ($0 ?? -1) > caretLinearIndex }) {
            return location
        }
        return 0
    }

    // MARK: - Editing

    /// Maps a rendered UTF-16 range to a linear model range. Invisible
    /// structure (spans, metas) interleaved with the characters is fine — the
    /// engine's structure-preserving edit flows around it. Returns nil only
    /// when the range touches rendered decorations (block boundaries, list
    /// prefixes, opaque placeholders), which are structural edits.
    private func linearRange(forRenderedRange renderedRange: NSRange) -> Range<Int>? {
        let map = renderedMap
        guard !map.isEmpty,
              renderedRange.location >= 0,
              renderedRange.location + renderedRange.length <= map.count else {
            return nil
        }

        if renderedRange.length == 0 {
            // Insertion point: the caret remembered from a structural change
            // wins when the map cannot resolve the position by itself.
            if let pending = pendingCaretContext, pending.renderedLocation == renderedRange.location {
                return pending.linearIndex..<pending.linearIndex
            }
            if renderedRange.location < map.count, let linearIndex = map[renderedRange.location] {
                return linearIndex..<linearIndex
            }
            if renderedRange.location > 0, let previousLinearIndex = map[renderedRange.location - 1] {
                return (previousLinearIndex + 1)..<(previousLinearIndex + 1)
            }
            return nil
        }

        let slice = map[renderedRange.location..<(renderedRange.location + renderedRange.length)]
        let indices = slice.compactMap { $0 }
        // Every rendered unit in the range must be a character; gaps in the
        // *linear* indices are invisible structure and are allowed.
        guard indices.count == slice.count, let first = indices.min(), let last = indices.max() else {
            return nil
        }
        return first..<(last + 1)
    }

    private func annotationsForInsertion(at linearIndex: Int) -> [WMFVisualEditorAnnotation] {
        guard let document, linearIndex > 0, linearIndex <= document.linearModel.count,
              case .character(_, let annotations) = document.linearModel[linearIndex - 1] else {
            return []
        }
        return annotations
    }

    /// Pressing Return: splits the enclosing block (paragraph, heading, list
    /// item) at the caret — a structural transaction, re-rendered fully.
    private func applySplit(atLinearIndex linearIndex: Int) {
        guard let document else {
            return
        }
        do {
            let (newDocument, insertedItems) = try document.splittingBlock(at: linearIndex)
            undoStack.append(EditRecord(insertedRange: linearIndex..<(linearIndex + insertedItems.count), removedItems: []))
            redoStack.removeAll()
            self.document = newDocument
            rerender(restoringCaretAtLinearIndex: linearIndex + insertedItems.count)
        } catch {
            DDLogWarn("NativeVisualEditorPlayground: rejected split: \(error)")
        }
    }

    private func applyEdit(renderedRange: NSRange, linearRange: Range<Int>, replacementText: String) -> Bool {
        guard let document else {
            return false
        }
        do {
            let annotations = annotationsForInsertion(at: linearRange.lowerBound)
            let (newDocument, removedSlice, newSliceCount) = try document.replacingCharactersPreservingStructure(in: linearRange, with: replacementText, annotations: annotations)
            undoStack.append(EditRecord(insertedRange: linearRange.lowerBound..<(linearRange.lowerBound + newSliceCount), removedItems: removedSlice))
            redoStack.removeAll()
            self.document = newDocument
            pendingCaretContext = nil
            applySurgicalRender(renderedRange: renderedRange, replacementText: replacementText, linearRange: linearRange, linearDelta: newSliceCount - linearRange.count)
            return true
        } catch {
            DDLogWarn("NativeVisualEditorPlayground: rejected edit: \(error)")
            return false
        }
    }

    // MARK: - Formatting

    private func selectedLinearRange() -> Range<Int>? {
        let selection = textView.selectedRange
        guard selection.length > 0 else {
            return nil
        }
        return linearRange(forRenderedRange: selection)
    }

    private func toggleAnnotation(kind: WMFVisualEditorAnnotation.Kind, target: String? = nil) {
        guard let document, let linearRange = selectedLinearRange() else {
            return
        }
        do {
            let (newDocument, removedItems) = try document.togglingAnnotation(kind: kind, target: target, in: linearRange)
            undoStack.append(EditRecord(insertedRange: linearRange, removedItems: removedItems))
            redoStack.removeAll()
            self.document = newDocument

            rerender(restoringCaretAtLinearIndex: nil)
            let start = renderedLocation(forLinearCaret: linearRange.lowerBound)
            let end = renderedLocation(forLinearCaret: linearRange.upperBound)
            let restoredSelection = NSRange(location: start, length: max(0, end - start))
            textView.selectedRange = restoredSelection
            textView.scrollRangeToVisible(restoredSelection)
        } catch {
            DDLogWarn("NativeVisualEditorPlayground: rejected annotation toggle: \(error)")
        }
    }

    @objc private func boldButtonTapped(_ sender: UIBarButtonItem) {
        toggleAnnotation(kind: .bold)
    }

    @objc private func italicButtonTapped(_ sender: UIBarButtonItem) {
        toggleAnnotation(kind: .italic)
    }

    @objc private func underlineButtonTapped(_ sender: UIBarButtonItem) {
        toggleAnnotation(kind: .underline)
    }

    @objc private func strikethroughButtonTapped(_ sender: UIBarButtonItem) {
        toggleAnnotation(kind: .strikethrough)
    }

    @objc private func superscriptButtonTapped(_ sender: UIBarButtonItem) {
        toggleAnnotation(kind: .superscripted)
    }

    @objc private func subscriptButtonTapped(_ sender: UIBarButtonItem) {
        toggleAnnotation(kind: .subscripted)
    }

    @objc private func codeButtonTapped(_ sender: UIBarButtonItem) {
        toggleAnnotation(kind: .code)
    }

    @objc private func linkButtonTapped(_ sender: UIBarButtonItem) {
        guard let document, let linearRange = selectedLinearRange() else {
            return
        }

        // If the whole selection is already linked, the button unlinks it.
        let selectionIsFullyLinked = document.linearModel[linearRange].allSatisfy { item in
            if case .character(_, let annotations) = item {
                return annotations.contains { $0.kind == .link }
            }
            return false
        }
        if selectionIsFullyLinked {
            toggleAnnotation(kind: .link)
            return
        }

        var selectedText = ""
        for item in document.linearModel[linearRange] {
            if case .character(let character, _) = item {
                selectedText.append(character)
            }
        }

        let alert = UIAlertController(title: "Link target", message: "Article title to link to", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = selectedText
        }
        alert.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel))
        alert.addAction(UIAlertAction(title: CommonStrings.doneTitle, style: .default) { [weak self, weak alert] _ in
            guard let title = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespaces), !title.isEmpty else {
                return
            }
            let target = "./" + title.replacingOccurrences(of: " ", with: "_")
            self?.toggleAnnotation(kind: .link, target: target)
        })
        present(alert, animated: true)
    }

    // MARK: - Publishing

    /// Serializes the edited document, transforms it to wikitext on the server
    /// (with the base revision + etag so selser produces a clean diff), and
    /// hands off to the existing native save flow — summary, minor edit,
    /// watchlist, captcha and abuse filter handling all come from
    /// EditSaveViewController, exactly as the source editor uses it.
    @objc private func publishButtonTapped(_ sender: UIBarButtonItem) {
        guard let document,
              let percentEncodedTitle = articleURL.wmf_title?.percentEncodedPageTitleForPathComponents else {
            return
        }

        var transformPathComponents = ["transform", "html", "to", "wikitext", percentEncodedTitle]
        if let fetchedRevisionID {
            transformPathComponents.append(fetchedRevisionID)
        }
        guard let transformURL = Configuration.current.pageContentServiceAPIURLForURL(articleURL, appending: transformPathComponents) else {
            showError(message: "Could not construct the transform URL for this article.")
            return
        }

        activityIndicator.startAnimating()
        let serializedHTML = WMFVisualEditorHTMLSerializer().serializeDocument(document)

        Task { [weak self] in
            do {
                var request = URLRequest(url: transformURL)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                if let etag = self?.fetchedETag {
                    request.setValue(etag, forHTTPHeaderField: "If-Match")
                }
                request.httpBody = try JSONSerialization.data(withJSONObject: ["html": serializedHTML])

                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    throw RequestError.http(httpResponse.statusCode)
                }
                guard let wikitext = String(data: data, encoding: .utf8) else {
                    throw RequestError.unexpectedResponse
                }

                guard let self, !Task.isCancelled else {
                    return
                }
                self.activityIndicator.stopAnimating()
                self.showEditSave(wikitext: wikitext)
            } catch {
                guard let self, !Task.isCancelled else {
                    return
                }
                self.activityIndicator.stopAnimating()
                DDLogError("NativeVisualEditorPlayground: html→wikitext transform failed: \(error)")
                self.showError(message: "The html→wikitext transform failed: \(error.localizedDescription)")
            }
        }
    }

    private func showEditSave(wikitext: String) {
        guard let saveViewController = EditSaveViewController.wmf_initialViewControllerFromClassStoryboard() else {
            return
        }

        saveViewController.dataStore = MWKDataStore.shared()
        saveViewController.savedData = editConfirmationSavedData
        saveViewController.pageURL = articleURL
        saveViewController.sectionID = nil
        saveViewController.languageCode = articleURL.wmf_languageCode
        saveViewController.wikitext = wikitext
        saveViewController.source = .article
        saveViewController.editTags = [.appFullSource]
        saveViewController.delegate = self
        saveViewController.theme = theme

        navigationController?.pushViewController(saveViewController, animated: true)
    }

    // MARK: - Actions

    @objc private func closeButtonTapped(_ sender: UIButton) {
        navigationController?.dismiss(animated: true)
    }

    @objc private func undoButtonTapped(_ sender: UIBarButtonItem) {
        guard let document, let record = undoStack.popLast(),
              let (restoredDocument, removedItems) = try? document.splicingItems(in: record.insertedRange, with: record.removedItems) else {
            return
        }
        redoStack.append(EditRecord(insertedRange: record.insertedRange.lowerBound..<(record.insertedRange.lowerBound + record.removedItems.count), removedItems: removedItems))
        self.document = restoredDocument
        rerender(restoringCaretAtLinearIndex: record.insertedRange.lowerBound + record.removedItems.count)
    }

    @objc private func redoButtonTapped(_ sender: UIBarButtonItem) {
        guard let document, let record = redoStack.popLast(),
              let (redoneDocument, removedItems) = try? document.splicingItems(in: record.insertedRange, with: record.removedItems) else {
            return
        }
        undoStack.append(EditRecord(insertedRange: record.insertedRange.lowerBound..<(record.insertedRange.lowerBound + record.removedItems.count), removedItems: removedItems))
        self.document = redoneDocument
        rerender(restoringCaretAtLinearIndex: record.insertedRange.lowerBound + record.removedItems.count)
    }

    @objc private func inspectorButtonTapped(_ sender: UIBarButtonItem) {
        guard let document else {
            return
        }
        let statistics = document.statistics

        var lines: [String] = []
        if let parseDuration {
            lines.append(String(format: "Parsed natively in %.0f ms", parseDuration * 1000))
        }
        lines.append("Characters: \(statistics.characterCount) (\(statistics.annotatedCharacterCount) annotated)")
        lines.append("Edits applied: \(undoStack.count)")
        lines.append("")
        for (type, count) in statistics.nodeTypeCounts.sorted(by: { $0.value > $1.value }) {
            lines.append("\(type): \(count)")
        }
        if !imageLoadStatuses.isEmpty {
            lines.append("")
            lines.append("Images:")
            for (name, status) in imageLoadStatuses.sorted(by: { $0.key < $1.key }) {
                lines.append("\(name.prefix(28)): \(status)")
            }
        }

        let alert = UIAlertController(title: "Linear model", message: lines.joined(separator: "\n"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: CommonStrings.okTitle, style: .default))
        present(alert, animated: true)
    }
}

// MARK: - EditSaveViewControllerDelegate

extension NativeVisualEditorPlaygroundViewController: EditSaveViewControllerDelegate {

    func editSaveViewControllerDidSave(_ editSaveViewController: EditSaveViewController, result: Result<EditorChanges, Error>, needsNewTempAccountToast: Bool?) {
        switch result {
        case .failure(let error):
            showError(message: error.localizedDescription)
        case .success(let changes):
            didPublish(changes.newRevisionID)
        }
    }

    func editSaveViewControllerWillCancel(_ saveData: EditSaveViewController.SaveData) {
        editConfirmationSavedData = saveData
        navigationController?.popViewController(animated: true)
    }

    func editSaveViewControllerDidTapShowWebPreview() {
        assertionFailure("Web preview is not part of the native visual editor flow")
    }
}

// MARK: - UITextViewDelegate

extension NativeVisualEditorPlaygroundViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Marked-text composition (CJK input methods) is a known spike
        // limitation — mapping composition state to transactions comes with the
        // real editing surface (TextKit 2 phase).
        guard textView.markedTextRange == nil else {
            return false
        }
        // Return splits the enclosing block — a structural transaction.
        if text == "\n", range.length == 0 {
            if let insertionRange = linearRange(forRenderedRange: range) {
                applySplit(atLinearIndex: insertionRange.lowerBound)
            }
            return false
        }
        // Multi-line pastes: flatten to spaces (multi-block paste is structural
        // work beyond this slice).
        let sanitizedText = text.contains("\n") ? text.replacingOccurrences(of: "\n", with: " ") : text
        guard let linearRange = linearRange(forRenderedRange: range) else {
            return false
        }
        _ = applyEdit(renderedRange: range, linearRange: linearRange, replacementText: sanitizedText)
        // The model is the source of truth: we re-rendered ourselves, so the
        // text view must never apply the edit directly.
        return false
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        navigate(to: URL)
        return false
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        // The remembered caret only stays valid while the selection is exactly
        // where the structural change put it.
        if let pending = pendingCaretContext,
           textView.selectedRange.location != pending.renderedLocation || textView.selectedRange.length != 0 {
            pendingCaretContext = nil
        }
    }
}
