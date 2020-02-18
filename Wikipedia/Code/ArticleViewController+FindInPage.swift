struct ArticleFindInPageState {
    var view: FindAndReplaceKeyboardBar?

    var matches: [String] = [] {
        didSet {
            updateViewState()
        }
    }
    var selectedIndex: Int = -1 {
        didSet {
            updateViewState()
        }
    }
    
    var selectedMatch: String? {
        guard selectedIndex >= 0, selectedIndex < matches.count else {
            return nil
        }
        return matches[selectedIndex]
    }
    
    mutating func next() {
        guard matches.count > 0 else {
            return
        }
        guard selectedIndex < matches.count - 1 else {
            selectedIndex = 0
            return
        }
        selectedIndex += 1
    }
    
    mutating func previous() {
        guard matches.count > 0 else {
            return
        }
        
        guard selectedIndex > 0 else {
            selectedIndex = matches.count - 1
            return
        }
        
        selectedIndex -= 1
    }
    
    func updateViewState() {
        view?.updateMatchCounts(index: selectedIndex, total: UInt(matches.count))
    }
}
extension ArticleViewController {
    func createFindInPageViewIfNecessary() {
        guard findInPage.view == nil else {
            return
        }
        let view = FindAndReplaceKeyboardBar.wmf_viewFromClassNib()!
        view.delegate = self
        view.apply(theme: theme)
        findInPage.view = view
    }
    
    func showFindInPage() {
        createFindInPageViewIfNecessary()
        becomeFirstResponder()
        findInPage.view?.show()
    }
    
    func hideFindInPage(_ completion: (() -> Void)? = nil) {
        resetFindInPage {
            self.findInPage.view?.hide()
            self.resignFirstResponder()
            completion?()
        }
    }

    func resetFindInPage(_ completion: (() -> Void)? = nil) {
        webView.evaluateJavaScript("window.wmf.findInPage.removeSearchTermHighlights()", completionHandler: { obj, error in
            self.findInPage.matches = []
            self.findInPage.selectedIndex = -1
            self.findInPage.view?.resetFind()
            if completion != nil {
                completion?()
            }
        })
    }
    
    func scrollToAndFocusOnFirstFindInPageMatch() {
        findInPage.selectedIndex = -1
        keyboardBarDidTapNext(findInPage.view)
    }
    
    func scrollToAndFocusOnSelectedMatch() {
        guard let selectedMatch = findInPage.selectedMatch else {
            return
        }
        scroll(to: selectedMatch, centered: true, animated: true)
        webView.evaluateJavaScript("window.wmf.findInPage.useFocusStyleForHighlightedSearchTermWithId(`\(selectedMatch.sanitizedForJavaScriptTemplateLiterals)`)", completionHandler: nil)
    }
}

extension ArticleViewController: FindAndReplaceKeyboardBarDelegate {
    func keyboardBar(_ keyboardBar: FindAndReplaceKeyboardBar, didChangeSearchTerm searchTerm: String?) {
        guard let searchTerm = searchTerm?.sanitizedForJavaScriptTemplateLiterals else {
            return
        }
        webView.evaluateJavaScript("window.wmf.findInPage.findAndHighlightAllMatchesForSearchTerm(`\(searchTerm)`)", completionHandler: { obj, error in
            self.findInPage.matches = obj as? [String] ?? []
            self.scrollToAndFocusOnFirstFindInPageMatch()
        })
    }
    
    func keyboardBarDidTapClose(_ keyboardBar: FindAndReplaceKeyboardBar) {
        hideFindInPage()
    }
    
    func keyboardBarDidTapClear(_ keyboardBar: FindAndReplaceKeyboardBar) {
        resetFindInPage()
    }
    
    func keyboardBarDidTapPrevious(_ keyboardBar: FindAndReplaceKeyboardBar) {
        findInPage.previous()
        scrollToAndFocusOnSelectedMatch()
    }
    
    func keyboardBarDidTapNext(_ keyboardBar: FindAndReplaceKeyboardBar?) {
        findInPage.next()
        scrollToAndFocusOnSelectedMatch()
    }
    
    func keyboardBarDidTapReturn(_ keyboardBar: FindAndReplaceKeyboardBar) {
        findInPage.view?.hide()
    }
    
    func keyboardBarDidTapReplace(_ keyboardBar: FindAndReplaceKeyboardBar, replaceText: String, replaceType: ReplaceType) {
        //no-op, not showing replace bar in this context
    }
}
