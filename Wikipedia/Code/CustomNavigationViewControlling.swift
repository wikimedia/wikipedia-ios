import Foundation
import SwiftUI
import UIKit
import Combine

enum ShiftingStatus {
    typealias Amount = CGFloat
    case shifted(Amount) // AKA completed shifting. Returns the amount that was shifted.
    case shifting
}

protocol CustomNavigationViewShiftingSubview: UIView {
    var order: Int { get } // The order the subview begins shifting, compared to the other subviews
    var contentHeight: CGFloat { get } // The height of it's full content, regardless of how much it has collapsed.
    func shift(amount: CGFloat) -> ShiftingStatus // The amount to shift, starting at 0.
}

class CustomNavigationView: SetupView {
    
    private let stackView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    override func setup() {
        super.setup()
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            safeAreaLayoutGuide.topAnchor.constraint(equalTo: stackView.topAnchor),
            safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
        
        backgroundColor = .white
    }
    
    var totalHeight: CGFloat {
        var totalHeight: CGFloat = 0
        for subview in stackView.arrangedSubviews {
            if let shiftingView = subview as? CustomNavigationViewShiftingSubview {
                totalHeight += shiftingView.contentHeight
            }
        }
    
        return totalHeight
    }
    
    func addShiftingSubviews(views: [CustomNavigationViewShiftingSubview]) {
        views.forEach { stackView.addArrangedSubview($0) }
    }
}

class CustomNavigationViewData: ObservableObject {
    @Published var scrollAmount = CGFloat(0)
    @Published var visibleHeight = CGFloat(0)
    @Published var totalHeight = CGFloat(0)
}

private protocol CustomNavigationViewControlling: UIViewController {
    var data: CustomNavigationViewData { get }
    var scrollAmountCancellable: AnyCancellable? { get set }
    var customNavigationView: CustomNavigationView { get }
    var customNavigationViewSubviews: [CustomNavigationViewShiftingSubview] { get }
}

// Shared Helper Methods

private extension CustomNavigationViewControlling {
    func sharedViewDidLoad() {
        setupCustomNavigationView()
    }
    
    func sharedViewDidLayoutSubviews() {
        if data.totalHeight != customNavigationView.totalHeight {
            data.totalHeight = customNavigationView.totalHeight
        }
    }
    
    func setupCustomNavigationView() {
        
        guard viewIfLoaded != nil else {
            assertionFailure("View not loaded")
            return
        }
        
        navigationController?.isNavigationBarHidden = true

        view.addSubview(customNavigationView)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: customNavigationView.topAnchor),
            view.leadingAnchor.constraint(equalTo: customNavigationView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: customNavigationView.trailingAnchor)
        ])
        
        // Add custom subviews
        customNavigationView.addShiftingSubviews(views: customNavigationViewSubviews)
        
        // Initial layout to get data correctly populated initially
        // Without this, data.totalHeight doesn't seem to get set properly upon first load.
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // Setup contentOffset listener, pass it through into custom subviews
        let sortedSubviews = customNavigationViewSubviews.sorted {
            $0.order < $1.order
        }
        
        self.scrollAmountCancellable = data.$scrollAmount.sink { scrollAmount in

            var offset: CGFloat = 0
            for subview in sortedSubviews {
                
                // We offset the scrollAmount so that each subview receives shifting amounts starting at zero
                let amount = scrollAmount + offset
                let shiftStatus = subview.shift(amount: amount)
                
                switch shiftStatus {
                case .shifted(let height):
                    offset -= height
                    continue
                case .shifting:
                    return
                }
            }
        }
    }
    
    func createCustomNavigationView() -> CustomNavigationView {
        let navigationView = CustomNavigationView(frame: .zero)
        navigationView.translatesAutoresizingMaskIntoConstraints = false
        return navigationView
    }
}

// Use for SwiftUI Content (UIHostingControllers)

class CustomNavigationViewHostingController<Content>: UIHostingController<Content>, CustomNavigationViewControlling where Content: View {

    var customNavigationViewSubviews: [CustomNavigationViewShiftingSubview] {
        fatalError("Must implement in subclass")
    }
    
    var data: CustomNavigationViewData {
        fatalError("Must implement in subclass")
    }
    
    var scrollAmountCancellable: AnyCancellable?
    
    lazy var customNavigationView: CustomNavigationView = {
        return createCustomNavigationView()
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

class CustomNavigationViewController: UIViewController, CustomNavigationViewControlling {
    
    var data = CustomNavigationViewData()
    var scrollAmountCancellable: AnyCancellable?
    
    lazy var customNavigationView: CustomNavigationView = {
        return createCustomNavigationView()
    }()
    
    var customNavigationViewSubviews: [CustomNavigationViewShiftingSubview] {
        fatalError("Must implement in subclass")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sharedViewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        sharedViewDidLayoutSubviews()
    }
}
