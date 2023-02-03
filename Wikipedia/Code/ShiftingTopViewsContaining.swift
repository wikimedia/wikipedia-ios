import Foundation
import SwiftUI

protocol ShiftingTopViewsContaining: UIViewController {
    var shiftingTopViewsStack: ShiftingTopViewsStack? { get set }
}

// Note: This subclass only seems necessary for proper nav bar hiding in iOS 14 & 15. It can be removed and switched to raw UIHostingControllers for iOS16+
private class NavigationBarHidingHostingVC<Content: View>: UIHostingController<Content> {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.isNavigationBarHidden = true
    }
}

extension ShiftingTopViewsContaining {
    func setup(shiftingTopViews: [ShiftingTopView], shadowBehavior: ShiftingTopViewsStack.ShadowBehavior, swiftuiView: some View, observableTheme: ObservableTheme) {
        
        navigationController?.isNavigationBarHidden = true
        
        let shiftingTopViewsStack = ShiftingTopViewsStack(shadowBehavior: shadowBehavior)

        // Add needed environment objects to SwiftUI view, then embed hosting view controller, then embed SwiftUI hosting view controller
        let finalSwiftUIView = swiftuiView
            .environmentObject(shiftingTopViewsStack.data)
            .environmentObject(observableTheme)
        
        let childHostingVC: UIViewController

        if #available(iOS 16, *) {
            childHostingVC = UIHostingController(rootView: finalSwiftUIView)
        } else {
            childHostingVC = NavigationBarHidingHostingVC(rootView: finalSwiftUIView)
        }
        
        childHostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(childHostingVC.view)

        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: childHostingVC.view.topAnchor),
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: childHostingVC.view.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: childHostingVC.view.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: childHostingVC.view.bottomAnchor)
        ])

        addChild(childHostingVC)
        childHostingVC.didMove(toParent: self)
        childHostingVC.view.backgroundColor = .clear

        // Add shiftingTopViewsStack
        view.addSubview(shiftingTopViewsStack)

        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: shiftingTopViewsStack.topAnchor),
            view.leadingAnchor.constraint(equalTo: shiftingTopViewsStack.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: shiftingTopViewsStack.trailingAnchor)
        ])

        shiftingTopViewsStack.addShiftingTopViews(shiftingTopViews)
        shiftingTopViewsStack.apply(theme: observableTheme.theme)
        self.shiftingTopViewsStack = shiftingTopViewsStack
    }
}
