import Foundation
import UIKit

protocol WMFEditorHeaderSelectScrollViewDelegate: AnyObject {
    func didSelectIndex(_ index: Int, headerSelectScrollView: WMFEditorHeaderSelectScrollView)
}

final class WMFEditorHeaderSelectScrollView: WMFComponentView {
    
    // MARK: - Properties
    
    private weak var delegate: WMFEditorHeaderSelectScrollViewDelegate?
    private var buttons: [WMFEditorHeaderSelectButton] = []
    private let viewModels: [WMFEditorHeaderSelectButton.ViewModel]
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()
    
    // MARK: - Lifecycle
    
    init(viewModels: [WMFEditorHeaderSelectButton.ViewModel], delegate: WMFEditorHeaderSelectScrollViewDelegate?) {
        self.viewModels = viewModels
        self.delegate = delegate
        super.init(frame: .zero)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {

        addButtonsToStackView(stackView)
        setupButtonTapActions()
        
        scrollView.addSubview(stackView)
        
        // pin stack view to scroll view content guide
        // ensure it only scrolls horizontally
        // set scroll view height to largest button height
        NSLayoutConstraint.activate([
            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: stackView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 16),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            scrollView.contentLayoutGuide.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: largestButtonHeight)
        ])
        
        // Add scroll view to self, pin to edges
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: topAnchor),
            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Internal
    
    func selectIndex(_ index: Int) {
        guard buttons.count > index else {
            return
        }
        
        buttons.forEach { $0.isSelected = false }
        
        buttons[index].isSelected = true
    }
    
    // MARK: - Private
    
    private func addButtonsToStackView(_ stackView: UIStackView) {
        
        var buttons: [WMFEditorHeaderSelectButton] = []
        
        for viewModel in viewModels {
            let button = WMFEditorHeaderSelectButton(viewModel: viewModel)
            button.translatesAutoresizingMaskIntoConstraints = false
            buttons.append(button)
            
            stackView.addArrangedSubview(button)
        }
        
        self.buttons = buttons
    }
    
    private func setupButtonTapActions() {
        for (index, button) in buttons.enumerated() {
            button.tapAction = { [weak self] in
                
                guard let self else {
                    return
                }

                for innerButton in self.buttons {
                    if button != innerButton {
                        innerButton.isSelected = false
                    } else {
                        innerButton.isSelected = true
                        self.delegate?.didSelectIndex(index, headerSelectScrollView: self)
                    }
                }
            }
        }
    }
    
    private var largestButtonHeight: CGFloat {
        var largestButtonHeight: CGFloat = 0
        for button in buttons {
            let buttonHeight = button.sizeThatFits(CGSize(width: .max, height: .max)).height
            if buttonHeight > largestButtonHeight {
                largestButtonHeight = buttonHeight
            }
        }
        
        return largestButtonHeight
    }
}
