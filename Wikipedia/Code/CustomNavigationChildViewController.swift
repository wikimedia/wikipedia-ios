import UIKit
import Combine

class CustomNavigationChildView: UIView {
    
    var customNavigationViewSubviews: [CustomNavigationViewShiftingSubview] = []
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !UIAccessibility.isVoiceOverRunning else {
            return super.point(inside: point, with: event)
        }
        
        for subview in customNavigationViewSubviews {
            let convertedPoint = convert(point, to: subview)
            if subview.point(inside: convertedPoint, with: event) {
                return true
            }
        }

        return false
    }
}

class CustomNavigationChildViewController: ThemeableViewController {
    
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
    
    private var childView: CustomNavigationChildView {
        return view as! CustomNavigationChildView
    }
    
    enum ShadowBehavior {
        case alwaysShow
        case showUponScroll
        case alwaysHide
    }
    
    let data = CustomNavigationViewData()
    private let shadowBehavior: ShadowBehavior
    private var customNavigationViewSubviews: [CustomNavigationViewShiftingSubview] = []
    private var scrollAmountCancellable: AnyCancellable?
    private var totalHeightCancellable: AnyCancellable?
    private var isLoadingCancellable: AnyCancellable?
    weak var scrollView: UIScrollView? {
        didSet {
            scrollView?.contentInsetAdjustmentBehavior = .never
            scrollView?.automaticallyAdjustsScrollIndicatorInsets = false
            
            // Ensures contentInset values are retained in case scroll views switched (from empty state scroll view to populated state scroll view, for example)
            if let oldValue,
                let scrollView {
                scrollView.contentInset = oldValue.contentInset
            }
        }
    }
    
    init(shadowBehavior: ShadowBehavior) {
        self.shadowBehavior = shadowBehavior
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let childView = CustomNavigationChildView(frame: .zero)
        view = childView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(stackView)
        view.addSubview(shadowView)
        
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: stackView.topAnchor),
            view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            
            view.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor),
            shadowView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale)
        ])
        
        switch shadowBehavior {
        case .alwaysShow:
            shadowView.alpha = 1
        case .alwaysHide, .showUponScroll:
            shadowView.alpha = 0
        }
        
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
        
        self.totalHeightCancellable = data.$totalHeight.sink(receiveValue: { [weak self] totalHeight in

            guard let scrollView = self?.scrollView else {
                return
            }

            if scrollView.contentInset.top != totalHeight {
                scrollView.contentInset = UIEdgeInsets(top: totalHeight, left: 0, bottom: 0, right: 0)
                scrollView.verticalScrollIndicatorInsets = UIEdgeInsets(top: totalHeight, left: 0, bottom: 0, right: 0)
                
                if -1 * scrollView.contentOffset.y < scrollView.contentInset.top {
                    var contentOffset = scrollView.contentOffset
                    contentOffset.y = -1 * scrollView.contentInset.top
                    scrollView.setContentOffset(contentOffset, animated: false)
                }
            }
        })
        
        self.isLoadingCancellable = data.$isLoading.sink(receiveValue: { [weak self] isLoading in
            
            guard let self = self else {
                return
            }
            
            let loadableShiftingSubview = self.customNavigationViewSubviews.first { $0 is Loadable } as? Loadable
            
            if isLoading {
                loadableShiftingSubview?.startLoading()
            } else {
                loadableShiftingSubview?.stopLoading()
            }
        })
        
        apply(theme: theme)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        switch shadowBehavior {
        case .showUponScroll:
            let percentCollapsed = stackView.frame.height / totalHeight
            
            UIView.animate(withDuration: 0.2) {
                self.shadowView.alpha = 1 - percentCollapsed
            }
        default:
            break
        }
        
        if self.data.totalHeight != totalHeight {
            self.data.totalHeight = totalHeight
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
    
    func removeShiftingSubview(_ removingSubview: CustomNavigationViewShiftingSubview) {
        customNavigationViewSubviews = customNavigationViewSubviews.filter { $0 !== removingSubview }
        childView.customNavigationViewSubviews = customNavigationViewSubviews
        removingSubview.removeFromSuperview()
    }
    
    func addShiftingSubviews(views: [CustomNavigationViewShiftingSubview]) {
        customNavigationViewSubviews.append(contentsOf: views)
        childView.customNavigationViewSubviews = customNavigationViewSubviews
        views.forEach { stackView.addArrangedSubview($0) }
        
        stackView.setNeedsLayout()
        stackView.layoutIfNeeded()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollAmount = scrollView.contentInset.top + scrollView.contentOffset.y
        data.scrollAmount = scrollAmount
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        stackView.backgroundColor = theme.colors.paperBackground
        stackView.arrangedSubviews.forEach({ ($0 as? Themeable)?.apply(theme: theme) })
        shadowView.backgroundColor = theme.colors.chromeShadow
    }
}
