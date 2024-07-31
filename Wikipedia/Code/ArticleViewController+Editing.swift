import CocoaLumberjackSwift
import WKData

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
        
        let editTag: WKEditTag = selectedTextEditInfo == nil ?  .appSectionSource : .appSelectSource

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
                
                self.assignAltTextArticleEditorExperimentAndPresentModalIfNeeded(postedWikitext: changes.postedWikitext)
                
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
    
    private func assignAltTextArticleEditorExperimentAndPresentModalIfNeeded(postedWikitext: String?) {
        
        guard let siteURL = articleURL.wmf_site,
        let postedWikitext else {
            return
        }
        
        let dataController = WKAltTextDataController.shared
        
        guard let dataController,
              let wikimediaProject = WikimediaProject(siteURL: siteURL),
                let project = wikimediaProject.wkProject else {
            return
        }
        
        let isLoggedIn = dataStore.authenticationManager.isLoggedIn
        
        guard isLoggedIn else {
            return
        }
        
        // TODO: Evaluate postedWikitext here, confirm it qualifies for alt text experiment before assigning experiment values https://phabricator.wikimedia.org/T367908
        
        do {
            try dataController.assignArticleEditorExperiment(isLoggedIn: isLoggedIn, project: project)
        } catch let error {
            DDLogWarn("Error assigning alt text article editor experiment: \(error)")
        }
        
        DDLogDebug("Assigned alt text image recommendations group: \(dataController.assignedAltTextImageRecommendationsGroupForLogging() ?? "nil")")
        
        DDLogDebug("Assigned alt text article editor group: \(dataController.assignedAltTextArticleEditorGroupForLogging() ?? "nil")")
        
        if dataController.shouldEnterAltTextArticleEditorFlow(isLoggedIn: isLoggedIn, project: project) {
            print("TODO: PRESENT MODAL")
            dataController.markSawAltTextArticleEditorPrompt()
        }
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

extension ArticleViewController: TestVCDelegate {
    
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
    
    func didTapPublish() {
        guard let altTextExperimentViewModel,
        let siteURL = articleURL.wmf_site else {
            return
        }
        
        // TODO: Just inserting dummy alt text here
        
        let originalFullArticleWikitext = altTextExperimentViewModel.fullArticleWikitextWithImage
        let originalImageWikitext = altTextExperimentViewModel.imageWikitext
        let originalCaption = altTextExperimentViewModel.caption
        
        var finalImageWikitext = originalImageWikitext
        var finalWikitext = originalFullArticleWikitext
        
        let altTextToInsert = String.localizedStringWithFormat(localizedAltTextFormat(siteURL: siteURL), "Dummy")
        
        if let originalCaption,
           let range = originalImageWikitext.range(of: " | \(originalCaption)]]") {
            finalImageWikitext.replaceSubrange(range, with: "| \(altTextToInsert) | \(originalCaption)]]")
        } else if let range = originalImageWikitext.range(of: "]]") {
            finalImageWikitext.replaceSubrange(range, with: "| \(altTextToInsert)]]")
        }
        
        if let range = originalFullArticleWikitext.range(of: originalImageWikitext) {
            finalWikitext.replaceSubrange(range, with: finalImageWikitext)
        }
        
        print(finalWikitext)
        
//        let fetcher = WikiTextSectionUploader()
//        fetcher.uploadWikiText(finalWikitext, forArticleURL: articleURL, section: "0", summary: "Added alt text", isMinorEdit: false, addToWatchlist: false, baseRevID: NSNumber(value: altTextExperimentViewModel.lastRevisionID), captchaId: nil, captchaWord: nil, editTags: nil) { result, error in
//            print(result)
//            print(error)
//        }
    }
}

// Save these strings in case we need them - right now I don't think mobile-html even sends the event if they can't edit
// WMFLocalizedStringWithDefaultValue(@"page-protected-can-not-edit-title", nil, nil, @"This page is protected", @"Title of alert dialog shown when trying to edit a page that is protected beyond what the user can edit.")
// WMFLocalizedStringWithDefaultValue(@"page-protected-can-not-edit", nil, nil, @"You do not have the rights to edit this page", @"Text of alert dialog shown when trying to edit a page that is protected beyond what the user can edit.")
