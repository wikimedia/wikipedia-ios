extension ArticleViewController {
    
    @objc func shareMenuItemTapped() {
        self.shareArticle()
    }
    
    @objc func editMenuItemTapped() {
        webView.wmf_getSelectedTextEditInfo { [weak self] (editInfo, error) in
            guard let self,
                  let editInfo = editInfo else {
                self?.showError(error ?? RequestError.unexpectedResponse)
                return
            }

            if editInfo.isSelectedTextInTitleDescription, let descriptionSource = editInfo.descriptionSource, descriptionSource == .central {
                // Only show the description editor if the description is from Wikidata (descriptionSource == .central)
                self.showTitleDescriptionEditor(with: .unknown)
            } else {
                // Otherwise it needs to be changed in the wikitext editor by editing the {{Short description}} template
                self.showEditorForSection(with: editInfo.sectionID, selectedTextEditInfo: editInfo)
            }
            
            if let project = WikimediaProject(siteURL: articleURL) {
                EditInteractionFunnel.shared.logArticleSelectDidTapEditContextMenu(project: project)
            }
            EditAttemptFunnel.shared.logInit(pageURL: self.articleURL)
        }
    }
}
