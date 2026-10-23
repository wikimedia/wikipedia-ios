import SwiftUI
import Combine
import WMFData

public protocol WMFReadingListsLoggingDelegate: AnyObject {
    @MainActor func readingListsDidTapEdit()
    @MainActor func readingListsDidDelete(count: Int)
    @MainActor func readingListsDidFailToDelete(error: Error)
}

@MainActor
public final class WMFReadingListsViewModel: ObservableObject {

    public enum State {
        case loading
        case empty
        case data
    }

    @Published public private(set) var readingLists: [WMFReadingList] = []
    /// One row per list, reused across reloads while the list is unchanged so its images stay loaded.
    @Published private(set) var rows: [WMFReadingListRowViewModel] = []
    @Published public private(set) var state: State = .loading
    @Published public private(set) var isEditing = false
    @Published public private(set) var selectedIDs: Set<String> = []
    @Published public var searchText = ""
    @Published public private(set) var sortOrder: WMFReadingListSortOrder
    /// The lists the user asked to delete and is being asked to confirm. Set only for lists with articles.
    @Published public var pendingDeletion: [WMFReadingList]?

    public let filter: WMFReadingListsFilter

    public var didTapReadingList: ((WMFReadingList) -> Void)?
    public var didTapCreateList: (() -> Void)?
    public var didPullToRefresh: (() async -> Void)?
    public var didUpdateEditingMode: ((Bool) -> Void)?
    public weak var loggingDelegate: WMFReadingListsLoggingDelegate?

    private let dataController: WMFLegacyReadingListsDataController
    private var loadTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    public init(dataController: WMFLegacyReadingListsDataController, filter: WMFReadingListsFilter = .all) {
        self.dataController = dataController
        self.filter = filter
        self.sortOrder = dataController.readingListsSortOrder
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadReadingLists()
            }
            .store(in: &cancellables)
    }

    deinit {
        loadTask?.cancel()
    }

    public var hasSelection: Bool {
        !selectedIDs.isEmpty
    }

    /// Only custom lists can be deleted, so editing needs at least one.
    public var canEdit: Bool {
        readingLists.contains { !$0.isDefault }
    }

    public var selectedReadingLists: [WMFReadingList] {
        readingLists.filter { selectedIDs.contains($0.id) }
    }

    // MARK: - Loading

    public func loadReadingLists() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            let lists = (try? await dataController.fetchReadingLists(filter: filter, searchText: searchText)) ?? []
            guard !Task.isCancelled else { return }
            let existingRows = Dictionary(rows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            self.rows = lists.map { list in
                if let row = existingRows[list.id], row.readingList == list {
                    return row
                }
                return WMFReadingListRowViewModel(readingList: list)
            }
            self.readingLists = lists
            let isEmpty = lists.isEmpty && searchText.isEmpty
            let newState: State = isEmpty ? .empty : .data
            if newState != self.state {
                self.state = newState
            }
        }
    }

    public func refresh() async {
        await didPullToRefresh?()
        loadReadingLists()
    }

    // MARK: - Sorting

    public func setSortOrder(_ sortOrder: WMFReadingListSortOrder) {
        self.sortOrder = sortOrder
        dataController.setReadingListsSortOrder(sortOrder)
        loadReadingLists()
    }

    // MARK: - Editing

    public func toggleEditing() {
        isEditing.toggle()
        if !isEditing {
            selectedIDs = []
        } else {
            loggingDelegate?.readingListsDidTapEdit()
        }
        didUpdateEditingMode?(isEditing)
    }

    public func toggleSelection(for readingList: WMFReadingList) {
        guard !readingList.isDefault else { return }
        if selectedIDs.contains(readingList.id) {
            selectedIDs.remove(readingList.id)
        } else {
            selectedIDs.insert(readingList.id)
        }
    }

    // MARK: - Deleting

    /// Asks for confirmation when any of the lists holds articles; deletes right away otherwise.
    public func requestDeletion(of readingLists: [WMFReadingList]) {
        let deletable = readingLists.filter { !$0.isDefault }
        guard !deletable.isEmpty else { return }
        if deletable.contains(where: { $0.articleCount > 0 }) {
            pendingDeletion = deletable
        } else {
            delete(deletable)
        }
    }

    public func deleteSelectedReadingLists() {
        requestDeletion(of: selectedReadingLists)
    }

    public func confirmPendingDeletion() {
        guard let pendingDeletion else { return }
        self.pendingDeletion = nil
        delete(pendingDeletion)
    }

    public func cancelPendingDeletion() {
        pendingDeletion = nil
    }

    private func delete(_ lists: [WMFReadingList]) {
        let ids = lists.map { $0.id }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await dataController.deleteReadingLists(ids: ids)
                loggingDelegate?.readingListsDidDelete(count: ids.count)
                if isEditing {
                    toggleEditing()
                }
                loadReadingLists()
            } catch {
                loggingDelegate?.readingListsDidFailToDelete(error: error)
                loadReadingLists()
            }
        }
    }
}
