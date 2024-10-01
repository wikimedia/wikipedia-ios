import WMF

extension ArticleViewController: ArticleWebMessageHandling {
    
    func didRecieve(action: ArticleWebMessagingController.Action) {
        dismissReferencesPopover()
        switch action {
        case .setup:
            handlePCSDidFinishInitialSetup()
        case .finalSetup:
            handlePCSDidFinishFinalSetup()
        case .unknown(let href):
            fallthrough
        case .link(let href, _, _):
            handleLink(with: href)
        case .leadImage(let source, let width, let height):
            handleLeadImage(source: source, width: width, height: height)
        case .tableOfContents(items: let items):
            handleTableOfContents(items: items)
        case .footerItem(let type, let payload):
            handleFooterItem(type: type, payload: payload)
        case .edit(let sectionID, let descriptionSource):
            showEditorForSectionOrTitleDescription(with: sectionID, descriptionSource: descriptionSource)
        case .backLink(let referenceId, let referenceText, let backLinks):
            showReferenceBackLinks(backLinks, referenceId: referenceId, referenceText: referenceText)
        case .reference(let index, let group):
            showReferences(group, selectedIndex: index, animated: true)
        case .image(let src, let href, let width, let height):
            showImage(src: src, href: href, width: width, height: height)
        case .addTitleDescription:
            showTitleDescriptionEditor(with: .none)
        case .scrollToAnchor(let anchor, let rect):
            scrollToAnchorCompletions.popLast()?(anchor, rect)
            scrollToAnchorCompletions.removeAll()
        case .viewInBrowser:
            navigate(to: self.articleURL, useSafari: true)
        case .aaaldInsertOnScreen:
            handleAaaLDInsertOnScreenEvent()
        }
    }
    
    func handleTableOfContents(items: [TableOfContentsItem]) {
        let titleItem = TableOfContentsItem(id: 0, titleHTML: article.displayTitleHTML, anchor: "", rootItemId: 0, indentationLevel: 0)
        var allItems: [TableOfContentsItem] = [titleItem]
        allItems.append(contentsOf: items)

        // While `items` includes strings localized to the language of the article, our additional appended strings here are not. We need to specify we want localized strings for a local `.lproj` we actually have (which unfortunately doesn't always match the article itself). Here, we send the full language variant code to hint to pull the most accurate localized string we may have available based on the language variant of the article itself.
        let languageCode = articleURL.wmf_contentLanguageCode ?? articleLanguageCode
        let aboutThisArticleTitle = CommonStrings.aboutThisArticleTitle(with: languageCode)
        let readMoreTitle = CommonStrings.readMoreTitle(with: languageCode)
        let aboutThisArticleItem = TableOfContentsItem(id: -2, titleHTML: aboutThisArticleTitle, anchor: PageContentService.Footer.Menu.fragment, rootItemId: -2, indentationLevel: 0)
        allItems.append(aboutThisArticleItem)
        let readMoreItem = TableOfContentsItem(id: -3, titleHTML: readMoreTitle, anchor: PageContentService.Footer.ReadMore.fragment, rootItemId: -3, indentationLevel: 0)
        allItems.append(readMoreItem)
        tableOfContentsItems = allItems
    }
    
    func handlePCSDidFinishInitialSetup() {
        let oldState = state
        state = .loaded
        
        if altTextExperimentViewModel == nil {
            showWIconPopoverIfNecessary()
        }
        
        refreshControl.endRefreshing()
        surveyTimerController?.articleContentDidLoad()
        loadSummary(oldState: oldState)
        initialSetupCompletion?()
        initialSetupCompletion = nil
    }
    
    @objc func handlePCSDidFinishFinalSetup() {
        assignScrollStateFromArticleFlagsIfNecessary()
        articleLoadWaitGroup?.leave()
        addToHistory()
        persistPageViewsForWikipediaInReview()
        syncCachedResourcesIfNeeded()
    }
    
    func handleFooterItem(type: PageContentService.Footer.Menu.Item, payload: Any?) {
        switch type {
        case .talkPage:
            showTalkPage()
        case .coordinate:
            showCoordinate()
        case .disambiguation:
            showDisambiguation(with: payload)
        case .lastEdited:
            showEditHistory()
        case .pageIssues:
            showPageIssues(with: payload)
        }
    }
    
    func handleLeadImage(source: String?, width: Int?, height: Int?) {
        assert(Thread.isMainThread)
        guard let source = source else {
            leadImageHeightConstraint.constant = 0
            return
        }
        guard let leadImageURLToRequest = WMFArticle.imageURL(forTargetImageWidth: traitCollection.wmf_leadImageWidth, fromImageSource: source, withOriginalWidth: width ?? 0) else {
            return
        }
        loadLeadImage(with: leadImageURLToRequest)
    }
    
    func setupFooter() {
        // Always use Configuration.production for related articles
        guard let baseURL = Configuration.production.pageContentServiceAPIURLForURL(articleURL, appending: []) else {
            return
        }
        var menuItems: [PageContentService.Footer.Menu.Item] = [.talkPage, .lastEdited, .pageIssues, .disambiguation]
        if article.coordinate != nil {
            menuItems.append(.coordinate)
        }
        messagingController.addFooter(articleURL: articleURL, restAPIBaseURL: baseURL, menuItems: menuItems, lastModified: article.lastModifiedDate)
    }
    
    func handleAaaLDInsertOnScreenEvent() {
        surveyTimerController?.userDidScrollPastLivingDocArticleContentInsert(withState: state)
    }
}
