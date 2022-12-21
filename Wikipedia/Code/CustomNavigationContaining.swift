import Foundation
import SwiftUI
import UIKit
import Combine

enum ShiftingStatus {
    public typealias Amount = CGFloat
    case shifted(Amount) // AKA completed shifting. Returns the amount that was shifted.
    case shifting
}

protocol CustomNavigationViewShiftingSubview: UIView, Themeable {
    var order: Int { get } // The order the subview begins shifting, compared to the other subviews
    var contentHeight: CGFloat { get } // The height of it's full content, regardless of how much it has collapsed.
    func shift(amount: CGFloat) -> ShiftingStatus // The amount to shift, starting at 0.
}

class CustomNavigationViewData: ObservableObject {
    @Published var scrollAmount = CGFloat(0)
    @Published var totalHeight = CGFloat(0)
}

protocol CustomNavigationContaining: UIViewController {
    var navigationViewChildViewController: CustomNavigationChildViewController? { get set }
}

// Shared Helper Methods

extension CustomNavigationContaining {
    
    func setup(shiftingSubviews: [CustomNavigationViewShiftingSubview], shadowBehavior: CustomNavigationChildViewController.ShadowBehavior, swiftuiView: some View) {
        
        navigationController?.isNavigationBarHidden = true
        
        let childNavigationViewVC = CustomNavigationChildViewController(shadowBehavior: shadowBehavior)
        
        // Add hosting child VC
        let finalSwiftUIView = swiftuiView.environmentObject(childNavigationViewVC.data)
        let childHostingVC = UIHostingController(rootView: finalSwiftUIView)
        childHostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(childHostingVC.view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: childHostingVC.view.topAnchor),
            view.leadingAnchor.constraint(equalTo: childHostingVC.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: childHostingVC.view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: childHostingVC.view.bottomAnchor)
        ])
        
        addChild(childHostingVC)
        childHostingVC.didMove(toParent: self)
        
        // Add navigation child VC
        childNavigationViewVC.view.translatesAutoresizingMaskIntoConstraints = false
        childNavigationViewVC.addShiftingSubviews(views: shiftingSubviews)
        view.addSubview(childNavigationViewVC.view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: childNavigationViewVC.view.topAnchor),
            view.leadingAnchor.constraint(equalTo: childNavigationViewVC.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: childNavigationViewVC.view.trailingAnchor)
        ])
        
        addChild(childNavigationViewVC)
        childNavigationViewVC.didMove(toParent: self)
        self.navigationViewChildViewController = childNavigationViewVC
    }
    
    func setup(shiftingSubviews: [CustomNavigationViewShiftingSubview], shadowBehavior: CustomNavigationChildViewController.ShadowBehavior, scrollView: UIScrollView) {
        
        navigationController?.isNavigationBarHidden = true
        
        // Add scroll view if needed
        if scrollView.superview == nil {
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(scrollView)
            
            NSLayoutConstraint.activate([
                view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: scrollView.topAnchor),
                view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
            ])
        }
        
        // Add navigation child VC
        let childNavigationViewVC = CustomNavigationChildViewController(shadowBehavior: shadowBehavior)
        childNavigationViewVC.view.translatesAutoresizingMaskIntoConstraints = false
        childNavigationViewVC.addShiftingSubviews(views: shiftingSubviews)
        view.addSubview(childNavigationViewVC.view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: childNavigationViewVC.view.topAnchor),
            view.leadingAnchor.constraint(equalTo: childNavigationViewVC.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: childNavigationViewVC.view.trailingAnchor)
        ])
        
        addChild(childNavigationViewVC)
        childNavigationViewVC.didMove(toParent: self)
        self.navigationViewChildViewController = childNavigationViewVC
        
        childNavigationViewVC.scrollView = scrollView
    }
}
