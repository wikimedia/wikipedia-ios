import Foundation
import SwiftUI
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

private protocol CustomNavigationBarHandling: UIViewController {
    var data: CustomNavigationBarData { get }
    var contentOffsetCancellable: AnyCancellable? { get set }
    var customNavigationBar: CustomNavigationBar { get }
}

// Shared Helper Methods

private extension CustomNavigationBarHandling {
    func sharedViewDidLoad() {
        setupCustomNavigationBar()
    }
    
    func sharedViewDidLayoutSubviews() {
        data.totalBarHeight = customNavigationBar.totalHeight
        print("customNavigationBar.bounds.height: \(customNavigationBar.bounds.height)")
    }
    
    func setupCustomNavigationBar() {
        
        guard viewIfLoaded != nil else {
            assertionFailure("View not loaded")
            return
        }
        
        navigationController?.isNavigationBarHidden = true

        view.addSubview(customNavigationBar)
        
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: customNavigationBar.topAnchor),
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: customNavigationBar.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: customNavigationBar.trailingAnchor)
        ])
        
        // Add custom subviews
        customNavigationBar.addCollapsingSubviews(views: customNavigationBarSubviews)
        
        // Initial layout to get data correctly populated initially
        // Without this, data.totalBarHeight doesn't seem to get set properly upon first load.
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // Setup contentOffset listener, pass it through into custom subviews
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
    
    var customNavigationBarSubviews: [CustomNavigationBarSubviewHeightAdjusting] {
        fatalError("Must implement in specific subclass")
    }
    
    func createCustomNavigationBar() -> CustomNavigationBar {
        let navigationBar = CustomNavigationBar(frame: .zero)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        return navigationBar
    }
}

// Use for SwiftUI Content (UIHostingControllers)

class CustomNavigationBarSwiftUIViewController<Content>: UIHostingController<Content>, CustomNavigationBarHandling where Content: View {
    
    var data: CustomNavigationBarData {
        fatalError("Must implement in subclass")
    }
    
    static var data: CustomNavigationBarData {
        return CustomNavigationBarData()
    }
    
    var contentOffsetCancellable: AnyCancellable?
    
    lazy var customNavigationBar: CustomNavigationBar = {
        return createCustomNavigationBar()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sharedViewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        sharedViewDidLayoutSubviews()
    }
}

// Use for UIKit Content (UIScrollViews)

class CustomNavigationBarViewController: UIViewController, CustomNavigationBarHandling {
    
    var data = CustomNavigationBarData()
    var contentOffsetCancellable: AnyCancellable?
    
    lazy var customNavigationBar: CustomNavigationBar = {
        let navigationBar = CustomNavigationBar(frame: .zero)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        return navigationBar
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sharedViewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        sharedViewDidLayoutSubviews()
    }
}
