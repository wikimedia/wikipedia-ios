import Foundation
import UIKit
import Combine

protocol CustomNavigationBarSubviewCollapsing: UIView {
    var collapseOrder: Int { get }
    func updateContentOffset(contentOffset: CGPoint)
}

class CustomNavigationBarContentOffset: ObservableObject {
    @Published var point: CGPoint = .zero
}

class CustomNavigationBarContainerViewController: UIViewController {
    
    var contentOffset = CustomNavigationBarContentOffset()
    var contentOffsetCancellable: AnyCancellable?
    
    var childContentViewController: UIViewController {
        fatalError("Must subclass")
    }
    
    var collapsingNavigationBarSubviews: [CustomNavigationBarSubviewCollapsing] {
        fatalError("Must subclass")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCustomNavigationBar()
    }
    
    private func setupCustomNavigationBar() {
        
        guard viewIfLoaded != nil else {
            assertionFailure("View not loaded")
            return
        }
        
        navigationController?.isNavigationBarHidden = true
        
        // First add child VC
        addChild(childContentViewController)
        childContentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(childContentViewController.view)
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: childContentViewController.view.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: childContentViewController.view.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: childContentViewController.view.bottomAnchor)
        ])
        childContentViewController.didMove(toParent: self)
        
        // Then add custom navigation bar above
        let navigationBar = CustomNavigationBar(frame: .zero)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(navigationBar)
        
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: navigationBar.topAnchor),
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),
            childContentViewController.view.topAnchor.constraint(equalTo: navigationBar.bottomAnchor)
        ])
        
        navigationBar.addCollapsingSubviews(views: collapsingNavigationBarSubviews)
        
        self.contentOffsetCancellable = contentOffset.$point.sink { newOffset in
            self.collapsingNavigationBarSubviews.forEach { subview in
                subview.updateContentOffset(contentOffset: newOffset)
            }
        }
    }
}
