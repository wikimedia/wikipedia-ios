import Foundation
import SwiftUI
import UIKit

final class WMFTooltipViewController: WMFComponentViewController {
    
    let viewModel: WMFTooltipViewModel
    private let horizontalPadding = CGFloat(12)
    private let verticalPadding = CGFloat(8)
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    lazy var stackView: UIStackView = {
       let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 4
        return stackView
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.numberOfLines = 0
        label.text = viewModel.localizedStrings.title
        label.font = WMFFont.for(.callout)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.numberOfLines = 0
        label.text = viewModel.localizedStrings.body
        label.font = WMFFont.for(.callout)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    lazy var buttonContainerView: UIView = {
       let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var actionButton: UIView = {
        let trailingIcon = viewModel.buttonNeedsDisclosure ? WMFSFSymbolIcon.for(symbol: .chevronForward, font: .mediumSubheadline) : nil
        let configuration = WMFSmallButton.Configuration(style: .quiet, trailingIcon: trailingIcon)
        let button = WMFSmallButton(configuration: configuration, title: viewModel.localizedStrings.buttonTitle, action: viewModel.buttonAction)
        let buttonHostingController = UIHostingController(rootView: button)
        buttonHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        buttonHostingController.view.backgroundColor = .clear
        buttonHostingController.view.setContentCompressionResistancePriority(.required, for: .vertical)
        buttonHostingController.view.setContentHuggingPriority(.required, for: .vertical)
        return buttonHostingController.view
    }()
    
    init(viewModel: WMFTooltipViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(bodyLabel)
        buttonContainerView.addSubview(actionButton)
        stackView.addArrangedSubview(buttonContainerView)
        
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: scrollView.topAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: stackView.topAnchor, constant: -verticalPadding),
            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: -horizontalPadding),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: horizontalPadding),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: verticalPadding),
            
            buttonContainerView.topAnchor.constraint(equalTo: actionButton.topAnchor),
            buttonContainerView.leadingAnchor.constraint(lessThanOrEqualTo: actionButton.leadingAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: actionButton.trailingAnchor),
            buttonContainerView.bottomAnchor.constraint(equalTo: actionButton.bottomAnchor)
        ])
    }
    
    override var preferredContentSize: CGSize {
        get {
            let additionalVerticalSize = CGFloat(10) // Needed to prevent unnecessary scrolling
            let size = CGSize(width: 280, height: UIView.noIntrinsicMetric)
            let titleSize = titleLabel.sizeThatFits(size)
            let bodySize = bodyLabel.sizeThatFits(size)
            let buttonSize = actionButton.sizeThatFits(size)
            return CGSize(width: 280 + (horizontalPadding * 2), height: titleSize.height + bodySize.height + buttonSize.height + (verticalPadding * 2) + additionalVerticalSize)
        }

        set { super.preferredContentSize = newValue }
    }
    
    override func appEnvironmentDidChange() {
        let theme = WMFAppEnvironment.current.theme
        view.backgroundColor = theme.popoverBackground
        titleLabel.textColor = theme.text
        bodyLabel.textColor = theme.secondaryText
    }
}
