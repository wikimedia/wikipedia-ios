extension ArticleViewController {
    func updateMenuItems() {
        let shareMenuItemTitle = CommonStrings.shareMenuTitle
        let shareMenuItem = UIMenuItem(title: shareMenuItemTitle, action: #selector(shareMenuItemTapped))
        let editMenuItemTitle = WMFLocalizedString("edit-menu-item", value: "Edit", comment: "Button label for text selection 'Edit' menu item")
        let editMenuItem = UIMenuItem(title: editMenuItemTitle, action: #selector(editMenuItemTapped))
        
        UIMenuController.shared.menuItems = [editMenuItem, shareMenuItem]
    }
    
    @objc func shareMenuItemTapped() {
        webView.wmf_getSelectedText { (text) in
            self.shareArticle(with: text)
        }
    }
    
    @objc func editMenuItemTapped() {
        webView.wmf_getSelectedTextEditInfo { (editInfo, error) in
            guard let editInfo = editInfo else {
                self.showError(error ?? RequestError.unexpectedResponse)
                return
            }

            if editInfo.isSelectedTextInTitleDescription, let descriptionSource = editInfo.descriptionSource, descriptionSource == .central {
                // Only show the description editor if the description is from Wikidata (descriptionSource == .central)
                self.showTitleDescriptionEditor(with: .unknown, funnelSource: .highlight)
            } else {
                // Otherwise it needs to be changed in the section editor by editing the {{Short description}} template
                self.showEditorForSection(with: editInfo.sectionID, selectedTextEditInfo: editInfo, funnelSource: .highlight)
            }
        }
    }
}
