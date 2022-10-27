import Foundation

extension TalkPageViewController {

    // MARK: - Overrides

    override var canBecomeFirstResponder: Bool {
        return findInPageState.keyboardBar != nil
    }

    override var inputAccessoryView: UIView? {
        return findInPageState.keyboardBar
    }

    // MARK: - Presentation

    fileprivate func createFindInPageViewIfNecessary() {
        guard findInPageState.keyboardBar == nil else {
            return
        }

        let keyboardBar = FindAndReplaceKeyboardBar.wmf_viewFromClassNib()!
        keyboardBar.delegate = self
        keyboardBar.apply(theme: theme)
        findInPageState.keyboardBar = keyboardBar
    }

    func showFindInPage() {
        createFindInPageViewIfNecessary()
        becomeFirstResponder()
        findInPageState.keyboardBar?.show()
    }

    func hideFindInPage() {
        findInPageState.reset(viewModel.topics)
        findInPageState.keyboardBar?.hide()
        talkPageView.collectionView.reloadData()
        resignFirstResponder()
    }

    // MARK: - Scroll to Element

    func scrollToFindInPageResult(_ result: TalkPageFindInPageSearchController.SearchResult?) {
        guard let result = result else { return }

        talkPageView.collectionView.reloadData()

        // TODO: - Fine tune position when scrolling
        switch result.location {
        case .topicTitle(topicIndex: let index, topicIdentifier: _):
            let indexPath = IndexPath(row: index, section: 0)
            talkPageView.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        case .topicLeadComment(topicIndex: let index, replyIdentifier: _):
            let commentViewModel = viewModel.topics[index].leadComment
            scrollToComment(commentViewModel: commentViewModel, animated: true)
        case .reply(topicIndex: let topicIndex, topicIdentifier: _, replyIndex: let replyIndex, replyIdentifier: _):
            let topicViewModel = viewModel.topics[topicIndex]
            topicViewModel.isThreadExpanded = true
            let commentViewModel = topicViewModel.replies[replyIndex]
            scrollToComment(commentViewModel: commentViewModel, animated: true)
        }
    }

}

extension TalkPageViewController: FindAndReplaceKeyboardBarDelegate {

    func keyboardBar(_ keyboardBar: FindAndReplaceKeyboardBar, didChangeSearchTerm searchTerm: String?) {
        guard let searchTerm else {
            return
        }

        findInPageState.search(term: searchTerm, in: viewModel.topics)
        talkPageView.collectionView.reloadData()
    }

    func keyboardBarDidTapClose(_ keyboardBar: FindAndReplaceKeyboardBar) {
        hideFindInPage()
    }

    func keyboardBarDidTapClear(_ keyboardBar: FindAndReplaceKeyboardBar) {
        findInPageState.reset(viewModel.topics)
        talkPageView.collectionView.reloadData()
    }

    func keyboardBarDidTapPrevious(_ keyboardBar: FindAndReplaceKeyboardBar) {
        findInPageState.previous()
        viewModel.topics.forEach { $0.activeHighlightResult = findInPageState.selectedMatch }
        scrollToFindInPageResult(findInPageState.selectedMatch)
    }

    func keyboardBarDidTapNext(_ keyboardBar: FindAndReplaceKeyboardBar?) {
        findInPageState.next()
        viewModel.topics.forEach { $0.activeHighlightResult = findInPageState.selectedMatch }
        scrollToFindInPageResult(findInPageState.selectedMatch)
    }

    func keyboardBarDidTapReturn(_ keyboardBar: FindAndReplaceKeyboardBar) {
        keyboardBarDidTapNext(keyboardBar)
    }

    func keyboardBarDidTapReplace(_ keyboardBar: FindAndReplaceKeyboardBar, replaceText: String, replaceType: ReplaceType) {}

}
