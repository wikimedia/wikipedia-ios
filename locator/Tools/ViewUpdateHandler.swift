import UIKit

/// Standard logic for views that need to show content loading states
struct ViewUpdateHandler {
    typealias UpdateViews = (loader: UIActivityIndicatorView, contentView: UIView, error: UIView)
    
    /// handles loading state transitions for loading, content and error views
    let handle: (UpdateState, UpdateViews) -> Void
    
    /// simple update handler implementation which hides all views except actual one
    static let showHideHandler: ViewUpdateHandler = .init { state, views in
        switch state {
        case .updating:
            views.loader.startAnimating()
            views.contentView.isHidden = true
            views.error.isHidden = true
        case .lastUpdateFailed:
            views.error.isHidden = false
            views.loader.stopAnimating()
            views.contentView.isHidden = true
        case .never:
            views.error.isHidden = true
            views.loader.isHidden = true
        case .updated:
            views.loader.stopAnimating()
            views.error.isHidden = true
            views.contentView.isHidden = false
        }
    }
}
