import UIKit

protocol NotificationsViewDelegate: AnyObject {
	func userDidTapNotification(type: NotificationType)
}

@objc public protocol NotificationDrawerDelegate: AnyObject {
	func userDidTapDrawerButton()
	func userDidTapInPlaceButton()
	func userDidTapNotificationsInDrawer()
}

enum NotificationType: Int {
	case article
	case history
	case diff
	case articleTalkPage
	case userTalkPage
}

final class NotificationsViewController: ViewController, NotificationsViewDelegate {

	override func loadView() {
		super.loadView()
		self.view = NotificationsView(frame: UIScreen.main.bounds)
		self.scrollView = (view as! NotificationsView).scrollView
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Notifications"

		navigationBar.isBarHidingEnabled = true
		navigationBar.displayType = .backVisible

		(view as! NotificationsView).delegate = self
	}

	override func apply(theme: Theme) {
		super.apply(theme: theme)

		(view as! NotificationsView).backgroundColor = theme.colors.paperBackground
        (view as! NotificationsView).toolbarLabel.textColor = theme.colors.primaryText
		NotificationsDrawerHandler.shared.drawerView.backgroundColor = theme.colors.paperBackground
        NotificationsDrawerHandler.shared.drawerView.notificationsButton.backgroundColor = theme.colors.cardButtonBackground
        NotificationsDrawerHandler.shared.drawerView.notificationsButton.setTitleColor(theme.colors.primaryText, for: .normal)
	}

	// MARK: - Notifications View Delegate

	func userDidTapNotification(type: NotificationType) {
		switch type {
		case .article:
			let articleViewController = ArticleViewController(articleURL: URL(string: "https://en.wikipedia.org/wiki/English_Wikipedia")!, dataStore: MWKDataStore.shared(), theme: self.theme)
			self.navigationController?.push(articleViewController!)
		case .history:
			let pageHistoryViewController = PageHistoryViewController(pageTitle: "English Wikipedia", pageURL: URL(string: "https://en.wikipedia.org/wiki/English_Wikipedia")!)
			self.navigationController?.push(pageHistoryViewController)
		case .diff:
			let diffContainerViewController = DiffContainerViewController(siteURL: URL(string: "https://en.wikipedia.org")!, theme: theme, fromRevisionID: 1027571449, toRevisionID: 1027571191, type: .single, articleTitle: nil)
			self.navigationController?.push(diffContainerViewController)
		case .articleTalkPage:
			let url = URL(string: "https://en.wikipedia.org/wiki/Talk:English_Wikipedia")!
			let singleWebPageViewController = SinglePageWebViewController(url: url, theme: theme)
			navigationController?.push(singleWebPageViewController)
			return
		case .userTalkPage:
			let userTalkPageController = TalkPageContainerViewController(title: "User_talk:Jimbo_Wales", siteURL: URL(string: "https://en.wikipedia.org/wiki/User_talk:Jimbo_Wales")!, type: .user, dataStore: MWKDataStore.shared(), theme: theme)
			navigationController?.push(userTalkPageController)
		}
	}

}

final class NotificationsView: SetupView {

	weak var delegate: NotificationsViewDelegate?

	lazy var scrollView: UIScrollView = {
		let scrollView = UIScrollView()
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		scrollView.alwaysBounceVertical = true
		return scrollView
	}()

	lazy var buttonStack: UIStackView = {
		let stackView = UIStackView()
		stackView.axis = .vertical
		stackView.spacing = 20
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.alignment = .leading
		return stackView
	}()
    
