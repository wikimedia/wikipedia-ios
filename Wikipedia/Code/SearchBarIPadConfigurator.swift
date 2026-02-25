import UIKit

/// Encapsulates the iPad 26 (regular-width) custom back-chevron and clear-button workarounds
/// for any `UISearchController` that does **not** use a `searchResultsController`.
///
/// On iPad 26 in regular width, `UISearchController` renders the search bar inline in the
/// navigation bar without a visible Cancel button.  This helper installs:
///   - A chevron ← button as the left view (dismisses the search controller)
///   - A custom ✕ clear button as the right view (clears text, hides itself when bar is empty)
///
/// Usage:
/// ```swift
/// // 1. Declare as a lazy property on the host VC:
/// private lazy var iPadSearchConfigurator = SearchBarIPadConfigurator(theme: theme)
///
/// // 2. Pass as `searchControllerDelegate` in WMFNavigationBarSearchConfig:
/// let searchConfig = WMFNavigationBarSearchConfig(
///     searchResultsController: nil,
///     searchControllerDelegate: iPadSearchConfigurator,
///     ...
/// )
///
/// // 3. Keep theme in sync:
/// override func apply(theme: Theme) {
///     super.apply(theme: theme)
///     iPadSearchConfigurator.theme = theme
/// }
///
/// // 4. Forward text changes so the clear button stays in sync:
/// func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
///     if let sc = navigationItem.searchController {
///         iPadSearchConfigurator.updateClearButtonVisibility(text: searchText, for: sc)
///     }
///     // ... existing logic ...
/// }
/// ```
final class SearchBarIPadConfigurator: NSObject, UISearchControllerDelegate {

    // MARK: - Public

    var theme: Theme

    /// Called after the iPad-specific setup inside `willPresentSearchController`.
    var onWillPresent: (() -> Void)?

    /// Called after the iPad-specific teardown inside `willDismissSearchController`.
    var onWillDismiss: (() -> Void)?

    var onDidPresent: (() -> Void)?
    var onDidDismiss: (() -> Void)?

    // MARK: - Init

    init(theme: Theme) {
        self.theme = theme
    }

    // MARK: - Private

    private var customClearButton: UIButton?

    private var isIPad26RegularHSizeClass: Bool {
        if #available(iOS 26.0, *) {
            return UIDevice.current.userInterfaceIdiom == .pad &&
                   UITraitCollection.current.horizontalSizeClass == .regular
        }
        return false
    }

    // MARK: - UISearchControllerDelegate

    func willPresentSearchController(_ searchController: UISearchController) {
        if isIPad26RegularHSizeClass {
            searchController.searchBar.searchTextField.clearButtonMode = .never

            let backButton = UIButton(type: .system)
            backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
            backButton.tintColor = theme.colors.link
            backButton.addAction(UIAction { [weak searchController] _ in
                searchController?.isActive = false
            }, for: .touchUpInside)
            searchController.searchBar.searchTextField.leftView = backButton
            searchController.searchBar.searchTextField.leftViewMode = .always

            let clearButton = UIButton(type: .system)
            clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            clearButton.tintColor = theme.colors.secondaryText
            clearButton.addAction(UIAction { [weak searchController, weak self] _ in
                searchController?.searchBar.text = nil
                searchController?.searchBar.searchTextField.rightView = nil
                self?.onClearTapped?(searchController)
            }, for: .touchUpInside)
            customClearButton = clearButton
            searchController.searchBar.searchTextField.rightViewMode = .whileEditing
        }
        onWillPresent?()
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        if isIPad26RegularHSizeClass {
            let magnifyingGlass = UIImageView(image: UIImage(systemName: "magnifyingglass"))
            magnifyingGlass.tintColor = .secondaryLabel
            searchController.searchBar.searchTextField.leftView = magnifyingGlass
            searchController.searchBar.searchTextField.leftViewMode = .always
            customClearButton = nil
        }
        onWillDismiss?()
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        onDidPresent?()
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        onDidDismiss?()
    }

    // MARK: - Public helpers

    /// Optional hook called when the custom ✕ clear button is tapped, after the bar text
    /// has already been cleared. Use this if the host VC needs to reset additional state
    /// (e.g. clear a search view model, reset suggestions, etc.).
    var onClearTapped: ((UISearchController?) -> Void)?

    /// Call this whenever the search bar text changes so the custom clear button visibility
    /// stays in sync with whether there is text in the bar.
    func updateClearButtonVisibility(text: String, for searchController: UISearchController) {
        guard isIPad26RegularHSizeClass, let clearButton = customClearButton else { return }
        let hasText = text.wmf_hasNonWhitespaceText
        searchController.searchBar.searchTextField.rightView = hasText ? clearButton : nil
    }
}
