import CocoaLumberjackSwift
import WMFComponents
import WMFData

extension ArticleViewController {
    func showEditorForSectionOrTitleDescription(with id: Int, descriptionSource: ArticleDescriptionSource?) {
        /// If this is a first section with an existing description, show the dialog box. (This is reported as a `central` or `local` description source.) Otherwise, just show the editor for the section. (A first section without an article description has an `Add article description` button, and thus doesn't need the dialog box.)
        if let descriptionSource = descriptionSource, descriptionSource == .central || descriptionSource == .local {
            showEditSectionOrTitleDescriptionDialogForSection(with: id, descriptionSource: descriptionSource)
        } else {
            showEditorForSection(with: id)
        }
        
        if let project = WikimediaProject(siteURL: articleURL) {
            EditInteractionFunnel.shared.logArticleDidTapEditSectionButton(project: project)
        }
        
        EditAttemptFunnel.shared.logInit(pageURL: articleURL)
    }
    
    func showEditorForFullSource() {
        let editorViewController = EditorViewController(pageURL: articleURL, sectionID: nil, editFlow: .editorPreviewSave, source: .article, dataStore: dataStore, articleSelectedInfo: nil, editTag: .appFullSource, delegate: self, theme: theme)
        
        presentEditor(editorViewController: editorViewController)
        
        if let project = WikimediaProject(siteURL: articleURL) {
            EditInteractionFunnel.shared.logArticleDidTapEditSourceButton(project: project)
        }
        
        EditAttemptFunnel.shared.logInit(pageURL: articleURL)
    }
    
    func showEditorForSection(with id: Int, selectedTextEditInfo: SelectedTextEditInfo? = nil) {
        cancelWIconPopoverDisplay()
        
        let editTag: WMFEditTag = selectedTextEditInfo == nil ?  .appSectionSource : .appSelectSource

        let editorViewController = EditorViewController(pageURL: articleURL, sectionID: id, editFlow: .editorPreviewSave, source: .article, dataStore: dataStore, articleSelectedInfo: selectedTextEditInfo, editTag: editTag, delegate: self, theme: theme)
        
        presentEditor(editorViewController: editorViewController)
    }
    
    func showTitleDescriptionEditor(with descriptionSource: ArticleDescriptionSource) {

        let maybeDescriptionController: ArticleDescriptionControlling? = (articleURL.wmf_isEnglishWikipedia || articleURL.wmf_isTestWikipedia) ? ShortDescriptionController(article: article, articleLanguageCode: articleLanguageCode, articleURL: articleURL, descriptionSource: descriptionSource, delegate: self) : WikidataDescriptionController(article: article, articleLanguageCode: articleLanguageCode, descriptionSource: descriptionSource)

        guard let descriptionController = maybeDescriptionController else {
            showGenericError()
            return
        }
        
        let editVC = DescriptionEditViewController.with(dataStore: dataStore, theme: theme, articleDescriptionController: descriptionController)
        editVC.delegate = self
        let navigationController = WMFThemeableNavigationController(rootViewController: editVC, theme: theme)
        navigationController.modalPresentationStyle = .overCurrentContext
        navigationController.view.isOpaque = false
        navigationController.view.backgroundColor = .clear
       let needsIntro = !UserDefaults.standard.wmf_didShowTitleDescriptionEditingIntro()
       if needsIntro {
           navigationController.view.alpha = 0
       }
        let showIntro: (() -> Void)? = {
            let welcomeVC = DescriptionWelcomeInitialViewController.wmf_viewControllerFromDescriptionWelcomeStoryboard()
            welcomeVC.completionBlock = {
            }
            welcomeVC.apply(theme: self.theme)
            navigationController.present(welcomeVC, animated: true) {
                UserDefaults.standard.wmf_setDidShowTitleDescriptionEditingIntro(true)
                navigationController.view.alpha = 1
            }
        }
        present(navigationController, animated: !needsIntro) {
            if needsIntro {
                showIntro?()
            }
        }
    }
    
