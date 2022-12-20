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

class CustomNavigationView: SetupView, Themeable {
    
    enum ShadowBehavior {
        case alwaysShow
        case showUponScroll
        case alwaysHide
    }
    
    private let stackView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    
    private lazy var shadowView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        view.alpha = 0
        return view
    }()
    
    private let shadowBehavior: ShadowBehavior
    
    init(shadowBehavior: ShadowBehavior) {
        self.shadowBehavior = shadowBehavior
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        super.setup()
        
        addSubview(stackView)
        addSubview(shadowView)
        
        NSLayoutConstraint.activate([
            safeAreaLayoutGuide.topAnchor.constraint(equalTo: stackView.topAnchor),
            leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            
            leadingAnchor.constraint(equalTo: shadowView.leadingAnchor),
            trailingAnchor.constraint(equalTo: shadowView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor),
            shadowView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale)
        ])
        
        backgroundColor = .white
        
        switch shadowBehavior {
        case .alwaysShow:
            shadowView.alpha = 1
        case .alwaysHide, .showUponScroll:
            shadowView.alpha = 0
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        switch shadowBehavior {
        case .showUponScroll:
            let percentCollapsed = stackView.frame.height / totalHeight
            
            UIView.animate(withDuration: 0.2) {
                self.shadowView.alpha = 1 - percentCollapsed
            }
        default:
            break
        }
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
    
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        stackView.backgroundColor = theme.colors.paperBackground
        stackView.arrangedSubviews.forEach({ ($0 as? Themeable)?.apply(theme: theme) })
        shadowView.backgroundColor = theme.colors.chromeShadow
    }
}

class CustomNavigationViewData: ObservableObject {
    @Published var scrollAmount = CGFloat(0)
    @Published var visibleHeight = CGFloat(0)
    @Published var totalHeight = CGFloat(0)
}

private protocol CustomNavigationViewControlling: UIViewController, Themeable {
    var data: CustomNavigationViewData { get }
    var scrollAmountCancellable: AnyCancellable? { get set }
    var customNavigationView: CustomNavigationView { get }
    var customNavigationViewSubviews: [CustomNavigationViewShiftingSubview] { get }
    var theme: Theme { get set }
    var shadowBehavior: CustomNavigationView.ShadowBehavior { get }
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
    
    func sharedApplyTheme(theme: Theme) {
        self.theme = theme
        customNavigationView.apply(theme: theme)
    }
    
    func createCustomNavigationView() -> CustomNavigationView {
        let navigationView = CustomNavigationView(shadowBehavior: shadowBehavior)
        navigationView.translatesAutoresizingMaskIntoConstraints = false
        return navigationView
    }
}

// Use for SwiftUI Content (UIHostingControllers)

class CustomNavigationViewHostingController<Content>: UIHostingController<Content>, CustomNavigationViewControlling where Content: View {

    var customNavigationViewSubviews: [CustomNavigationViewShiftingSubview] {
        fatalError("Must implement in subclass")
    }
    
    // Override if needed
    var shadowBehavior: CustomNavigationView.ShadowBehavior {
        return .showUponScroll
    }
    
    var data: CustomNavigationViewData {
        fatalError("Must implement in subclass")
    }
    
    var scrollAmountCancellable: AnyCancellable?
    
    lazy var customNavigationView: CustomNavigationView = {
        return createCustomNavigationView()
    }()
    
    var theme: Theme
    
    init(rootView: Content, theme: Theme) {
        self.theme = theme
        super.init(rootView: rootView)
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
    
    func apply(theme: Theme) {
        sharedApplyTheme(theme: theme)
    }
}

// Use for UIKit Content (UIScrollViews)

class CustomNavigationViewController: UIViewController, CustomNavigationViewControlling, UIScrollViewDelegate {
    
    var data = CustomNavigationViewData()
    var scrollAmountCancellable: AnyCancellable?
    
    lazy var customNavigationView: CustomNavigationView = {
        return createCustomNavigationView()
    }()
    
    // Override if needed
    var shadowBehavior: CustomNavigationView.ShadowBehavior {
        return .showUponScroll
    }
    
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
            scrollView.delegate = self
        }
    }
    
    var theme: Theme
    
    init(theme: Theme) {
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sharedViewDidLoad()
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
    
    // MARK: UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollAmount = scrollView.contentInset.top + scrollView.contentOffset.y
        self.data.scrollAmount = scrollAmount
    }
    
    func apply(theme: Theme) {
        sharedApplyTheme(theme: theme)
    }
}
