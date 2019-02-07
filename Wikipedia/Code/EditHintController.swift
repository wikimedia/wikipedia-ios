@objc(WMFEditHintController)
class EditHintController: HintController {
    @objc init() {
        let editHintViewController = EditHintViewController()
        super.init(hintViewController: editHintViewController)
    }

    @objc func toggle() {
        setHintHidden(false)
    }
}
