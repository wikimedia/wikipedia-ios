import UIKit

protocol HintViewControllerDataSource: AnyObject {
    var defaultViewImage: UIImage { get }
    var defaultViewTitle: String { get }
    var confirmationViewImage: UIImage { get }
    var confirmationViewTitle: String { get }
    var confirmationViewAccessoryImage: UIImage { get }
}

protocol HintViewControllerDelegate: AnyObject {
    func hintViewControllerDidTapDefaultView()
    func hintViewControllerDidTapConfirmationView()
}

class HintViewController: UIViewController {
    weak var dataSource: HintViewControllerDataSource?
    weak var delegate: HintViewControllerDelegate?

    @IBOutlet private weak var defaultView: UIView!
    @IBOutlet private weak var defaultLabel: UILabel!
    @IBOutlet private weak var defaultImageView: UIImageView!

    @IBOutlet private weak var confirmationView: UIView!
    @IBOutlet private weak var confirmationLabel: UILabel!
    @IBOutlet private weak var confirmationImageView: UIImageView!
    @IBOutlet private weak var confirmationAccessoryImageView: UIImageView!

    private var theme = Theme.standard

    private enum ViewType {
        case `default`
        case confirmation
    }

    private var viewType: ViewType = .default {
        didSet {
            switch viewType {
            case .default:
                confirmationView.isHidden = true
                defaultView.isHidden = false
            case .confirmation:
                confirmationView.isHidden = false
                defaultView.isHidden = true
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(themeChanged), name: Notification.Name(ReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        defaultLabel.font = UIFont.wmf_font(.mediumSubheadline, compatibleWithTraitCollection: traitCollection)
        confirmationLabel.font = UIFont.wmf_font(.mediumSubheadline, compatibleWithTraitCollection: traitCollection)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func themeChanged(notification: Notification) {
        guard let info = notification.userInfo else {
            assertionFailure("Expected userInfo")
            return
        }
        let key = ReadingThemesControlsViewController.WMFUserDidSelectThemeNotificationThemeKey
        guard let theme = info[key] as? Theme else {
            assertionFailure("Expected theme")
            return
        }
        apply(theme: theme)
    }
}

extension HintViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.hintBackground
        defaultLabel?.textColor = theme.colors.link
        confirmationLabel?.textColor = theme.colors.link
        confirmationAccessoryImageView.tintColor = theme.colors.link
    }
}