    let toolbar: UIView = {
        let view = UIView()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .secondarySystemFill
        }
                
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let toolbarLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "Toolbar"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        return label
    }()

	override func setup() {
        addSubview(toolbar)
		addSubview(scrollView)
		NSLayoutConstraint.activate([
			scrollView.topAnchor.constraint(equalTo: self.topAnchor),
			scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
			scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.toolbar.topAnchor)
		])
        
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            toolbar.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 60)
        ])

		scrollView.addSubview(buttonStack)
		NSLayoutConstraint.activate([
			buttonStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
			buttonStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
			buttonStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
			buttonStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
			buttonStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
		])

		let articleButton = UIButton()
		articleButton.tag = NotificationType.article.rawValue
		articleButton.setTitle("  Article  ", for: .normal)

		let historyButton = UIButton()
		historyButton.tag = NotificationType.history.rawValue
		historyButton.setTitle("  Article History  ", for: .normal)

		let diffButton = UIButton()
		diffButton.tag = NotificationType.diff.rawValue
		diffButton.setTitle("  Specific Diff  ", for: .normal)

		let articleTalkButton = UIButton()
		articleTalkButton.tag = NotificationType.articleTalkPage.rawValue
		articleTalkButton.setTitle("  Article Talk Page  ", for: .normal)

		let userTalkPage = UIButton()
		userTalkPage.tag = NotificationType.userTalkPage.rawValue
		userTalkPage.setTitle("  User Talk Page  ", for: .normal)


		buttonStack.addArrangedSubview(articleButton)
		buttonStack.addArrangedSubview(historyButton)
		buttonStack.addArrangedSubview(diffButton)
		buttonStack.addArrangedSubview(articleTalkButton)
		buttonStack.addArrangedSubview(userTalkPage)

		for button in buttonStack.arrangedSubviews {
			(button as? UIButton)?.addTarget(self, action: #selector(userDidTapButton(_:)), for: .primaryActionTriggered)
			(button as? UIButton)?.backgroundColor = .blue50
			(button as? UIButton)?.layer.cornerRadius = 5
		}
        
        toolbar.wmf_addSubviewWithConstraintsToEdges(toolbarLabel)
	}

	@objc func userDidTapButton(_ button: UIButton) {
		guard let notification = NotificationType(rawValue: button.tag) else {
			fatalError()
		}

		delegate?.userDidTapNotification(type: notification)
	}

}

@objc public protocol NotificationsButtonTapDelegate: AnyObject {
	func userDidTapDrawerButton()
}

@objc public final class NotificationsDrawerHandler: NSObject {

	@objc public static let shared = NotificationsDrawerHandler()

	weak var delegate: NotificationsButtonTapDelegate?

	var drawerView = NotificationDrawerView(frame: UIScreen.main.bounds)
	var isDrawerVisible = false
	var containerView: UIView?

	@objc public func userDidTapDrawer(containerView: UIView, completion: @escaping (Bool) -> Void) {
		if !(containerView.window?.subviews.contains(drawerView) ?? true) {
			containerView.superview?.insertSubview(drawerView, belowSubview: containerView)

			containerView.layer.shadowColor = UIColor.black.cgColor
			containerView.layer.shadowOpacity = 0.30
			containerView.layer.shadowOffset = .zero
			containerView.layer.shadowRadius = 20

			self.containerView = containerView
		}

		UIView.animate(withDuration: 0.25, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseInOut], animations: {
			containerView.frame.origin.x = containerView.frame.origin.x + (self.isDrawerVisible ? -280 : 280)
		}, completion: { success in
			self.isDrawerVisible = !self.isDrawerVisible
			completion(success)
		})
	}

	@objc public func userDidTapInDrawerNotificationButton() {
		delegate?.userDidTapDrawerButton()
	}

}

public final class NotificationDrawerView: SetupView {
    
    let notificationsButton: UIButton = {
        let button = UIButton()
        button.setTitle("    Notifications", for: .normal)
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(systemName: "bell"), for: .normal)
        }
        return button
    }()

	public override func setup() {
        addSubview(notificationsButton)
        notificationsButton.frame = CGRect(x: 0, y: 100, width: 250, height: 60)

		notificationsButton.addTarget(self, action: #selector(userDidTapButton), for: .primaryActionTriggered)

		let tapDismissGesture = UITapGestureRecognizer(target: self, action: #selector(userDidTapDismiss))
		addGestureRecognizer(tapDismissGesture)
	}

	@objc func userDidTapDismiss() {
		NotificationsDrawerHandler.shared.userDidTapDrawer(containerView: NotificationsDrawerHandler.shared.containerView!, completion: { _ in
		})
	}

	@objc func userDidTapButton() {
		NotificationsDrawerHandler.shared.userDidTapInDrawerNotificationButton()
	}

}