    private func presentEditor(editorViewController: UIViewController) {
        
        let navigationController = WMFThemeableNavigationController(rootViewController: editorViewController, theme: theme)
        navigationController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        
        let needsIntro = !UserDefaults.standard.didShowEditingOnboarding
        if needsIntro {
            let editingWelcomeViewController = EditingWelcomeViewController(theme: theme) {
                self.present(navigationController, animated: true)
            }
            editingWelcomeViewController.apply(theme: theme)
            present(editingWelcomeViewController, animated: true) {
                UserDefaults.standard.didShowEditingOnboarding = true
            }

        } else {
            present(navigationController, animated: true)
        }
    }
    
    func showEditSectionOrTitleDescriptionDialogForSection(with id: Int, descriptionSource: ArticleDescriptionSource, selectedTextEditInfo: SelectedTextEditInfo? = nil) {

        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        
        let editTitleDescriptionTitle = WMFLocalizedString("description-edit-pencil-title", value: "Edit article description", comment: "Title for button used to show article description editor")
        let editTitleDescriptionAction = UIAlertAction(title: editTitleDescriptionTitle, style: .default) { (action) in
            self.showTitleDescriptionEditor(with: descriptionSource)
            
            if let project = WikimediaProject(siteURL: self.articleURL) {
                EditInteractionFunnel.shared.logArticleConfirmDidTapEditArticleDescription(project: project)
            }
        }
        sheet.addAction(editTitleDescriptionAction)
        
        let editLeadSectionTitle = WMFLocalizedString("description-edit-pencil-introduction", value: "Edit introduction", comment: "Title for button used to show article lead section editor")
        let editLeadSectionAction = UIAlertAction(title: editLeadSectionTitle, style: .default) { (action) in
            self.showEditorForSection(with: id, selectedTextEditInfo: selectedTextEditInfo)
            
            if let project = WikimediaProject(siteURL: self.articleURL) {
                EditInteractionFunnel.shared.logArticleConfirmDidTapEditIntroduction(project: project)
            }
        }
        sheet.addAction(editLeadSectionAction)
        
        sheet.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel) { _ in

            if let project = WikimediaProject(siteURL: self.articleURL) {
                EditInteractionFunnel.shared.logArticleConfirmDidTapCancel(project: project)
            }

            EditAttemptFunnel.shared.logAbort(pageURL: self.articleURL)

        })
        present(sheet, animated: true)
    }

}

extension ArticleViewController: ShortDescriptionControllerDelegate {

    /// Pulls title description from article content.
    /// Looks for the innerText of the "pcs-edit-section-title-description" ID element
    /// - Parameter completion: Completion when bridge call completes. Passes back title description or nil if pcs-edit-section-title-description could not be extracted.
    func currentDescription(completion: @escaping (String?) -> Void) {

        let javascript = """
            function extractTitleDescription() {
                var editTitleDescriptionElement = document.getElementById('pcs-edit-section-title-description');
                if (editTitleDescriptionElement) {
                    return editTitleDescriptionElement.innerText;
                }
                return null;
            }
            extractTitleDescription();
        """

        webView.evaluateJavaScript(javascript) { (result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    DDLogWarn("Failure in articleHtmlTitleDescription: \(error)")
                    completion(nil)
                    return
                }

                guard let stringResult = result as? String else {
                    completion(nil)
                    return
                }

                completion(stringResult)
            }
        }
    }
    
    enum ArticleEditingDescriptionError: Error {
        case failureInjectingNewDescription
    }
    
    func injectNewDescriptionIntoArticleContent(_ newDescription: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let javascript = """
            function injectTitleDescription(description) {

                //first attempt to swap out add description callout
                var addTitleDescriptionElement = document.getElementById("pcs-edit-section-add-title-description");
                if (addTitleDescriptionElement) {
                    addTitleDescriptionElement.insertAdjacentHTML("beforebegin",`<p id='pcs-edit-section-title-description'>${description}</p>`);
                    addTitleDescriptionElement.parentElement.removeChild(addTitleDescriptionElement);
                    return true;
                }
                
                //else replace existing description
                var editTitleDescriptionElement = document.getElementById('pcs-edit-section-title-description');
                if (editTitleDescriptionElement) {
                    editTitleDescriptionElement.innerHTML = description;
                    return true;
                }
                return false;
            }
           injectTitleDescription(`\(newDescription.sanitizedForJavaScriptTemplateLiterals)`);
        """

        webView.evaluateJavaScript(javascript) { (result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    DDLogWarn("Failure in injectNewDescriptionIntoArticleContent: \(error)")
                    completion(.failure(error))
                    return
                }

                guard let boolResult = result as? Bool,
                      boolResult == true else {
                    completion(.failure(ArticleEditingDescriptionError.failureInjectingNewDescription))
                    return
                }

                completion(.success(()))
            }
        }
    }
}

