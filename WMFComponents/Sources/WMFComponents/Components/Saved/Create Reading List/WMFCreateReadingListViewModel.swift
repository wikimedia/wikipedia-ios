import Foundation
import WMFData
import WMFNativeLocalizations

@MainActor
public final class WMFCreateReadingListViewModel: ObservableObject {

    public enum Mode: Equatable {
        case create
        case importSharedList
        /// Saves the Discover list. The name defaults to "Discover" and the date.
        case saveDiscoverList(date: Date)
    }

    /// An article the user can select to save in the new list.
    public struct Article: Identifiable, Equatable {
        public let id: String
        /// The title to show. It can contain HTML.
        public let displayTitle: String
        public let project: WMFProject
        public let description: String?
        public let thumbnailURL: URL?

        public init(id: String, displayTitle: String, project: WMFProject, description: String?, thumbnailURL: URL?) {
            self.id = id
            self.displayTitle = displayTitle
            self.project = project
            self.description = description
            self.thumbnailURL = thumbnailURL
        }
    }

    @Published public var name: String = "" {
        didSet {
            guard name != oldValue else { return }
            nameErrorMessage = validationError(for: name)
        }
    }
    @Published public var description: String = ""
    @Published public private(set) var nameErrorMessage: String?
    @Published public private(set) var isImporting: Bool
    @Published public private(set) var isInputEnabled = true
    /// The host sets it while it saves the list, so the user cannot tap Create twice.
    @Published public var isCreating = false
    @Published private var selectedArticleIDSet: Set<String> = []

    @Published public private(set) var articles: [Article] = []
    @Published private(set) var articleRows: [WMFPageRowSavedViewModel] = []

    public let mode: Mode
    public var didTapCreate: ((_ name: String, _ description: String) -> Void)?
    public var didTapClose: (() -> Void)?
    /// Called once the form leaves the screen, by any path.
    public var didDismiss: (() -> Void)?

    let title: String
    let subtitle: String?

    /// Returns an error message when the trimmed name cannot be used, for example when a list with that name exists.
    private let validateName: ((String) -> String?)?

    private let importedListDefaultName = WMFLocalizedString("import-shared-reading-list-default-title", value: "My Reading List", comment: "Default title of a reading list imported through a shared link.")

    public init(mode: Mode, articles: [Article] = [], validateName: ((String) -> String?)? = nil) {
        self.mode = mode
        self.validateName = validateName
        isImporting = mode == .importSharedList

        switch mode {
        case .create:
            title = CommonStrings.createNewListTitle
            subtitle = nil
        case .importSharedList:
            title = WMFLocalizedString("import-shared-reading-list-title", value: "Import shared reading list", comment: "Title of screen that imports a shared reading list.")
            subtitle = nil
        case .saveDiscoverList(let date):
            title = WMFLocalizedString("discover-save-list-title", value: "Save reading list", comment: "Title of the sheet that saves the articles of the Discover reading list as a new reading list.")
            subtitle = WMFLocalizedString("discover-save-list-subtitle", value: "Name reading list and select articles to save.", comment: "Text under the title of the sheet that saves the articles of the Discover reading list as a new reading list.")
            name = String.localizedStringWithFormat(Self.discoverDefaultNameFormat, DateFormatter.wmfShortDateShortTimeFormatter.string(from: date))
            nameErrorMessage = validationError(for: name)
        }

        setArticles(articles)
    }

    // MARK: - State

    public var isCreateButtonEnabled: Bool {
        !trimmedName.isEmpty && nameErrorMessage == nil && !isImporting && isInputEnabled && !isCreating && hasRequiredSelection
    }

    /// The IDs of the selected articles, in list order.
    public var selectedArticleIDs: [String] {
        articles.map(\.id).filter { selectedArticleIDSet.contains($0) }
    }

    var focusesNameOnAppear: Bool {
        mode == .create
    }

    /// In create mode the user chose the articles before, so a single row only shows what the list gets.
    var allowsArticleSelection: Bool {
        mode != .create || articles.count > 1
    }

    func isSelected(_ articleID: String) -> Bool {
        selectedArticleIDSet.contains(articleID)
    }

    private var hasRequiredSelection: Bool {
        articles.isEmpty || !selectedArticleIDSet.isEmpty
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private func validationError(for name: String) -> String? {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return nil }
        return validateName?(trimmedName)
    }

    // MARK: - Actions

    public func tapCreate() {
        guard isCreateButtonEnabled else { return }
        didTapCreate?(trimmedName, description.trimmingCharacters(in: .whitespaces))
    }

    public func tapClose() {
        didTapClose?()
    }

    func toggleSelection(of articleID: String) {
        guard isInputEnabled, allowsArticleSelection, let rowViewModel = articleRows.first(where: { $0.id == articleID }) else { return }
        if selectedArticleIDSet.contains(articleID) {
            selectedArticleIDSet.remove(articleID)
        } else {
            selectedArticleIDSet.insert(articleID)
        }
        rowViewModel.isSelected = selectedArticleIDSet.contains(articleID)
    }

    // MARK: - Host callbacks

    public func showNameError(_ message: String) {
        nameErrorMessage = message
    }

    /// Shows the imported articles as rows, all selected.
    public func importDidSucceed(articles: [Article] = []) {
        setArticles(articles)
        isImporting = false
        name = importedListDefaultName
    }

    public func importDidFail() {
        isImporting = false
        isInputEnabled = false
    }

    private func setArticles(_ articles: [Article]) {
        self.articles = articles
        selectedArticleIDSet = Set(articles.map(\.id))
        articleRows = articles.map { article in
            let rowViewModel = WMFPageRowSavedViewModel(
                id: article.id,
                title: article.displayTitle.removingHTML,
                project: article.project,
                description: article.description,
                thumbnailURL: article.thumbnailURL,
                readingListNames: []
            )
            rowViewModel.isEditing = allowsArticleSelection
            rowViewModel.isSelected = true
            return rowViewModel
        }
    }

    // MARK: - Strings

    private static let discoverDefaultNameFormat = WMFLocalizedString("discover-save-list-default-name", value: "Discover %1$@", comment: "Default name of a reading list saved from the Discover reading list. %1$@ is replaced with the current date and time, for example \"10/2/26, 10:52 PM\".")
}
