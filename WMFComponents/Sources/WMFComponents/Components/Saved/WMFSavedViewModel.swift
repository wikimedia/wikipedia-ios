import SwiftUI
import Combine
import WMFData
import WMFNativeLocalizations

public protocol WMFSavedLoggingDelegate: AnyObject {
    @MainActor func savedDidAppear()
    /// A segment is on screen: at first load and after every switch.
    @MainActor func savedDidShowSegment(_ segment: WMFSavedViewModel.Segment)
    /// The reader switched to a segment.
    @MainActor func savedDidSelectSegment(_ segment: WMFSavedViewModel.Segment)
    @MainActor func savedDidTapEditAllArticles()
    @MainActor func savedDidTapProfile()
    @MainActor func savedDidTapTabs()
}

/// The Saved tab container: the segment picker, the search field and the navigation bar state
/// shared by the All articles and Reading lists segments.
@MainActor
public final class WMFSavedViewModel: ObservableObject {

    public enum Segment: Int, CaseIterable, Identifiable {
        case allArticles
        case readingLists

        public var id: Int { rawValue }

        public var title: String {
            switch self {
            case .allArticles:
                return CommonStrings.savedAllArticlesTitle
            case .readingLists:
                return CommonStrings.savedReadingListsTitle
            }
        }

        public var searchPrompt: String {
            switch self {
            case .allArticles:
                return CommonStrings.savedAllArticlesSearchPlaceholder
            case .readingLists:
                return CommonStrings.savedReadingListsSearchPlaceholder
            }
        }
    }

    @Published public private(set) var segment: Segment = .allArticles
    @Published public var searchText = ""
    @Published public var isSearchPresented = false
    @Published public private(set) var isEditing = false
    @Published public private(set) var sortOrder: WMFReadingListSortOrder
    @Published public private(set) var profileButtonNeedsBadge = false

    public let allArticlesViewModel: WMFSavedAllArticlesViewModel
    public let readingListsViewModel: WMFReadingListsViewModel
    public let progressViewModel: WMFSavedProgressViewModel

    public var didTapProfile: (() -> Void)?
    public var didTapTabs: (() -> Void)?
    /// Answers whether the profile button needs its badge. Asked on every appearance and on request.
    public var profileButtonNeedsBadgeProvider: (() -> Bool)?
    public weak var loggingDelegate: WMFSavedLoggingDelegate?

    private var cancellables = Set<AnyCancellable>()

    public init(allArticlesViewModel: WMFSavedAllArticlesViewModel, readingListsViewModel: WMFReadingListsViewModel, progressViewModel: WMFSavedProgressViewModel) {
        self.allArticlesViewModel = allArticlesViewModel
        self.readingListsViewModel = readingListsViewModel
        self.progressViewModel = progressViewModel
        self.sortOrder = allArticlesViewModel.sortOrder
        bind()
    }

    private func bind() {
        $searchText
            .removeDuplicates()
            .sink { [weak self] text in
                self?.forwardSearchText(text)
            }
            .store(in: &cancellables)

        $isSearchPresented
            .removeDuplicates()
            .dropFirst()
            .filter { !$0 }
            .sink { [weak self] _ in
                self?.searchDidEnd()
            }
            .store(in: &cancellables)

        allArticlesViewModel.$isEditing
            .sink { [weak self] isEditing in
                self?.updateIsEditing(isEditing, from: .allArticles)
            }
            .store(in: &cancellables)

        readingListsViewModel.$isEditing
            .sink { [weak self] isEditing in
                self?.updateIsEditing(isEditing, from: .readingLists)
            }
            .store(in: &cancellables)

        allArticlesViewModel.$sortOrder
            .sink { [weak self] sortOrder in
                self?.updateSortOrder(sortOrder, from: .allArticles)
            }
            .store(in: &cancellables)

        readingListsViewModel.$sortOrder
            .sink { [weak self] sortOrder in
                self?.updateSortOrder(sortOrder, from: .readingLists)
            }
            .store(in: &cancellables)
    }

    // MARK: - Lifecycle

    public func viewDidLoad() {
        loggingDelegate?.savedDidShowSegment(segment)
    }

    public func viewWillAppear() {
        refreshProfileButtonBadge()
    }

    public func viewDidAppear() {
        loggingDelegate?.savedDidAppear()
    }

    // MARK: - Segments

    public var searchPrompt: String {
        segment.searchPrompt
    }

    public func selectSegment(_ newSegment: Segment) {
        guard newSegment != segment else { return }
        isSearchPresented = false
        searchText = ""
        segment = newSegment
        updateIsEditing(activeIsEditing, from: newSegment)
        updateSortOrder(activeSortOrder, from: newSegment)
        loggingDelegate?.savedDidShowSegment(newSegment)
        loggingDelegate?.savedDidSelectSegment(newSegment)
    }

    // MARK: - Search

    private func forwardSearchText(_ text: String) {
        switch segment {
        case .allArticles:
            allArticlesViewModel.searchText = text
        case .readingLists:
            readingListsViewModel.searchText = text
        }
    }

    private func searchDidEnd() {
        searchText = ""
        switch segment {
        case .allArticles:
            allArticlesViewModel.searchText = ""
            allArticlesViewModel.loadArticles()
        case .readingLists:
            readingListsViewModel.searchText = ""
        }
    }

    // MARK: - Sort

    public func setSortOrder(_ sortOrder: WMFReadingListSortOrder) {
        switch segment {
        case .allArticles:
            allArticlesViewModel.setSortOrder(sortOrder)
        case .readingLists:
            readingListsViewModel.setSortOrder(sortOrder)
        }
    }

    private var activeSortOrder: WMFReadingListSortOrder {
        segment == .allArticles ? allArticlesViewModel.sortOrder : readingListsViewModel.sortOrder
    }

    private func updateSortOrder(_ sortOrder: WMFReadingListSortOrder, from source: Segment) {
        guard source == segment else { return }
        self.sortOrder = sortOrder
    }

    // MARK: - Editing

    /// Reading lists can be edited only when there is a custom list to delete.
    public var canEdit: Bool {
        segment == .allArticles || readingListsViewModel.canEdit
    }

    public func toggleEditing() {
        switch segment {
        case .allArticles:
            allArticlesViewModel.toggleEditing()
            if allArticlesViewModel.isEditing {
                loggingDelegate?.savedDidTapEditAllArticles()
            }
        case .readingLists:
            guard readingListsViewModel.canEdit else { return }
            readingListsViewModel.toggleEditing()
        }
    }

    public func cancelEditing() {
        guard activeIsEditing else { return }
        switch segment {
        case .allArticles:
            allArticlesViewModel.toggleEditing()
        case .readingLists:
            readingListsViewModel.toggleEditing()
        }
    }

    private var activeIsEditing: Bool {
        segment == .allArticles ? allArticlesViewModel.isEditing : readingListsViewModel.isEditing
    }

    private func updateIsEditing(_ isEditing: Bool, from source: Segment) {
        guard source == segment else { return }
        self.isEditing = isEditing
    }

    // MARK: - Navigation bar

    public func refreshProfileButtonBadge() {
        profileButtonNeedsBadge = profileButtonNeedsBadgeProvider?() ?? false
    }

    public func profileButtonTapped() {
        loggingDelegate?.savedDidTapProfile()
        didTapProfile?()
    }

    public func tabsButtonTapped() {
        didTapTabs?()
        loggingDelegate?.savedDidTapTabs()
    }
}