extension ArticleViewController: EditorViewControllerDelegate {
    func editorDidCancelEditing(_ editor: EditorViewController, navigateToURL url: URL?) {
        dismiss(animated: true) {
            self.navigate(to: url)
        }
    }
    
    func editorDidFinishEditing(_ editor: EditorViewController, result: Result<EditorChanges, Error>) {
        switch result {
        case .failure(let error):
            showError(error)
        case .success(let changes):
            dismiss(animated: true) {
                
                self.assignAltTextArticleEditorExperimentAndPresentModalIfNeeded(fullArticleWikitext: changes.fullArticleWikitextForAltTextExperiment, lastRevisionID: changes.newRevisionID)
                
                let title = CommonStrings.editPublishedToastTitle
                let image = UIImage(systemName: "checkmark.circle.fill")
                
                if UIAccessibility.isVoiceOverRunning {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: title)
                    }
                } else {
                    WMFAlertManager.sharedInstance.showBottomAlertWithMessage(title, subtitle: nil, image: image, type: .custom, customTypeName: "edit-published", dismissPreviousAlerts: true)
                }
                
            }
            
            waitForNewContentAndRefresh(changes.newRevisionID)
        }
    }
    
    private func assignAltTextArticleEditorExperimentAndPresentModalIfNeeded(fullArticleWikitext: String?, lastRevisionID: UInt64) {
        
        guard let siteURL = articleURL.wmf_site,
              let languageCode = siteURL.wmf_languageCode,
        let fullArticleWikitext else {
            return
        }
        
        let dataController = WMFAltTextDataController.shared
        
        guard let dataController,
              let wikimediaProject = WikimediaProject(siteURL: siteURL),
                let project = wikimediaProject.wmfProject else {
            return
        }
        
        let isLoggedIn = dataStore.authenticationManager.isLoggedIn
        
        guard isLoggedIn else {
            return
        }
        
        var missingAltTextLink: WMFMissingAltTextLink?
        do {
            let fileMagicWords = MagicWordUtils.getMagicWordsForKey(.fileNamespace, languageCode: languageCode)
            let altMagicWords = MagicWordUtils.getMagicWordsForKey(.imageAlt, languageCode: languageCode)
            missingAltTextLink = try WMFWikitextUtils.missingAltTextLinks(text: fullArticleWikitext, language: languageCode, targetNamespaces: fileMagicWords, targetAltParams: altMagicWords).first
        } catch {
            DDLogError("Error extracting missing alt text link: \(error)")
        }
        
        guard let missingAltTextLink,
              let articleTitle = articleURL.wmf_title,
            let filename = missingAltTextLink.file.denormalizedPageTitle else {
            return
        }
        
        do {
            try dataController.assignArticleEditorExperiment(isLoggedIn: isLoggedIn, project: project)
            EditInteractionFunnel.shared.logAltTextDidAssignArticleEditorGroup(project: WikimediaProject(wmfProject: project))
        } catch let error {
            DDLogWarn("Error assigning alt text article editor experiment: \(error)")
        }
        
        DDLogDebug("Assigned alt text image recommendations group: \(dataController.assignedAltTextImageRecommendationsGroupForLogging() ?? "nil")")
        
        DDLogDebug("Assigned alt text article editor group: \(dataController.assignedAltTextArticleEditorGroupForLogging() ?? "nil")")
        
        if dataController.shouldEnterAltTextArticleEditorFlow(isLoggedIn: isLoggedIn, project: project) {
            presentAltTextPromptModal(missingAltTextLink: missingAltTextLink, filename: filename, articleTitle: articleTitle, fullArticleWikitext: fullArticleWikitext, lastRevisionID: lastRevisionID)
            dataController.markSawAltTextArticleEditorPrompt()
        }
    }
    
    private func presentAltTextPromptModal(missingAltTextLink: WMFMissingAltTextLink, filename: String, articleTitle: String, fullArticleWikitext: String, lastRevisionID: UInt64) {
        
        guard let siteURL = articleURL.wmf_site,
              let languageCode = siteURL.wmf_languageCode,
              let project = WikimediaProject(siteURL: siteURL),
              let wmfProject = project.wmfProject else {
            return
        }
        
        let primaryTapHandler: ScrollableEducationPanelButtonTapHandler = { [weak self] _, _ in
            
            self?.dismiss(animated: true) { [weak self] in
                
                guard let self else {
                    return
                }
                
                self.altTextExperimentAcceptDate = Date()
                
                if let project = WikimediaProject(siteURL: siteURL) {
                    EditInteractionFunnel.shared.logAltTextPromptDidTapAdd(project: project)
                }
                
                let info = ArticleAltTextInfo(missingAltTextLink: missingAltTextLink, filename: filename, articleTitle: articleTitle, fullArticleWikitext: fullArticleWikitext, lastRevisionID: lastRevisionID, wmfProject: wmfProject)
                let altTextArticleEditorOnboardingPresenter = AltTextArticleEditorOnboardingPresenter(articleViewController: self, altTextInfo: info)
                self.altTextArticleEditorOnboardingPresenter = altTextArticleEditorOnboardingPresenter
                altTextArticleEditorOnboardingPresenter.enterAltTextFlow()
            }
        }

        let secondaryTapHandler: ScrollableEducationPanelButtonTapHandler = { [weak self] _, _ in
            self?.dismiss(animated: true) {
                
                EditInteractionFunnel.shared.logAltTextPromptDidTapDoNotAdd(project: project)
                
                // todo: show survey
            }
        }

        let traceableDismissHandler: ScrollableEducationPanelTraceableDismissHandler = { lastAction in
            switch lastAction {
            case .tappedPrimary, .tappedSecondary:
                break
            default:
                EditInteractionFunnel.shared.logAltTextPromptDidTapClose(project: project)
            }
        }

        let panel = AltTextExperimentPanelViewController(showCloseButton: true, buttonStyle: .updatedStyle, primaryButtonTapHandler: primaryTapHandler, secondaryButtonTapHandler: secondaryTapHandler, traceableDismissHandler: traceableDismissHandler, theme: self.theme, isFlowB: false)
        
        EditInteractionFunnel.shared.logAltTextPromptDidAppear(project: project)
        
        present(panel, animated: true)
    }
}

