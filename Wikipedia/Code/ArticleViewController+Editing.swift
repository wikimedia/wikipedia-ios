extension ArticleViewController: SectionEditorViewControllerDelegate {
    func sectionEditorDidFinishEditing(_ sectionEditor: SectionEditorViewController, withChanges didChange: Bool) {
        
    }
    
    func sectionEditorDidFinishLoadingWikitext(_ sectionEditor: SectionEditorViewController) {
        
    }
    
    func showEditorForSection(with id: Int, descriptionSource: String?, selectedTextEditInfo: SelectedTextEditInfo? = nil, funnelSource: EditFunnelSource) {
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

}
