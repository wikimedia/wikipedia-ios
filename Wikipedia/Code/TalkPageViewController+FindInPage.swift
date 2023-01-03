import Foundation

extension TalkPageViewController {

    // MARK: - Overrides

    override var canBecomeFirstResponder: Bool {
        return findInPageState.keyboardBar != nil
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

    func hideFindInPage(releaseKeyboardBar: Bool = false) {
        findInPageState.reset(viewModel.topics)
        findInPageState.keyboardBar?.hide()
        rethemeVisibleCells()
        resignFirstResponder()

        if releaseKeyboardBar {
            findInPageState.keyboardBar = nil
        }
    }
    
    var isShowingFindInPage: Bool {
        return findInPageState.keyboardBar?.isVisible ?? false
    }

    // MARK: - Scroll to Element
    
    private func scrollToFindInPageResultRect() {
        if let scrollingToIndexPath = scrollingToIndexPath,
        let scrollingToResult = scrollingToResult {
            
            if let scrollingToCommentViewModel = scrollingToCommentViewModel {
                if let commentView = talkPageCell(indexPath: scrollingToIndexPath)?.commentViewForViewModel(scrollingToCommentViewModel) {
                    if let targetFrame = commentView.frameForHighlight(result: scrollingToResult) {
                        talkPageView.collectionView.scrollRectToVisible(targetFrame, animated: true)
                    }
                }
            } else {
                if let talkPageCell = talkPageCell(indexPath: scrollingToIndexPath) {
                    if let targetFrame = talkPageCell.topicView.frameForHighlight(result: scrollingToResult) {
                        talkPageView.collectionView.scrollRectToVisible(targetFrame, animated: true)
                    }
                }
            }
        }
        
        scrollingToIndexPath = nil
        scrollingToResult = nil
        scrollingToCommentViewModel = nil
        
        rethemeVisibleCells()
    }

    func scrollToFindInPageResult(_ result: TalkPageFindInPageSearchController.SearchResult?) {
        guard let result = result else { return }

        switch result.location {
        case .topicTitle(topicIndex: let index, topicIdentifier: _):
            let indexPath = IndexPath(row: index, section: 0)
            
            scrollingToIndexPath = indexPath
            scrollingToResult = result
            
            if talkPageView.collectionView.indexPathsForVisibleItems.contains(indexPath) {
                scrollToFindInPageResultRect()
            } else {
                talkPageView.collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
                scrollToFindInPageResultRect()
            }
        case .topicLeadComment(topicIndex: let index, replyIdentifier: _),
             .topicOtherContent(topicIndex: let index):
            let indexPath = IndexPath(row: index, section: 0)
            
            scrollingToIndexPath = indexPath
            scrollingToResult = result
            
            if talkPageView.collectionView.indexPathsForVisibleItems.contains(indexPath) {
                scrollToFindInPageResultRect()
            } else {
                talkPageView.collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
                scrollToFindInPageResultRect()
            }
        case .reply(topicIndex: let topicIndex, topicIdentifier: _, replyIndex: let replyIndex, replyIdentifier: _):
            let topicViewModel = viewModel.topics[topicIndex]
            let commentViewModel = topicViewModel.replies[replyIndex]

            let indexPath = IndexPath(row: topicIndex, section: 0)
            
            scrollingToIndexPath = indexPath
            scrollingToResult = result
            scrollingToCommentViewModel = commentViewModel
            
            if talkPageView.collectionView.indexPathsForVisibleItems.contains(indexPath) {
                scrollToFindInPageResultRect()
            } else {
                talkPageView.collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
                scrollToFindInPageResultRect()
            }
        }
    }

    private func talkPageCell(indexPath: IndexPath) -> TalkPageCell? {
        talkPageView.collectionView.layoutIfNeeded()
        return talkPageView.collectionView.cellForItem(at: indexPath) as? TalkPageCell
    }

}

extension TalkPageViewController: FindAndReplaceKeyboardBarDelegate {

    func keyboardBar(_ keyboardBar: FindAndReplaceKeyboardBar, didChangeSearchTerm searchTerm: String?) {
        guard let searchTerm else {
            return
        }

        findInPageState.search(term: searchTerm, in: viewModel.topics, traitCollection: traitCollection, theme: theme)
        rethemeVisibleCells()
    }

    func keyboardBarDidTapClose(_ keyboardBar: FindAndReplaceKeyboardBar) {
        hideFindInPage()
    }

    func keyboardBarDidTapClear(_ keyboardBar: FindAndReplaceKeyboardBar) {
        findInPageState.reset(viewModel.topics)
        rethemeVisibleCells()
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
