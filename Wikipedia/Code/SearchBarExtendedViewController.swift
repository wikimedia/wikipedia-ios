import UIKit

protocol SearchBarExtendedViewControllerDataSource: class {
    // defaults to .search
    func returnKeyType(for searchBar: UISearchBar) -> UIReturnKeyType
    func placeholder(for searchBar: UISearchBar) -> String?
    // defaults to false
    func isSeparatorViewHidden(above searchBar: UISearchBar) -> Bool
}

protocol SearchBarExtendedViewControllerDelegate: class {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
}

class SearchBarExtendedViewController: UIViewController {
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var button: UIButton!
    
    weak var dataSource: SearchBarExtendedViewControllerDataSource?
    weak var delegate: SearchBarExtendedViewControllerDelegate?
    
    private var theme = Theme.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        searchBar.returnKeyType = dataSource?.returnKeyType(for: searchBar) ?? .search
        searchBar.placeholder = dataSource?.placeholder(for: searchBar)
        separatorView.isHidden = dataSource?.isSeparatorViewHidden(above: searchBar) ?? false
        apply(theme: theme)
    }

}

extension SearchBarExtendedViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        delegate?.searchBar(searchBar, textDidChange: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        delegate?.searchBarSearchButtonClicked(searchBar)
    }
}

extension SearchBarExtendedViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        separatorView.backgroundColor = theme.colors.border
        searchBar.wmf_enumerateSubviewTextFields{ (textField) in
            textField.textColor = theme.colors.primaryText
            textField.keyboardAppearance = theme.keyboardAppearance
        }
    }
}
