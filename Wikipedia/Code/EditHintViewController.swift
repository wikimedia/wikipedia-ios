@objc(WMFEditHintViewController)
class EditHintViewController: HintViewController {
    override func configureSubviews() {
        defaultImageView.image = UIImage(named: "published-pencil")
        defaultLabel.text = "Your edit was successfully published"
    }
}
