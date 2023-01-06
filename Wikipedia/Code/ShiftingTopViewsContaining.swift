import Foundation
import SwiftUI

protocol ShiftingTopViewsContaining: UIViewController {
    
}

extension ShiftingTopViewsContaining {
    func setup(swiftuiView: some View, observableTheme: ObservableTheme) {

        // Embed SwiftUI hosting view controller
        let finalSwiftUIView = swiftuiView
            .environmentObject(observableTheme)
        let childHostingVC = UIHostingController(rootView: finalSwiftUIView)

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
    }
}
