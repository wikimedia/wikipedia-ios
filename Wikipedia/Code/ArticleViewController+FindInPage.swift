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
        NavigationEventsFunnel.shared.logEvent(action: .articleToolbarSearchSuccess)
    }
    
    func showFindInPage() {
        createFindInPageViewIfNecessary()
        startObservingFindInPageKeyboard()
        becomeFirstResponder()
        findInPage.view?.show()
    }

    func hideFindInPage(_ completion: (() -> Void)? = nil) {
            resetFindInPage {
                self.findInPage.view?.hide()
                self.findInPage.view?.removeFromSuperview()
                self.findInPage.view = nil
                self.resignFirstResponder()
                self.stopObservingFindInPageKeyboard()
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

    // MARK: - Keyboard

    func startObservingFindInPageKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(findInPageKeyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(findInPageKeyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func stopObservingFindInPageKeyboard() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        restoreScrollViewBottomInsetForFindInPage(animated: false)
    }

    @objc func findInPageKeyboardWillChangeFrame(_ notification: Notification) {
        guard findInPage.view != nil,
              let window = view.window,
              let endFrameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        let keyboardFrameInWindow = window.convert(endFrameValue.cgRectValue, from: nil)
        let webViewFrameInWindow = webView.convert(webView.bounds, to: window)
        let coveredHeight = max(0, webViewFrameInWindow.maxY - keyboardFrameInWindow.minY)

        if findInPageBaseScrollViewBottomInset == nil {
            findInPageBaseScrollViewBottomInset = webView.scrollView.contentInset.bottom
        }
        let baseInset = findInPageBaseScrollViewBottomInset ?? 0

        setScrollViewBottomInsetForFindInPage(baseInset + coveredHeight, notification: notification)
    }

    @objc func findInPageKeyboardWillHide(_ notification: Notification) {
        restoreScrollViewBottomInsetForFindInPage(animated: true, notification: notification)
    }

    private func setScrollViewBottomInsetForFindInPage(_ bottomInset: CGFloat, notification: Notification) {
        let scrollView = webView.scrollView
        guard scrollView.contentInset.bottom != bottomInset else {
            return
        }
        animateAlongsideKeyboard(notification) {
            scrollView.contentInset.bottom = bottomInset
            scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
    }

    private func restoreScrollViewBottomInsetForFindInPage(animated: Bool, notification: Notification? = nil) {
        guard let baseInset = findInPageBaseScrollViewBottomInset else {
            return
        }
        findInPageBaseScrollViewBottomInset = nil
        let scrollView = webView.scrollView
        let apply = {
            scrollView.contentInset.bottom = baseInset
            scrollView.verticalScrollIndicatorInsets.bottom = baseInset
        }
        if animated, let notification {
            animateAlongsideKeyboard(notification, apply)
        } else {
            apply()
        }
    }

    private func animateAlongsideKeyboard(_ notification: Notification, _ animations: @escaping () -> Void) {
        let userInfo = notification.userInfo
        let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curveValue = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int) ?? Int(UIView.AnimationCurve.easeInOut.rawValue)
        let options = UIView.AnimationOptions(rawValue: UInt(curveValue) << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: animations)
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
}
