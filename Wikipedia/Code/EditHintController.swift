@objc(WMFEditHintController)
class EditHintController: HintController {
    @objc init() {
        let editHintViewController = EditHintViewController()
        super.init(hintViewController: editHintViewController)
    }

    override func toggle(presenter: HintPresentingViewController, context: HintController.Context?, theme: Theme) {
        super.toggle(presenter: presenter, context: context, theme: theme)
        setHintHidden(false)
    }
}