extension ArticleViewController: DescriptionEditViewControllerDelegate {
    func descriptionEditViewControllerEditSucceeded(_ descriptionEditViewController: DescriptionEditViewController, result: ArticleDescriptionPublishResult) {
        injectNewDescriptionIntoArticleContent(result.newDescription) { [weak self] injectResult in
            
            guard let self = self else {
                return
            }

            switch injectResult {
            case .failure(let error):
                DDLogWarn("Failure injecting new description into article content, refreshing instead: \(error)")
                self.waitForNewContentAndRefresh(result.newRevisionID)
            case .success:
                break
            }
        }
    }
}

extension ArticleViewController: WMFAltTextExperimentModalSheetDelegate {
    func didTapGuidance() {
        
    }
    
    func didTapNext(altText: String) {
        
        guard let altTextExperimentViewModel else {
            return
        }
        
        altTextDelegate?.didTapPublish(altText: altText, articleViewController: self, viewModel: altTextExperimentViewModel)
    }
}

extension ArticleViewController: AltTextDelegate {
    private func localizedAltTextFormat(siteURL: URL) -> String {
        let enFormat = "alt=%@"
        guard let languageCode = siteURL.wmf_languageCode else {
            return enFormat
        }
        
        guard let magicWord = MagicWordUtils.getMagicWordForKey(.imageAlt, languageCode: languageCode) else {
            return enFormat
        }
             
        return magicWord.replacingOccurrences(of: "$1", with: "%@")
    }
    
