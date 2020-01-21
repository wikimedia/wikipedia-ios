class ArticleTableOfContentsDisplayController {
    
    let viewController: TableOfContentsViewController
    
    weak var delegate: UIViewController?
    
    init (view: UIView, viewController: TableOfContentsViewController, delegate: ViewController?) {
        self.viewController = viewController
        self.delegate = delegate
        stackView.addArrangedSubview(view)
        stackView.addArrangedSubview(separatorView)
        stackView.addArrangedSubview(inlineContainerView)
        NSLayoutConstraint.activate([separatorWidthConstraint])
    }

    lazy var stackView: UIStackView = {
        let stackView = UIStackView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()

    lazy var separatorView: UIView = {
        let sv = UIView(frame: .zero)
        sv.isHidden = true
        return sv
    }()
    
    lazy var inlineContainerView: UIView = {
        let cv = UIView(frame: .zero)
        cv.isHidden = true
        return cv
    }()
    
    lazy var separatorWidthConstraint: NSLayoutConstraint = {
        return separatorView.widthAnchor.constraint(equalToConstant: 1)
    }()

    func show(animated: Bool) {
        viewController.isVisible = true
        switch viewController.displayMode {
        case .inline:
            UserDefaults.wmf.wmf_setTableOfContentsIsVisibleInline(true)
            inlineContainerView.isHidden = false
            separatorView.isHidden = false
        case .modal:
            guard delegate?.presentedViewController == nil else {
                break
            }
            delegate?.present(viewController, animated: animated)
        }
    }
    
    func hide(animated: Bool) {
       viewController.isVisible = false
       switch viewController.displayMode {
       case .inline:
           UserDefaults.wmf.wmf_setTableOfContentsIsVisibleInline(false)
           inlineContainerView.isHidden = true
           separatorView.isHidden = true
       case .modal:
            delegate?.dismiss(animated: true)
       }
    }
    
    func update(with traitCollection: UITraitCollection) {
        let isCompact = traitCollection.horizontalSizeClass == .compact
        viewController.displaySide = traitCollection.layoutDirection == .rightToLeft ? .right : .left
        viewController.displayMode = isCompact ? .modal : .inline
        setupTableOfContentsViewController()
    }
    
    func setupTableOfContentsViewController() {
        switch viewController.displayMode {
        case .inline:
            guard viewController.parent != delegate else {
                return
            }
            if delegate?.presentedViewController == viewController {
                delegate?.dismiss(animated: false)
            }
            delegate?.addChild(viewController)
            inlineContainerView.wmf_addSubviewWithConstraintsToEdges(viewController.view)
            viewController.didMove(toParent: delegate)
        case .modal:
            guard viewController.parent == delegate else {
                return
            }
            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
        }
    }

}
