import SwiftUI
import UIKit

/// Hosts a SwiftUI view as the custom view of a `UIBarButtonItem`.
///
/// The bar reads the size of a custom view when the item is set. A bare hosting view reports
/// no intrinsic size until SwiftUI lays it out, so the bar collapses the item. This view
/// measures the content synchronously and keeps the frame in sync with that size.
///
/// The content is type-erased on purpose: a generic `UIView` subclass makes the Swift 6.3
/// optimizer crash on the class deinit (EarlyPerfInliner), which breaks the release builds
/// of the UI tests.
public final class WMFBarButtonHostingView: UIView {

    private let hostingController: UIHostingController<AnyView>

    public init<Content: View>(rootView: Content) {
        hostingController = UIHostingController(rootView: AnyView(rootView))
        super.init(frame: .zero)

        backgroundColor = .clear
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        frame.size = intrinsicContentSize

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: Self, _) in
            view.invalidateIntrinsicContentSize()
            view.frame.size = view.intrinsicContentSize
        }
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setRootView<Content: View>(_ rootView: Content) {
        hostingController.rootView = AnyView(rootView)
        invalidateIntrinsicContentSize()
        frame.size = intrinsicContentSize
    }

    public override var intrinsicContentSize: CGSize {
        hostingController.sizeThatFits(in: UIView.layoutFittingExpandedSize)
    }
}

public extension UIBarButtonItem {

    /// Makes an item that shows a SwiftUI view. The item has no action of its own; give the
    /// content its own controls when it needs to respond to taps.
    ///
    /// On iPhone Duo the horizontal bar collapses and the system moves the items to a vertical
    /// bar. A custom view stays horizontal by default, so it disappears there. Small content
    /// like a badge fits the vertical bar, so the item prefers it unless `fitsVerticalBar` is
    /// false.
    @MainActor
    static func hostingBarButtonItem<Content: View>(rootView: Content, fitsVerticalBar: Bool = true) -> UIBarButtonItem {
        let item = UIBarButtonItem(customView: WMFBarButtonHostingView(rootView: rootView))
        if #available(iOS 26, *) {
            item.hidesSharedBackground = true
        }
        if fitsVerticalBar, #available(iOS 27.1, *) {
            // `axisBehavior` is typed only in the iOS 27.1 SDK and CI builds with an older Xcode,
            // so the value is set by key. 2 is `UIBarButtonItem.AxisBehavior.verticalPreferred`.
            item.setValue(2, forKey: "axisBehavior")
        }
        return item
    }
}
