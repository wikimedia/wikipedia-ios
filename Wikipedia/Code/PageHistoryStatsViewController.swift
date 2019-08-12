import UIKit

class PageHistoryStatsViewController: UIViewController {
    private let pageTitle: String

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var pageTitleLabel: UILabel!
    @IBOutlet private weak var statsLabel: UILabel!

    var theme = Theme.standard

    private var isFirstLayoutPass = true

    required init(pageTitle: String) {
        self.pageTitle = pageTitle
        super.init(nibName: "PageHistoryStatsViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        pageTitleLabel.text = pageTitle
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard isFirstLayoutPass else {
            return
        }
        titleLabel.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        pageTitleLabel.font = UIFont.wmf_font(.boldTitle1, compatibleWithTraitCollection: traitCollection)
        statsLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)

        isFirstLayoutPass = false
    }
}

extension PageHistoryStatsViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        titleLabel.textColor = theme.colors.secondaryText
        pageTitleLabel.textColor = theme.colors.primaryText
        statsLabel.textColor = theme.colors.accent
    }
}
