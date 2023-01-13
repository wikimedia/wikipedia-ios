import UIKit
import Combine

class ShiftingTopViewsStack: UIStackView, Themeable {
    
    let data = ShiftingTopViewsData()
    private var shiftingTopViews: [ShiftingTopView] = []
    
    private var scrollAmountCancellable: AnyCancellable?
    private var isLoadingCancellable: AnyCancellable?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        alignment = .fill
        distribution = .fill
        
        // Listen to scrollAmount changes and pass them through to shifting top views
        self.scrollAmountCancellable = data.$scrollAmount.sink { [weak self] scrollAmount in

            guard let self = self else {
                return
            }

            let sorted = self.shiftingTopViews.sorted {
                $0.shiftOrder < $1.shiftOrder
            }

            var offset: CGFloat = 0
            for view in sorted {

                let amount = scrollAmount + offset
                let shiftedAmount = view.shift(amount: amount)

                // We offset the scrollAmount so that the next view's shift call receives an amount starting at zero
                offset -= shiftedAmount
            }
        }
        
        self.isLoadingCancellable = data.$isLoading.sink(receiveValue: { [weak self] isLoading in

            guard let self = self else {
                return
            }

            let loadableShiftingSubview = self.shiftingTopViews.first { $0 is Loadable } as? Loadable

            if isLoading {
                loadableShiftingSubview?.startLoading()
            } else {
                loadableShiftingSubview?.stopLoading()
            }
        })
    }
    
    func calculateTotalHeight() {
        if self.data.totalHeight != totalHeight {
            self.data.totalHeight = totalHeight
        }
    }
    
    func addShiftingTopViews(_ views: [ShiftingTopView]) {
        shiftingTopViews.append(contentsOf: views)
        views.forEach { addArrangedSubview($0) }
        
        for view in views {
            view.stackView = self
        }

        setNeedsLayout()
        layoutIfNeeded()
    }
    
    private var totalHeight: CGFloat {
        var totalHeight: CGFloat = 0
        for view in arrangedSubviews {
            if let shiftingView = view as? ShiftingTopView {
                totalHeight += shiftingView.contentHeight
            }
        }

        return totalHeight
    }

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        arrangedSubviews.forEach({ ($0 as? Themeable)?.apply(theme: theme) })
    }
}
