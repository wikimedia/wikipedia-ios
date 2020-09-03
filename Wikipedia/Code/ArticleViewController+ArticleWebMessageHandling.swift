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
            showEditorForSectionOrTitleDescription(with: sectionID, descriptionSource: descriptionSource, funnelSource: .pencil)
        case .backLink(let referenceId, let referenceText, let backLinks):
            showReferenceBackLinks(backLinks, referenceId: referenceId, referenceText: referenceText)
        case .reference(let index, let group):
            showReferences(group, selectedIndex: index, animated: true)
        case .image(let src, let href, let width, let height):
            showImage(src: src, href: href, width: width, height: height)
        case .addTitleDescription:
            showTitleDescriptionEditor(with: .none, funnelSource: .titleDescription)
        case .pronunciation(let url):
            showAudio(with: url)
        case .scrollToAnchor(let anchor, let rect):
            scrollToAnchorCompletions.popLast()?(anchor, rect)
        default:
            break
        }
    }
    
    func handleTableOfContents(items: [TableOfContentsItem]) {
        let titleItem = TableOfContentsItem(id: -1, titleHTML: article.displayTitleHTML, anchor: "", rootItemId: -1, indentationLevel: 0)
        var allItems: [TableOfContentsItem] = [titleItem]
        allItems.append(contentsOf: items)
        let aboutThisArticleTitle = CommonStrings.aboutThisArticleTitle(with: articleLanguage)
        let readMoreTitle = CommonStrings.readMoreTitle(with: articleLanguage)
        let aboutThisArticleItem = TableOfContentsItem(id: -2, titleHTML: aboutThisArticleTitle, anchor: PageContentService.Footer.Menu.fragment, rootItemId: -2, indentationLevel: 0)
        allItems.append(aboutThisArticleItem)
        let readMoreItem = TableOfContentsItem(id: -3, titleHTML: readMoreTitle, anchor: PageContentService.Footer.ReadMore.fragment, rootItemId: -3, indentationLevel: 0)
        allItems.append(readMoreItem)
        tableOfContentsItems = allItems
    }
    
    func handlePCSDidFinishInitialSetup() {
        state = .loaded
        webView.becomeFirstResponder()
        showWIconPopoverIfNecessary()
        refreshControl.endRefreshing()
    }
    
    func handlePCSDidFinishFinalSetup() {
        footerLoadGroup?.leave()
        restoreStateIfNecessary()
        addToHistory()
        fromNavStateRestoration = false
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
        guard let baseURL = Configuration.production.wikipediaMobileAppsServicesAPIURLComponentsForHost(articleURL.host, appending: []).url else {
            return
        }
        var menuItems: [PageContentService.Footer.Menu.Item] = [.talkPage, .lastEdited, .pageIssues, .disambiguation]
        if article.coordinate != nil {
            menuItems.append(.coordinate)
        }
        messagingController.addFooter(articleURL: articleURL, restAPIBaseURL: baseURL, menuItems: menuItems, lastModified: article.lastModifiedDate)
    }
}
