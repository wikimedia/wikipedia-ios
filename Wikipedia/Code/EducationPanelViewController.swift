import UIKit

typealias EducationPanelButtonTapHandler = ((_ sender: EducationPanelViewController) -> ())

/*
 Education panels typically have the following items, from top to bottom:
    == Close button ==
    == Image ==
    == Title text ==
    == Subtitle text ==
    == Primary button ==
    == Secondary button ==
    == Description text ==
 
 This class pairs with a xib with roughly the following structure:
    view
        scroll view
            close button
            stack view
                image view
                title label
                subtitle label
                primary button
                secondary button
                description label
 
 - Stackview management of its subviews makes it easy to collapse space for unneeded items.
 - Scrollview containment makes long translations or landscape on small phones scrollable when needed.
*/
class EducationPanelViewController: UIViewController, Themeable {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var primaryButton: UIButton!
    @IBOutlet weak var secondaryButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var scrollViewContainer: UIView!
    
    var primaryButtonTapHandler: EducationPanelButtonTapHandler?
    var secondaryButtonTapHandler: EducationPanelButtonTapHandler?
    var dismissHandler: EducationPanelButtonTapHandler?
    var showCloseButton = true
    
    init(sourceView: UIView, showCloseButton: Bool, primaryButtonTapHandler: EducationPanelButtonTapHandler?, secondaryButtonTapHandler: EducationPanelButtonTapHandler?, dismissHandler: EducationPanelButtonTapHandler?) {
        super.init(nibName: "EducationPanelView", bundle: nil)
        self.showCloseButton = showCloseButton
        self.primaryButtonTapHandler = primaryButtonTapHandler
        self.secondaryButtonTapHandler = secondaryButtonTapHandler
        self.dismissHandler = dismissHandler
    }
    required public init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Keep preferredContentSize in sync so if we present this via UIPopoverPresentationController the
        // popover sizes itself correctly for this VC's stack view nested in a scroll view. Handles content
        // of any height correctly - is scrollable if content is really tall or device is in landscape and
        // properly hugs content if it's not very tall. https://stackoverflow.com/a/38444512/135557
        self.preferredContentSize = scrollViewContainer.bounds.size
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reset()
        configureButtonToAutoAdjustFontSize(button: primaryButton)
        configureButtonToAutoAdjustFontSize(button: secondaryButton)
        closeButton.isHidden = !showCloseButton
    }
    
    // Configure button so its text will shrink if the translation is crazy long.
    func configureButtonToAutoAdjustFontSize(button: UIButton) {
        guard let label = primaryButton.titleLabel else {
            return
        }
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = .byClipping
    }
    
    // Clear out xib defaults. Needed because we check these for nil to conditionally collapse stackview subviews.
    fileprivate func reset() {
        imageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        primaryButton.setTitle(nil, for: .normal)
        secondaryButton.setTitle(nil, for: .normal)
        descriptionLabel.text = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        adjustStackViewSubviewsVisibility()
        super.viewWillAppear(animated)
    }
    
    fileprivate func adjustStackViewSubviewsVisibility() {
        // Collapse stack view cell for image if no image.
        imageView.isHidden = (imageView.image == nil)
        // Collapse stack view cells for labels/buttons if no text.
        titleLabel.isHidden = !titleLabel.wmf_hasAnyNonWhitespaceText
        subtitleLabel.isHidden = !subtitleLabel.wmf_hasAnyNonWhitespaceText
        descriptionLabel.isHidden = !descriptionLabel.wmf_hasAnyNonWhitespaceText
        primaryButton.isHidden = !primaryButton.wmf_hasAnyNonWhitespaceText
        secondaryButton.isHidden = !secondaryButton.wmf_hasAnyNonWhitespaceText
    }
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func primaryButtonTapped(_ sender: Any) {
        guard let primaryButtonTapHandler = primaryButtonTapHandler else {
            return
        }
        primaryButtonTapHandler(self)

    }

    @IBAction func secondaryButtonTapped(_ sender: Any) {
        guard let secondaryButtonTapHandler = secondaryButtonTapHandler else {
            return
        }
        secondaryButtonTapHandler(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let dismissHandler = dismissHandler else {
            return
        }
        dismissHandler(self)
    }
    
    func apply(theme: Theme) {
        view.tintColor = theme.colors.link
    }
}

// Convenience class containerizing EducationPanelViewController for easy popover presentation.
class EducationPopoverPanelViewController: EducationPanelViewController, UIPopoverPresentationControllerDelegate {
    var dismissOnTapOutside = false
    // Note: 'sourceView' is simply used to set 'popoverPresentationController.sourceView'.
    init(sourceView: UIView, showCloseButton: Bool, dismissOnTapOutside: Bool, primaryButtonTapHandler: EducationPanelButtonTapHandler?, secondaryButtonTapHandler: EducationPanelButtonTapHandler?, dismissHandler: EducationPanelButtonTapHandler?) {
        super.init(sourceView: sourceView, showCloseButton: showCloseButton, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, dismissHandler: dismissHandler)

        self.dismissOnTapOutside = dismissOnTapOutside
        self.modalPresentationStyle = .popover
        self.popoverPresentationController?.delegate = self
        self.popoverPresentationController?.sourceView = sourceView
        self.popoverPresentationController?.canOverlapSourceViewRect = true
        self.popoverPresentationController?.sourceRect = sourceView.bounds
        self.popoverPresentationController?.permittedArrowDirections = []
    }
    
    required public init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    // Correctly re-position panel after rotation. https://stackoverflow.com/a/45301726/135557
    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>){
        guard let newRect = popoverPresentationController.sourceView?.bounds else {
            return
        }
        rect.pointee = newRect
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return dismissOnTapOutside
    }
}
