extension ArticleViewController: SectionEditorViewControllerDelegate {
    func sectionEditorDidFinishEditing(_ sectionEditor: SectionEditorViewController, withChanges didChange: Bool) {
        
    }
    
    func sectionEditorDidFinishLoadingWikitext(_ sectionEditor: SectionEditorViewController) {
        
    }
    
    func showEditorForSection(with id: Int) {
        
    }
    
//    func showEditor(for sectionID: Int, selectedTextEditInfo: SelectedTextEditInfo?, source: EditFunnelSource) {
//        editFunnel.logSectionEditingStart(from: source, language: articleLanguage)
//
//        cancelWIconPopoverDisplay()
//        let sectionEditVC = SectionEditorViewController()
//        sectionEditVC.section = section
//        sectionEditVC.delegate = self
//        sectionEditVC.editFunnel = editFunnel
//        sectionEditVC.dataStore = dataStore
//        sectionEditVC.selectedTextEditInfo = selectedTextEditInfo
//
//        let navigationController = WMFThemeableNavigationController(rootViewController: sectionEditVC, theme: theme)
//        navigationController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
//
//        let needsIntro = !UserDefaults.standard.didShowEditingOnboarding
//        if needsIntro {
//            navigationController.view.alpha = 0
//        }
//
//        sectionEditVC.shouldFocusWebView = !needsIntro
//        weakify(self)
//        let showIntro: (() -> Void)? = {
//                strongify(self)
//                self.editFunnel.logOnboardingPresentationInitiated(by: source, language: articleLanguage)
//                let editingWelcomeViewController = WMFEditingWelcomeViewController(theme: self.theme) {
//                        sectionEditVC.shouldFocusWebView = true
//                    }
//                editingWelcomeViewController.applyTheme(self.theme)
//                navigationController.present(editingWelcomeViewController, animated: true) {
//                    UserDefaults.standard.didShowEditingOnboarding = true
//                    navigationController.view.alpha = 1
//                }
//            }
//        present(navigationController, animated: !needsIntro) {
//            if needsIntro {
//                showIntro?()
//            }
//        }
//    }
//    
//    func descriptionEditViewControllerEditSucceeded(_ descriptionEditViewController: DescriptionEditViewController?) {
//        reload()
//    }
}
