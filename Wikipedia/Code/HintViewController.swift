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

    @IBOutlet var safeAreaBottomConstraint: NSLayoutConstraint!
    @IBOutlet var viewBottomConstraint: NSLayoutConstraint!
    
    //if true, hint will extend below safe area to the bottom of the view, and hint content within will align to safe area
    //must also override extendsUnderSafeArea to true in HintController
    var extendsUnderSafeArea: Bool {
        return false
    }
    
    weak var delegate: HintViewControllerDelegate?

    var theme = Theme.standard

    private var isFirstLayout = true

    enum ViewType {
        case `default`
        case confirmation
    }

    var viewType: ViewType = .default {
        didSet {
            switch viewType {
            case .default:
                confirmationView.isHidden = true
                defaultView.isHidden = false
            case .confirmation:
                confirmationView.isHidden = false
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
        view.setNeedsLayout()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.hintViewControllerWillDisappear(self)
    }

    private var previousHeight: CGFloat = 0.0
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirstLayout {
            updateFonts()
            isFirstLayout = false
        }
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
        view.backgroundColor = theme.colors.hintBackground
        defaultLabel?.textColor = theme.colors.link
        confirmationLabel?.textColor = theme.colors.link
        confirmationAccessoryButton.tintColor = theme.colors.link
    }
}
