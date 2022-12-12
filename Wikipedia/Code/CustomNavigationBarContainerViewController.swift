import Foundation
import UIKit
import Combine

enum AdjustingStatus {
    typealias AmountAdjusted = CGFloat
    case complete(CGFloat)
    case adjusting
}

protocol CustomNavigationBarSubviewHeightAdjusting: UIView {
    var order: Int { get }
    var contentHeight: CGFloat { get }
    func updateContentOffset(contentOffset: CGPoint) -> AdjustingStatus
}

class CustomNavigationBarData: ObservableObject {
    @Published var contentOffset: CGPoint = .zero
    @Published var visibleBarHeight: CGFloat = .zero
    @Published var totalBarHeight: CGFloat = .zero
}

class CustomNavigationBarContainerViewController: UIViewController {
    
    var data = CustomNavigationBarData()
    var contentOffsetCancellable: AnyCancellable?
    
    var childContentViewController: UIViewController {
        fatalError("Must subclass")
    }
    
    var customNavigationBarSubviews: [CustomNavigationBarSubviewHeightAdjusting] {
        fatalError("Must subclass")
    }
    
    lazy var customNavigationBar: CustomNavigationBar = {
        let navigationBar = CustomNavigationBar(frame: .zero)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        return navigationBar
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCustomNavigationBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        data.totalBarHeight = customNavigationBar.totalHeight
        
        print("customNavigationBar.bounds.height: \(customNavigationBar.bounds.height)")
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
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: childContentViewController.view.topAnchor),
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: childContentViewController.view.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: childContentViewController.view.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: childContentViewController.view.bottomAnchor)
        ])
        childContentViewController.didMove(toParent: self)
        
        // Then add custom navigation bar above
        
        view.addSubview(customNavigationBar)
        
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: customNavigationBar.topAnchor),
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: customNavigationBar.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: customNavigationBar.trailingAnchor)
        ])
        
        customNavigationBar.addCollapsingSubviews(views: customNavigationBarSubviews)
        
        // Without this, data.totalBarHeight doesn't seem to get set properly upon first load.
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        let sortedSubviews = customNavigationBarSubviews.sorted {
            $0.order < $1.order
        }
        
        self.contentOffsetCancellable = data.$contentOffset.sink { newOffset in

            var adjustedDelta: CGFloat = 0
            for subview in sortedSubviews {
                
                let shiftedOffset = CGPoint(x: newOffset.x, y: newOffset.y + adjustedDelta)
                let adjustStatus = subview.updateContentOffset(contentOffset: shiftedOffset)
                
                switch adjustStatus {
                case .complete(let adjustedHeight):
                    adjustedDelta += adjustedHeight
                    continue
                case .adjusting:
                    return
                }
            }
        }
    }
}
