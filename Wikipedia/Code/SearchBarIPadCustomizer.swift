import UIKit

/// Encapsulates the iPad 26 (regular-width) custom back-chevron and clear-button workarounds
/// for `UISearchController`.
///
/// On iPad 26 in regular width, `UISearchController` renders the search bar inline in the
/// navigation bar without a visible Cancel button. This helper installs:
///   - A chevron ← button as the left view (dismisses the search controller)
///   - A custom ✕ clear button as the right view (clears text, hides itself when bar is empty)
///
/// ## Pattern A — VC owns its own `UISearchController` with no `searchResultsController`
/// Used by `SavedViewController` and `PlacesViewController`.
/// Pass the configurator directly as `searchControllerDelegate` in `WMFNavigationBarSearchConfig`
/// so UIKit calls its delegate methods automatically. Call `updateClearButtonVisibility` whenever
/// the search text changes.
///
/// ```swift
/// private lazy var iPadSearchConfigurator = SearchBarIPadConfigurator(theme: theme)
///
/// private func configureNavigationBar() {
///     let searchConfig = WMFNavigationBarSearchConfig(
///         searchResultsController: nil,
///         searchControllerDelegate: iPadSearchConfigurator,
///         ...
///     )
///     configureNavigationBar(..., searchBarConfig: searchConfig, ...)
/// }
///
/// override func apply(theme: Theme) {
///     super.apply(theme: theme)
///     iPadSearchConfigurator.theme = theme
/// }
///
/// // Call from UISearchBarDelegate.searchBar(_:textDidChange:)
/// // or UISearchResultsUpdating.updateSearchResults(for:):
/// iPadSearchConfigurator.updateClearButtonVisibility(text: searchText, for: searchController)
/// ```
///
/// ## Pattern B — `UISearchController` uses a `searchResultsController`
/// Used internally by `SearchResultsViewController`, which is itself the
/// `UISearchControllerDelegate` for all contexts that embed it (Explore, Article, Search tab).
/// The results VC holds an instance, keeps its theme in sync, calls the delegate methods
/// directly from its own `UISearchControllerDelegate` conformance, and calls
/// `updateClearButtonVisibility` from `updateSearchResults(for:)`.
/// Host VCs using `SearchResultsViewController` do not interact with this class at all.
///
/// Use `onClearTapped` and `onWillDismiss` closures to reset any additional VC-specific state
/// when the clear button is tapped or the search bar is dismissed.
final class SearchBarIPadCustomizer: NSObject, UISearchControllerDelegate {

    // MARK: - Public

    var theme: Theme

    /// Called after the iPad-specific button setup in `willPresentSearchController`.
    var onWillPresent: (() -> Void)?

    /// Called after the iPad-specific button teardown in `willDismissSearchController`.
    /// Use this to reset any search state the host VC owns (e.g. clearing results, resetting a view model).
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

    /// Called when the custom ✕ clear button is tapped, after the bar text has been cleared.
    /// Use this to reset any additional state the host VC owns (e.g. clearing a results list or suggestion model).
    var onClearTapped: ((UISearchController?) -> Void)?

    /// Syncs the custom clear button's visibility with whether the bar has non-whitespace text.
    /// Call this whenever the search bar text changes — from `UISearchBarDelegate.searchBar(_:textDidChange:)`
    /// or `UISearchResultsUpdating.updateSearchResults(for:)`.
    func updateClearButtonVisibility(text: String, for searchController: UISearchController) {
        guard isIPad26RegularHSizeClass, let clearButton = customClearButton else { return }
        let hasText = text.wmf_hasNonWhitespaceText
        searchController.searchBar.searchTextField.rightView = hasText ? clearButton : nil
    }
}
