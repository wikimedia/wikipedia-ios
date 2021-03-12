import CocoaLumberjackSwift

extension ArticleViewController {
    func showEditorForSectionOrTitleDescription(with id: Int, descriptionSource: ArticleDescriptionSource?, selectedTextEditInfo: SelectedTextEditInfo? = nil, funnelSource: EditFunnelSource) {
        if let descriptionSource = descriptionSource {
            showEditSectionOrTitleDescriptionDialogForSection(with: id, descriptionSource: descriptionSource, selectedTextEditInfo: selectedTextEditInfo, funnelSource: funnelSource)
        }
    }
    
    func showEditorForSection(with id: Int, selectedTextEditInfo: SelectedTextEditInfo? = nil, funnelSource: EditFunnelSource) {
        editFunnel.logSectionEditingStart(from: funnelSource, language: articleLanguage)
        cancelWIconPopoverDisplay()
        let sectionEditVC = SectionEditorViewController(articleURL: articleURL, sectionID: id, dataStore: dataStore, selectedTextEditInfo: selectedTextEditInfo, theme: theme)
        sectionEditVC.delegate = self
        sectionEditVC.editFunnel = editFunnel
        let navigationController = WMFThemeableNavigationController(rootViewController: sectionEditVC, theme: theme)
        navigationController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        let needsIntro = !UserDefaults.standard.didShowEditingOnboarding
        if needsIntro {
            navigationController.view.alpha = 0
        }
        
        sectionEditVC.shouldFocusWebView = !needsIntro
        let showIntro: (() -> Void)? = {
            self.editFunnel.logOnboardingPresentation(initiatedBy: funnelSource, language: self.articleLanguage)
            let editingWelcomeViewController = EditingWelcomeViewController(theme: self.theme) {
                sectionEditVC.shouldFocusWebView = true
            }
            editingWelcomeViewController.apply(theme: self.theme)
            navigationController.present(editingWelcomeViewController, animated: true) {
                UserDefaults.standard.didShowEditingOnboarding = true
                navigationController.view.alpha = 1
            }
        }
        present(navigationController, animated: !needsIntro) {
            if needsIntro {
                showIntro?()
            }
        }
    }
    
    func showTitleDescriptionEditor(with descriptionSource: ArticleDescriptionSource, funnelSource: EditFunnelSource) {

        editFunnel.logTitleDescriptionEditingStart(from: funnelSource, language: articleLanguage)

        let maybeDescriptionController: ArticleDescriptionControlling? = articleURL.wmf_isEnglishWikipedia ? ShortDescriptionController(article: article, articleLanguage: articleLanguage, articleURL: articleURL, descriptionSource: descriptionSource, delegate: self) : WikidataDescriptionController(article: article, articleLanguage: articleLanguage, descriptionSource: descriptionSource)

        guard let descriptionController = maybeDescriptionController else {
            showGenericError()
            return
        }
        
        let editVC = DescriptionEditViewController.with(dataStore: dataStore, theme: theme, articleDescriptionController: descriptionController)
        editVC.delegate = self
        editVC.editFunnel = editFunnel
        editVC.editFunnelSource = funnelSource
        let navigationController = WMFThemeableNavigationController(rootViewController: editVC, theme: theme)
        navigationController.modalPresentationStyle = .overCurrentContext
        navigationController.view.isOpaque = false
        navigationController.view.backgroundColor = .clear
       let needsIntro = !UserDefaults.standard.wmf_didShowTitleDescriptionEditingIntro()
       if needsIntro {
           navigationController.view.alpha = 0
       }
        let showIntro: (() -> Void)? = {
            self.editFunnel.logOnboardingPresentation(initiatedBy: funnelSource, language: self.articleLanguage)
            let welcomeVC = DescriptionWelcomeInitialViewController.wmf_viewControllerFromDescriptionWelcomeStoryboard()
            welcomeVC.completionBlock = {
                self.editFunnel.logTitleDescriptionReadyToEditFrom(from: funnelSource, isAddingNewTitleDescription: descriptionSource == .none, language: self.articleLanguage)
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
            } else {
                self.editFunnel.logTitleDescriptionReadyToEditFrom(from: funnelSource, isAddingNewTitleDescription: descriptionSource == .none, language: self.articleLanguage)
            }
        }
    }
    
    func showEditSectionOrTitleDescriptionDialogForSection(with id: Int, descriptionSource: ArticleDescriptionSource, selectedTextEditInfo: SelectedTextEditInfo? = nil, funnelSource: EditFunnelSource) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        
        let editTitleDescriptionTitle = WMFLocalizedString("description-edit-pencil-title", value: "Edit title description", comment: "Title for button used to show title description editor")
        let editTitleDescriptionAction = UIAlertAction(title: editTitleDescriptionTitle, style: .default) { (action) in
            self.showTitleDescriptionEditor(with: descriptionSource, funnelSource: funnelSource)
        }
        sheet.addAction(editTitleDescriptionAction)
        
        let editLeadSectionTitle = WMFLocalizedString("description-edit-pencil-introduction", value: "Edit introduction", comment: "Title for button used to show article lead section editor")
        let editLeadSectionAction = UIAlertAction(title: editLeadSectionTitle, style: .default) { (action) in
            self.showEditorForSection(with: id, selectedTextEditInfo: selectedTextEditInfo, funnelSource: funnelSource)
        }
        sheet.addAction(editLeadSectionAction)
        
        sheet.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel))

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
                    DDLogDebug("Failure in articleHtmlTitleDescription: \(error)")
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
}

extension ArticleViewController: SectionEditorViewControllerDelegate {
    func sectionEditorDidFinishEditing(_ sectionEditor: SectionEditorViewController, result: Result<SectionEditorChanges, Error>) {
        switch result {
        case .failure(let error):
            showError(error)
        case .success(let changes):
            dismiss(animated: true)
            waitForNewContentAndRefresh(changes.newRevisionID)
        }
    }
    
    func sectionEditorDidCancelEditing(_ sectionEditor: SectionEditorViewController) {
        dismiss(animated: true)
    }

    func sectionEditorDidFinishLoadingWikitext(_ sectionEditor: SectionEditorViewController) {
        
    }
}

extension ArticleViewController: DescriptionEditViewControllerDelegate {
    func descriptionEditViewControllerEditSucceeded(_ descriptionEditViewController: DescriptionEditViewController, revisionID: UInt64?) {
        waitForNewContentAndRefresh(revisionID)
    }
}

// Save these strings in case we need them - right now I don't think mobile-html even sends the event if they can't edit
//WMFLocalizedStringWithDefaultValue(@"page-protected-can-not-edit-title", nil, nil, @"This page is protected", @"Title of alert dialog shown when trying to edit a page that is protected beyond what the user can edit.")
//WMFLocalizedStringWithDefaultValue(@"page-protected-can-not-edit", nil, nil, @"You do not have the rights to edit this page", @"Text of alert dialog shown when trying to edit a page that is protected beyond what the user can edit.")
