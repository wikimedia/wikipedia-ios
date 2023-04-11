import Foundation

extension UISearchBar: Themeable {
    public func apply(theme: Theme) {
        wmf_enumerateSubviewTextFields { (textField) in
            textField.textColor = theme.colors.primaryText
            textField.keyboardAppearance = theme.keyboardAppearance
        }
        searchTextPositionAdjustment = UIOffset(horizontal: 7, vertical: 0)
        setSearchFieldBackgroundImage(theme.searchFieldBackgroundImage, for: .normal)
        
        if let placeholder = searchTextField.placeholder {
            let placeholderAttributes = [NSAttributedString.Key.foregroundColor: theme.colors.secondaryText]
            searchTextField.attributedPlaceholder = NSAttributedString(string: placeholder,
                                                                attributes: placeholderAttributes)
        }
        searchTextField.leftView?.tintColor = theme.colors.secondaryText
    }
}
