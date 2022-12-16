import Foundation
import SwiftUI
import UIKit
import Combine

enum ShiftingStatus {
    public typealias Amount = CGFloat
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
        print(data.totalHeight)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        print(data.totalHeight)

        self.scrollAmountCancellable = data.$scrollAmount.sink { [weak self] scrollAmount in
            
            guard let self = self else {
                return
            }
            
            // Setup contentOffset listener, pass it through into custom subviews
            let sortedSubviews = self.customNavigationViewSubviews.sorted {
                $0.order < $1.order
            }

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
    
    func sharedAppendShiftingSubview(_ subview: CustomNavigationViewShiftingSubview) {
        customNavigationView.addShiftingSubviews(views: [subview])
        
        customNavigationView.setNeedsLayout()
        customNavigationView.layoutIfNeeded()
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
    
    func appendShiftingSubview(_ subview: CustomNavigationViewShiftingSubview) {
        sharedAppendShiftingSubview(subview)
    }
}

// Use for UIKit Content (UIScrollViews)

class CustomNavigationViewController: UIViewController, CustomNavigationViewControlling, UIScrollViewDelegate {
    
    var data = CustomNavigationViewData()
    var scrollAmountCancellable: AnyCancellable?
    
    lazy var customNavigationView: CustomNavigationView = {
        return createCustomNavigationView()
    }()
    
    var customNavigationViewSubviews: [CustomNavigationViewShiftingSubview] {
        fatalError("Must implement in subclass")
    }
    
    var scrollView: UIScrollView {
        get {
            guard let scrollView = _scrollView else {
                fatalError("Must assign in subclass on load")
            }
            
            return scrollView
        }
        set {
            _scrollView = newValue
        }
    }
    private var _scrollView: UIScrollView? {
        didSet {
            scrollView.contentInsetAdjustmentBehavior = .never
            scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sharedViewDidLoad()
        
        // hide missing bottom toolbar color pain
        view.backgroundColor = .white
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        sharedViewDidLayoutSubviews()
        
        // Update content inset according to total height of custom navigation bar
        if scrollView.contentInset.top != data.totalHeight {
            let oldInsetTop = scrollView.contentInset.top
            scrollView.contentInset = UIEdgeInsets(top: data.totalHeight, left: 0, bottom: 0, right: 0)
            scrollView.verticalScrollIndicatorInsets = UIEdgeInsets(top: data.totalHeight, left: 0, bottom: 0, right: 0)
            
            
            // This fixes a bug upon first load where content initially appears underneath navigation view
            // This seems to be a one-time fix needed only for UITableViews, not UICollectionViews.
            // Also seeing a warning "UITableView was told to layout its visible cells and other contents without being in the view hierarchy (the table view or one of its superviews has not been added to a window).". Fixing that may remove the need for this.
            if Int(-1 * scrollView.contentOffset.y) == Int(oldInsetTop) { // && (-1 * scrollView.contentOffset.y) < data.totalHeight {
                var contentOffset = scrollView.contentOffset
                contentOffset.y = -1 * data.totalHeight
                scrollView.setContentOffset(contentOffset, animated: false)
            }
        }
    }
    
    func appendShiftingSubview(_ subview: CustomNavigationViewShiftingSubview) {
        sharedAppendShiftingSubview(subview)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollAmount = scrollView.contentInset.top + scrollView.contentOffset.y
        self.data.scrollAmount = scrollAmount
    }
}
