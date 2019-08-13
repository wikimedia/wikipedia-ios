import UIKit

class PageHistoryStatsViewController: UIViewController {
    private let pageTitle: String
    private let locale: Locale
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var pageTitleLabel: UILabel!
    @IBOutlet private weak var statsLabel: UILabel!

    @IBOutlet private weak var separator: UIView!

    @IBOutlet private weak var detailedStatsContainerView: UIView!
    private lazy var detailedStatsViewController = PageHistoryDetailedStatsViewController()

    var pageStats: PageStats? {
        didSet {
            guard
                let edits = pageStats?.edits,
                let editors = pageStats?.editors
            else {
                statsLabel.isHidden = true
                return
            }
            // TODO: When localization script supports multiple plurals per string, update to use plurals.
            statsLabel.text = String.localizedStringWithFormat(WMFLocalizedString("page-history-stats-text", value: "%1$d edits by %2$d editors", comment: "Text for representing the number of edits that were made to an article and the number of editors who contributed to the creation of an article. %1$d is replaced with the number of edits, %2$d is replaced with the number of editors."), edits, editors)
            statsLabel.isHidden = false

            detailedStatsViewController.pageStats = pageStats
        }
    }

    var theme = Theme.standard

    private var isFirstLayoutPass = true

    required init(pageTitle: String, locale: Locale = Locale.current) {
        self.pageTitle = pageTitle
        self.locale = locale
        super.init(nibName: "PageHistoryStatsViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        statsLabel.isHidden = true

        titleLabel.text = WMFLocalizedString("page-history-revision-history-title", value: "Revision history", comment: "Title for revision history view").uppercased(with: locale)
        pageTitleLabel.text = pageTitle

        wmf_add(childController: detailedStatsViewController, andConstrainToEdgesOfContainerView: detailedStatsContainerView)
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
        separator.backgroundColor = theme.colors.border
        detailedStatsViewController.apply(theme: theme)
    }
}
