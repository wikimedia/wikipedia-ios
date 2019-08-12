import UIKit

class PageHistoryStatsViewController: UIViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var articleTitleLabel: UILabel!
    @IBOutlet private weak var statsLabel: UILabel!

    var theme = Theme.standard

    private var isFirstLayoutPass = true

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard isFirstLayoutPass else {
            return
        }
        titleLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        isFirstLayoutPass = false
    }
}

extension PageHistoryStatsViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        view.backgroundColor = theme.colors.baseBackground
    }
}
