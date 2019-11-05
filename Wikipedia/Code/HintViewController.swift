import UIKit

protocol HintViewControllerDelegate: AnyObject {
    func hintViewControllerWillDisappear(_ hintViewController: HintViewController)
    func hintViewControllerHeightDidChange(_ hintViewController: HintViewController)
    func hintViewControllerViewTypeDidChange(_ hintViewController: HintViewController, newViewType: HintViewController.ViewType)
    func hintViewControllerDidPeformConfirmationAction(_ hintViewController: HintViewController)
    func hintViewControllerDidFailToCompleteDefaultAction(_ hintViewController: HintViewController)
}

class HintViewController: UIViewController {
    @IBOutlet weak var defaultView: UIView!
    @IBOutlet weak var defaultLabel: UILabel!
    @IBOutlet weak var defaultImageView: UIImageView!

    @IBOutlet weak var confirmationView: UIView!
    @IBOutlet weak var confirmationLabel: UILabel!
    @IBOutlet weak var confirmationImageView: UIImageView!
    @IBOutlet weak var confirmationAccessoryButton: UIButton!

    @IBOutlet weak var warningView: UIView!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var warningSubtitleLabel: UILabel!
    
    @IBOutlet var safeAreaBottomConstraint: NSLayoutConstraint!
    @IBOutlet var viewBottomConstraint: NSLayoutConstraint!

    var backgroundColor: UIColor?
    var primaryColor: UIColor?
    
    //if true, hint will extend below safe area to the bottom of the view, and hint content within will align to safe area
    //must also override extendsUnderSafeArea to true in HintController
    var extendsUnderSafeArea: Bool {
        return false
    }
    
    weak var delegate: HintViewControllerDelegate?

    var theme = Theme.standard
    
    enum ViewType {
        case `default`
        case confirmation
        case warning
    }

    var viewType: ViewType = .default {
        didSet {
            switch viewType {
            case .default:
                warningView.isHidden = true
                confirmationView.isHidden = true
                defaultView.isHidden = false
            case .confirmation:
                warningView.isHidden = true
                confirmationView.isHidden = false
                defaultView.isHidden = true
            case .warning:
                warningView.isHidden = false
                confirmationView.isHidden = true
                defaultView.isHidden = true
            }
            delegate?.hintViewControllerViewTypeDidChange(self, newViewType: viewType)
        }
    }

    override var nibName: String? {
        return "HintViewController"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        apply(theme: theme)
        let isRTL = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
        confirmationAccessoryButton.imageView?.transform = isRTL ? CGAffineTransform(scaleX: -1, y: 1) : CGAffineTransform.identity
        
        safeAreaBottomConstraint.isActive = extendsUnderSafeArea
        viewBottomConstraint.isActive = !extendsUnderSafeArea

        updateFonts()
        
        view.setNeedsLayout()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.hintViewControllerWillDisappear(self)
    }

    private var previousHeight: CGFloat = 0.0
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if previousHeight != view.frame.size.height {
            delegate?.hintViewControllerHeightDidChange(self)
        }
        previousHeight = view.frame.size.height
    }

    open func configureSubviews() {

    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        defaultLabel.font = UIFont.wmf_font(.mediumSubheadline, compatibleWithTraitCollection: traitCollection)
        confirmationLabel.font = UIFont.wmf_font(.mediumSubheadline, compatibleWithTraitCollection: traitCollection)
        warningLabel.font = UIFont.wmf_font(.mediumSubheadline, compatibleWithTraitCollection: traitCollection)
        warningSubtitleLabel.font = UIFont.wmf_font(.caption1, compatibleWithTraitCollection: traitCollection)
    }
}

extension HintViewController {
    @IBAction open func performDefaultAction(sender: Any) {

    }

    @IBAction open func performConfirmationAction(sender: Any) {

    }
}

extension HintViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }

        view.backgroundColor = backgroundColor ?? (viewType == .warning ? theme.colors.hintWarningBackground : theme.colors.hintBackground)
        defaultLabel?.textColor = primaryColor ?? theme.colors.link
        confirmationLabel?.textColor = primaryColor ?? theme.colors.link
        confirmationAccessoryButton.tintColor = primaryColor ?? theme.colors.link
        defaultImageView.tintColor = primaryColor ?? theme.colors.link
        warningLabel?.textColor = primaryColor ?? theme.colors.warning
        warningSubtitleLabel?.textColor = primaryColor ?? theme.colors.primaryText
    }
}
