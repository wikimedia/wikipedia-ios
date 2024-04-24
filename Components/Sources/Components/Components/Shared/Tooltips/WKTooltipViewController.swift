import Foundation
import SwiftUI
import UIKit

final class WKTooltipViewController: WKComponentViewController {
    
    let viewModel: WKTooltipViewModel
    private let horizontalPadding = CGFloat(12)
    private let verticalPadding = CGFloat(8)
    
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
        label.font = WKFont.for(.body)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.numberOfLines = 0
        label.text = viewModel.localizedStrings.body
        label.font = WKFont.for(.callout)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    lazy var buttonContainerView: UIView = {
       let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var actionButton: UIView = {
        let configuration = WKSmallButton.Configuration(style: .quiet, needsDisclosure: viewModel.buttonNeedsDisclosure)
        let button = WKSmallButton(configuration: configuration, title: viewModel.localizedStrings.buttonTitle, action: viewModel.buttonAction)
        let buttonHostingController = UIHostingController(rootView: button)
        buttonHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        buttonHostingController.view.backgroundColor = .clear
        buttonHostingController.view.setContentCompressionResistancePriority(.required, for: .vertical)
        buttonHostingController.view.setContentHuggingPriority(.required, for: .vertical)
        return buttonHostingController.view
    }()
    
    init(viewModel: WKTooltipViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(bodyLabel)
        buttonContainerView.addSubview(actionButton)
        stackView.addArrangedSubview(buttonContainerView)
        
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: stackView.topAnchor, constant: -verticalPadding),
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: -horizontalPadding),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: horizontalPadding),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: verticalPadding),
            buttonContainerView.topAnchor.constraint(equalTo: actionButton.topAnchor),
            buttonContainerView.leadingAnchor.constraint(lessThanOrEqualTo: actionButton.leadingAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: actionButton.trailingAnchor),
            buttonContainerView.bottomAnchor.constraint(equalTo: actionButton.bottomAnchor)
        ])
    }
    
    override var preferredContentSize: CGSize {
        get {
            let size = CGSize(width: 280, height: UIView.noIntrinsicMetric)
            let titleSize = titleLabel.sizeThatFits(size)
            let bodySize = bodyLabel.sizeThatFits(size)
            let buttonSize = actionButton.sizeThatFits(size)
            return CGSize(width: 280 + (horizontalPadding * 2), height: titleSize.height + bodySize.height + buttonSize.height + (verticalPadding * 2))
        }

        set { super.preferredContentSize = newValue }
    }
    
    override func appEnvironmentDidChange() {
        let theme = WKAppEnvironment.current.theme
        view.backgroundColor = theme.popoverBackground
        titleLabel.textColor = theme.text
        bodyLabel.textColor = theme.secondaryText
    }
}
