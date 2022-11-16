import Foundation

final class TalkPageFindInPageState {

    // MARK: - Properties

    let searchController = TalkPageFindInPageSearchController()
    var keyboardBar: FindAndReplaceKeyboardBar?

    var selectedIndex: Int = -1 {
        didSet {
            updateView()
        }
    }

    var selectedMatch: TalkPageFindInPageSearchController.SearchResult? {
        guard matches.indices.contains(selectedIndex) else {
            return nil
        }

        return matches[selectedIndex]
    }

    var matches: [TalkPageFindInPageSearchController.SearchResult] = [] {
        didSet {
            updateView()
        }
    }

    // MARK: - Public

    /// Next result, looping to start of matches if at end
    func next() {
        guard !matches.isEmpty else {
            return
        }

        guard selectedIndex < matches.count - 1 else {
            selectedIndex = 0
            return
        }

        selectedIndex += 1
    }

    /// Previous result, looping to end of matches if at beginning
    func previous() {
        guard !matches.isEmpty else {
            return
        }

        guard selectedIndex > 0 else {
            selectedIndex = matches.count - 1
            return
        }

        selectedIndex -= 1
    }

    func reset(_ topics: [TalkPageCellViewModel]) {
        matches = []
        selectedIndex = -1
        keyboardBar?.reset()
        topics.forEach {
            $0.highlightText = nil
            $0.activeHighlightResult = nil
        }

    }

    func search(term: String, in topics: [TalkPageCellViewModel], traitCollection: UITraitCollection, theme: Theme) {
        selectedIndex = -1
        matches = searchController.search(term: term, in: topics, traitCollection: traitCollection, theme: theme)
        topics.forEach {
            $0.highlightText = matches.isEmpty ? nil : term
            $0.activeHighlightResult = nil
        }
    }

    // MARK: - Private

    private func updateView() {
        keyboardBar?.updateMatchCounts(index: selectedIndex, total: UInt(matches.count))
    }

}
