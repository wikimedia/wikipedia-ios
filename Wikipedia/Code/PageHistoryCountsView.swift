import UIKit
import WMFComponents

class PageHistoryCountsView: UICollectionReusableView {
    fileprivate var pageTitle: String = ""
    fileprivate var locale: Locale = Locale.current
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var pageTitleLabel: UILabel!
    @IBOutlet private weak var countsLabel: UILabel!

    @IBOutlet private weak var sparklineView: WMFSparklineView!
    private lazy var visibleSparklineViewWidthConstraint = sparklineView.widthAnchor.constraint(greaterThanOrEqualTo: widthAnchor, multiplier: 0.35)
    private lazy var hiddenSparklineViewWidthConstraint = sparklineView.widthAnchor.constraint(equalToConstant: 0)

    @IBOutlet private weak var separator: UIView!
    @IBOutlet weak var bottomSeparator: UIView!
    
    @IBOutlet private weak var filterCountsContainerView: UIView!
    private lazy var filterCountsView = PageHistoryFilterCountsView()

    var editCountsGroupedByType: EditCountsGroupedByType? {
        didSet {
            filterCountsView.editCountsGroupedByType = editCountsGroupedByType
        }
    }

    func set(totalEditCount: Int?, firstEditDate: Date) {
        guard let totalEditCount = totalEditCount else {
            return
        }
        let firstEditYear = String(Calendar.current.component(.year, from: firstEditDate))
        countsLabel.text = String.localizedStringWithFormat(WMFLocalizedString("page-history-stats-text", value: "{{PLURAL:%1$d|%1$d edit|%1$d edits}} since %2$@", comment: "Text for representing the number of edits that were made to an article and the year when the first edit was made. %1$d is replaced with the number of edits, %2$d is replaced with they year when the first edit was made."), totalEditCount, firstEditYear)
        countsLabel.setTransparent(false)
    }

    var timeseriesOfEditsCounts: [NSNumber] = [] {
        didSet {
            if timeseriesOfEditsCounts.isEmpty != sparklineView.isHidden {
                setSparklineViewHidden(timeseriesOfEditsCounts.isEmpty)
            }
            sparklineView.setTransparent(timeseriesOfEditsCounts.isEmpty)
            sparklineView.dataValues = timeseriesOfEditsCounts
        }
    }

    private var theme = Theme.standard

    private var isFirstLayoutPass = true

    private func setSparklineViewHidden(_ hidden: Bool) {
        layoutIfNeeded()
        UIView.animate(withDuration: 0.2) {
            self.sparklineView.isHidden = hidden
            self.visibleSparklineViewWidthConstraint.isActive = !hidden
            self.hiddenSparklineViewWidthConstraint.isActive = hidden
            self.sparklineView.alpha = hidden ? 0 : 1
            self.setNeedsLayout()
        }
    }
    
    func configure(pageTitle: String, locale: Locale, totalEditCount: Int?, firstEditDate: Date?, editCountsGroupedByType: EditCountsGroupedByType?, timeseriesOfEditsCounts: [NSNumber]?, theme: Theme) {
        self.pageTitle = pageTitle
        self.locale = locale
        
        setSparklineViewHidden(false)
        countsLabel.setTransparent(true)

        titleLabel.text = WMFLocalizedString("page-history-revision-history-title", value: "Revision history", comment: "Title for revision history view. Please prioritize for de, ar and zh wikis.").uppercased(with: locale)
        pageTitleLabel.text = pageTitle

        sparklineView.showsVerticalGridlines = true

        filterCountsView.delegate = self
        filterCountsContainerView.wmf_addSubviewWithConstraintsToEdges(filterCountsView)

        sparklineView.isAccessibilityElement = true
        sparklineView.accessibilityLabel = WMFLocalizedString("page-history-graph-accessibility-label", value: "Graph of edits over time", comment: "Accessibility label text used for edits graph")

        accessibilityElements = [titleLabel, pageTitleLabel, countsLabel, sparklineView, filterCountsView].compactMap { $0 as Any }
        
        setNeedsLayout()
        layoutIfNeeded()
        
        if let totalEditCount, let firstEditDate {
            self.set(totalEditCount: totalEditCount, firstEditDate: firstEditDate)
        }
        
        if let editCountsGroupedByType {
            self.editCountsGroupedByType = editCountsGroupedByType
        }
        
        if let timeseriesOfEditsCounts {
            self.timeseriesOfEditsCounts = timeseriesOfEditsCounts
        }
       
        apply(theme: theme)
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        
        guard isFirstLayoutPass else {
            return
        }
        updateFonts()
        isFirstLayoutPass = false
    }

    private func updateFonts() {
        titleLabel.font = WMFFont.for(.mediumFootnote)
        pageTitleLabel.font = WMFFont.for(.boldTitle1)
        countsLabel.font = WMFFont.for(.boldSubheadline)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }
}

extension PageHistoryCountsView: PageHistoryFilterCountsViewDelegate {
    func didDetermineFilterCountsAvailability(_ available: Bool, view: PageHistoryFilterCountsView) {
        if !available {
            filterCountsContainerView.isHidden = true
            UIView.animate(withDuration: 0.4) {
                self.filterCountsView.removeFromSuperview()
            }
        }
    }
}

extension PageHistoryCountsView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        titleLabel.textColor = theme.colors.secondaryText
        pageTitleLabel.textColor = theme.colors.primaryText
        countsLabel.textColor = theme.colors.accent
        separator.backgroundColor = theme.colors.border
        bottomSeparator.backgroundColor = theme.colors.border
        filterCountsView.apply(theme: theme)
        sparklineView.apply(theme: theme)
    }
}
