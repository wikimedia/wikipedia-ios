import UIKit

class PageHistoryCountsViewController: UIViewController {
    private let pageTitle: String
    private let locale: Locale
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var pageTitleLabel: UILabel!
    @IBOutlet private weak var countsLabel: UILabel!

    @IBOutlet private weak var sparklineView: WMFSparklineView!
    private lazy var visibleSparklineViewWidthConstraint = sparklineView.widthAnchor.constraint(greaterThanOrEqualTo: view.widthAnchor, multiplier: 0.35)
    private lazy var hiddenSparklineViewWidthConstraint = sparklineView.widthAnchor.constraint(equalToConstant: 0)

    @IBOutlet private weak var separator: UIView!

    @IBOutlet private weak var filterCountsContainerView: UIView!
    private lazy var filterCountsViewController = PageHistoryFilterCountsViewController()

    var editCountsGroupedByType: EditCountsGroupedByType? {
        didSet {
            filterCountsViewController.editCountsGroupedByType = editCountsGroupedByType
        }
    }

    func set(totalEditCount: Int, firstEditDate: Date) {
        let firstEditYear = String(Calendar.current.component(.year, from: firstEditDate))
        countsLabel.text = String.localizedStringWithFormat(WMFLocalizedString("page-history-stats-text", value: "%1$d edits since %2$@", comment: "Text for representing the number of edits that were made to an article and the number of editors who contributed to the creation of an article. %1$d is replaced with the number of edits, %2$d is replaced with the number of editors."), totalEditCount, firstEditYear)
        setViewHidden(countsLabel, hidden: false)
    }

    var timeseriesOfEditsCounts: [NSNumber] = [] {
        didSet {
            if timeseriesOfEditsCounts.isEmpty != sparklineView.isHidden {
                setSparklineViewHidden(timeseriesOfEditsCounts.isEmpty)
            }
            setViewHidden(sparklineView, hidden: timeseriesOfEditsCounts.isEmpty)
            sparklineView.dataValues = timeseriesOfEditsCounts
            sparklineView.updateMinAndMaxFromDataValues()
        }
    }

    var theme = Theme.standard

    private var isFirstLayoutPass = true

    required init(pageTitle: String, locale: Locale = Locale.current) {
        self.pageTitle = pageTitle
        self.locale = locale
        super.init(nibName: "PageHistoryCountsViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setViewHidden(_ element: UIView, hidden: Bool) {
        UIView.animate(withDuration: 0.2) {
            element.alpha = hidden ? 0 : 1
        }
    }

    private func setSparklineViewHidden(_ hidden: Bool) {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.2) {
            self.sparklineView.isHidden = hidden
            self.visibleSparklineViewWidthConstraint.isActive = !hidden
            self.hiddenSparklineViewWidthConstraint.isActive = hidden
            self.sparklineView.alpha = hidden ? 0 : 1
            self.view.setNeedsLayout()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setSparklineViewHidden(false)
        setViewHidden(countsLabel, hidden: true)

        titleLabel.text = WMFLocalizedString("page-history-revision-history-title", value: "Revision history", comment: "Title for revision history view").uppercased(with: locale)
        pageTitleLabel.text = pageTitle

        sparklineView.showsVerticalGridlines = true

        filterCountsViewController.delegate = self
        wmf_add(childController: filterCountsViewController, andConstrainToEdgesOfContainerView: filterCountsContainerView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard isFirstLayoutPass else {
            return
        }
        titleLabel.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        pageTitleLabel.font = UIFont.wmf_font(.boldTitle1, compatibleWithTraitCollection: traitCollection)
        countsLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)

        isFirstLayoutPass = false
    }
}

extension PageHistoryCountsViewController: PageHistoryFilterCountsViewControllerDelegate {
    func didDetermineFilterCountsAvailability(_ available: Bool, viewController: PageHistoryFilterCountsViewController) {
        if !available {
            filterCountsContainerView.isHidden = true
            UIView.animate(withDuration: 0.4) {
                self.filterCountsViewController.willMove(toParent: nil)
                self.filterCountsViewController.view.removeFromSuperview()
                self.filterCountsViewController.removeFromParent()
            }
        }
    }
}

extension PageHistoryCountsViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        titleLabel.textColor = theme.colors.secondaryText
        pageTitleLabel.textColor = theme.colors.primaryText
        countsLabel.textColor = theme.colors.accent
        separator.backgroundColor = theme.colors.border
        filterCountsViewController.apply(theme: theme)
    }
}