    func didTapPublish(altText: String, articleViewController: ArticleViewController, viewModel: WMFAltTextExperimentViewModel) {
        let articleURL = articleViewController.articleURL
        guard let siteURL = articleURL.wmf_site else {
            return
        }
        
        var finalWikitextToPublish: String?
        if #available(iOS 16.0, *) {
            let altTextToInsert = String.localizedStringWithFormat(localizedAltTextFormat(siteURL: siteURL), altText)
            finalWikitextToPublish = WMFWikitextUtils.insertAltTextIntoImageWikitext(altText: altTextToInsert, caption: viewModel.caption, imageWikitext: viewModel.imageWikitext, fullArticleWikitextWithImage: viewModel.fullArticleWikitextWithImage)
        } else {
            return
        }
                
        let section: String?
        if let sectionID = viewModel.sectionID {
            section = "\(sectionID)"
        } else {
            section = nil
        }
        
        let fetcher = WikiTextSectionUploader()
        fetcher.uploadWikiText(finalWikitextToPublish, forArticleURL: articleURL, section: section, summary: viewModel.localizedStrings.editSummary, isMinorEdit: false, addToWatchlist: false, baseRevID: NSNumber(value: viewModel.lastRevisionID), captchaId: nil, captchaWord: nil, editTags: nil) { result, error in
            
            DispatchQueue.main.async {
                
                self.navigationController?.popViewController(animated: true)
                
                guard let fetchedData = result as? [String: Any],
                      let newRevID = fetchedData["newrevid"] as? UInt64 else {
                    return
                }
                
                if error == nil {
                    // wait for animation to complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                        self?.presentAltTextEditPublishedToast()
                        self?.logAltTextEditSuccess(viewModel: viewModel, altText: altText, revisionID: newRevID)
                    }
                }
            }
        }
    }
    
    private func logAltTextEditSuccess(viewModel: WMFAltTextExperimentViewModel, altText: String, revisionID: UInt64) {
        
        guard let acceptDate = altTextExperimentAcceptDate,
        let siteURL = articleURL.wmf_site,
        let articleTitle = articleURL.wmf_title else {
            return
        }
        
        let image = viewModel.filename
        let caption = viewModel.caption
        let timeSpent = Int(Date().timeIntervalSince(acceptDate))
        
        guard let loggedInUser = dataStore.authenticationManager.getLoggedInUserCache(for: siteURL),
        let project = WikimediaProject(siteURL: siteURL) else {
            return
        }
        
        EditInteractionFunnel.shared.logAltTextDidSuccessfullyPostEdit(timeSpent: timeSpent, revisionID: revisionID, altText: altText, caption: caption, articleTitle: articleTitle, image: image, username: loggedInUser.name, userEditCount: loggedInUser.editCount, registrationDate: loggedInUser.registrationDateString, project: project)
        
        altTextExperimentAcceptDate = nil
    }
    
    private func presentAltTextEditPublishedToast() {
        let title = CommonStrings.editPublishedToastTitle
        let image = UIImage(systemName: "checkmark.circle.fill")
        
        if UIAccessibility.isVoiceOverRunning {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: title)
            }
        } else {
            WMFAlertManager.sharedInstance.showBottomAlertWithMessage(title, subtitle: nil, image: image, type: .custom, customTypeName: "edit-published", dismissPreviousAlerts: true)
        }
    }
}

// Save these strings in case we need them - right now I don't think mobile-html even sends the event if they can't edit
// WMFLocalizedStringWithDefaultValue(@"page-protected-can-not-edit-title", nil, nil, @"This page is protected", @"Title of alert dialog shown when trying to edit a page that is protected beyond what the user can edit.")
// WMFLocalizedStringWithDefaultValue(@"page-protected-can-not-edit", nil, nil, @"You do not have the rights to edit this page", @"Text of alert dialog shown when trying to edit a page that is protected beyond what the user can edit.")
