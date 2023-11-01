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
        showWIconPopoverIfNecessary()
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
        syncCachedResourcesIfNeeded()
        
        if let imageWikitextFileNameSEAT {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.scrollToSEATImage(imageWikitextFileNameSEAT: imageWikitextFileNameSEAT, completion: { error in
                    
                })
            }
        }
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
    
    func scrollToSEATImage(imageWikitextFileNameSEAT: String, completion: @escaping (Error?) -> Void) {
        
        guard var fileName = imageWikitextFileNameSEAT.denormalizedPageTitle else {
            return
        }
        
        fileName = fileName.replacingOccurrences(of: "'", with: "\\'")
        
        let simpleJavascript = """
            var imageLinkElement = document.querySelectorAll('[href="./\(fileName)"]');
            imageLinkElement[0].scrollIntoView({behavior: "smooth"});
        """
        
        var complicatedJavascript: String?
        
        var namespace: String?
        if let index = fileName.firstIndex(of: ":") {
            namespace = String(fileName.prefix(upTo: index))
        }
        
        if let namespace {
            let enOptions = [fileName.replacingOccurrences(of: namespace, with: "File"), fileName.replacingOccurrences(of: namespace, with: "Image")]
            let esOptions = enOptions + [
                                        fileName.replacingOccurrences(of: namespace, with: "Archivo"),
                                        fileName.replacingOccurrences(of: namespace, with: "Imagen")
                                        ]
            let ptOptions = enOptions + [
                                        fileName.replacingOccurrences(of: namespace, with: "Ficheiro"),
                                        fileName.replacingOccurrences(of: namespace, with: "Arquivo"),
                                        fileName.replacingOccurrences(of: namespace, with: "Imagem")
                                        ]
            
            let needsSecondAttempt = UIDevice.current.userInterfaceIdiom == .pad
            
            let secondAttemptJavascript = """
                                            setTimeout(function(){
                                                imageLinkElement[0].scrollIntoView({behavior: "smooth"});
                                            }, 2000);
            """
            
            if let languageCode = articleURL.wmf_languageCode {
                switch languageCode {
                case "en":
                    complicatedJavascript = """
                        var imageLinkElement = document.querySelectorAll('[href="./\(enOptions[0])"]');
                        if (imageLinkElement === undefined || imageLinkElement[0] === undefined) { imageLinkElement = document.querySelectorAll('[href="./\(enOptions[1])"]'); }
                        imageLinkElement[0].scrollIntoView({behavior: "smooth"});
                    """
                    if needsSecondAttempt {
                        complicatedJavascript?.append(secondAttemptJavascript)
                    }
                case "es":
                    
                    complicatedJavascript = """
                        var imageLinkElement = document.querySelectorAll('[href="./\(esOptions[2])"]');
                        if (imageLinkElement === undefined || imageLinkElement[0] === undefined) { imageLinkElement = document.querySelectorAll('[href="./\(esOptions[3])"]'); }
                        if (imageLinkElement === undefined || imageLinkElement[0] === undefined) { imageLinkElement = document.querySelectorAll('[href="./\(esOptions[0])"]'); }
                        if (imageLinkElement === undefined || imageLinkElement[0] === undefined) { imageLinkElement = document.querySelectorAll('[href="./\(esOptions[1])"]'); }
                        imageLinkElement[0].scrollIntoView({behavior: "smooth"});
                    """
                    if needsSecondAttempt {
                        complicatedJavascript?.append(secondAttemptJavascript)
                    }
                    
                case "pt":
                    complicatedJavascript = """
                        var imageLinkElement = document.querySelectorAll('[href="./\(ptOptions[2])"]');
                        if (imageLinkElement === undefined || imageLinkElement[0] === undefined) { imageLinkElement = document.querySelectorAll('[href="./\(ptOptions[3])"]'); }
                        if (imageLinkElement === undefined || imageLinkElement[0] === undefined) { imageLinkElement = document.querySelectorAll('[href="./\(ptOptions[4])"]'); }
                        if (imageLinkElement === undefined || imageLinkElement[0] === undefined) { imageLinkElement = document.querySelectorAll('[href="./\(ptOptions[0])"]'); }
                        if (imageLinkElement === undefined || imageLinkElement[0] === undefined) { imageLinkElement = document.querySelectorAll('[href="./\(ptOptions[1])"]'); }
                        imageLinkElement[0].scrollIntoView({behavior: "smooth"});
                    """
                    if needsSecondAttempt {
                        complicatedJavascript?.append(secondAttemptJavascript)
                    }
                default:
                    break
                }
            }
        }
        
        let finalJavascript = complicatedJavascript ?? simpleJavascript

        webView.evaluateJavaScript(finalJavascript) { (result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completion(error)
                    return
                }

                completion(nil)
            }
        }
    }
}
