import SwiftUI
import UIKit

/// Wraps the system search bar so screens that can't host a `UISearchController` (e.g. the
/// onboarding interests step, which has no navigation bar) still get the same search bar the
/// rest of the app uses — including its icons, font, metrics, and cancel button.
struct WMFSearchBarRepresentable: UIViewRepresentable {

    @Binding var text: String
    /// Two-way: the delegate reports editing changes, and setting it to false resigns the
    /// keyboard (e.g. after the user picks a search result).
    @Binding var isFocused: Bool
    let placeholder: String
    let theme: WMFTheme
    let accessibilityIdentifier: String?
    let onCancel: () -> Void

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = context.coordinator
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.searchTextField.accessibilityIdentifier = accessibilityIdentifier
        return searchBar
    }

    func updateUIView(_ searchBar: UISearchBar, context: Context) {
        context.coordinator.parent = self

        if searchBar.text != text {
            searchBar.text = text
        }

        // UIKit doesn't inherit the SwiftUI colorScheme, so drive it from the theme.
        searchBar.overrideUserInterfaceStyle = theme.userInterfaceStyle
        searchBar.tintColor = theme.link
        searchBar.searchTextField.textColor = theme.text
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: theme.secondaryText]
        )

        if !isFocused && searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UISearchBarDelegate {

        var parent: WMFSearchBarRepresentable

        init(_ parent: WMFSearchBarRepresentable) {
            self.parent = parent
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            parent.text = searchText
        }

        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            searchBar.setShowsCancelButton(true, animated: true)
            parent.isFocused = true
        }

        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            searchBar.setShowsCancelButton(false, animated: true)
            parent.isFocused = false
        }

        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
            parent.onCancel()
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
    }
}
