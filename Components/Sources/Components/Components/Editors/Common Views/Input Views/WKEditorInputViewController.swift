import Foundation
import UIKit

protocol WKEditorInputViewDelegate: AnyObject {
    func didTapClose()
}

class WKEditorInputViewController: WKComponentViewController {
    
    // MARK: - Nested Types
    
    enum Configuration {
        case rootMain
        case rootHeaderSelect
    }
    
    // MARK: - Properties
    
    private lazy var containerView: UIView = {
       let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var embeddedNavigationController: UINavigationController = {
        let viewController = rootViewController(for: configuration)
        let navigationController = UINavigationController(rootViewController: viewController)
        return navigationController
    }()
    
    private lazy var headerSelectViewController: WKEditorInputHeaderSelectViewController = {
        let vc = WKEditorInputHeaderSelectViewController(configuration: .leftTitleNav, delegate: delegate)
        return vc
    }()
    
    private lazy var mainViewController: WKEditorInputMainViewController = {
        let vc = WKEditorInputMainViewController()
        vc.delegate = delegate
        return vc
    }()
    
    private let configuration: Configuration
    private weak var delegate: WKEditorInputViewDelegate?
    
    // MARK: - Lifecycle
    
    init(configuration: Configuration, delegate: WKEditorInputViewDelegate) {
        self.configuration = configuration
        self.delegate = delegate
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        view.addSubview(containerView)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            view.topAnchor.constraint(equalTo: containerView.topAnchor),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        embedNavigationController()
        
        updateColors()
    }
    
    // MARK: - Overrides
    
    override func appEnvironmentDidChange() {
        updateColors()
    }
    
    // MARK: - Private Helpers
    
    private func embedNavigationController() {
        addChild(embeddedNavigationController)
        embeddedNavigationController.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(embeddedNavigationController.view)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: embeddedNavigationController.view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: embeddedNavigationController.view.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: embeddedNavigationController.view.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: embeddedNavigationController.view.bottomAnchor)
        ])
        
        embeddedNavigationController.didMove(toParent: self)
    }
    
    private func rootViewController(for configuration: Configuration) -> UIViewController {
        var viewController: UIViewController

        switch configuration {
        case .rootMain:
            viewController = mainViewController
        case .rootHeaderSelect:
            viewController = headerSelectViewController
        }
        return viewController
    }
    
    private func updateColors() {
        view.backgroundColor = WKAppEnvironment.current.theme.accessoryBackground
        embeddedNavigationController.navigationBar.isTranslucent = false
        embeddedNavigationController.navigationBar.tintColor = WKAppEnvironment.current.theme.inputAccessoryButtonTint
        embeddedNavigationController.navigationBar.backgroundColor = WKAppEnvironment.current.theme.accessoryBackground
    }
}
