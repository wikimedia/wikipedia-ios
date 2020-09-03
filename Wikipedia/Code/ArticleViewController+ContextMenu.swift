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
            guard !editInfo.isSelectedTextInTitleDescription else {
                self.showTitleDescriptionEditor(with: .unknown, funnelSource: .highlight)
                return
            }
            self.showEditorForSection(with: editInfo.sectionID, selectedTextEditInfo: editInfo, funnelSource: .highlight)
        }
    }
}
