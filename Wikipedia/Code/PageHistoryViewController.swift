import UIKit
import WMF

@objc(WMFPageHistoryViewControllerDelegate)
protocol PageHistoryViewControllerDelegate: AnyObject {
    func pageHistoryViewControllerDidDisappear(_ pageHistoryViewController: PageHistoryViewController)
}

typealias PageHistoryCollectionViewCellSelectionThemeModel = PageHistoryViewController.SelectionThemeModel

@objc(WMFPageHistoryViewController)
class PageHistoryViewController: ColumnarCollectionViewController {
    private let pageTitle: String
    private let pageURL: URL

    private let pageHistoryFetcher = PageHistoryFetcher()
    private var pageHistoryFetcherParams: PageHistoryRequestParameters

    private var batchComplete = false
    private var isLoadingData = false

    private var cellLayoutEstimate: ColumnarCollectionViewLayoutHeightEstimate?

    var shouldLoadNewData: Bool {
        if batchComplete || isLoadingData {
            return false
        }
        let maxY = collectionView.contentOffset.y + collectionView.frame.size.height + 200.0;
        if (maxY >= collectionView.contentSize.height) {
            return true
        }
        return false;
    }

    @objc public weak var delegate: PageHistoryViewControllerDelegate?

    private lazy var countsViewController = PageHistoryCountsViewController(pageTitle: pageTitle, locale: NSLocale.wmf_locale(for: pageURL.wmf_language))

    @objc init(pageTitle: String, pageURL: URL) {
        self.pageTitle = pageTitle
        self.pageURL = pageURL
        self.pageHistoryFetcherParams = PageHistoryRequestParameters(title: pageTitle)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var pageHistorySections: [PageHistorySection] = []

    override var headerStyle: ColumnarCollectionViewController.HeaderStyle {
        return .sections
    }

    private lazy var compareButton = UIBarButtonItem(title: WMFLocalizedString("page-history-compare-title", value: "Compare", comment: "Title for action button that allows users to contrast different items"), style: .plain, target: self, action: #selector(compare(_:)))
    private lazy var cancelComparisonButton = UIBarButtonItem(title: CommonStrings.cancelActionTitle, style: .done, target: self, action: #selector(cancelComparison(_:)))

    override func viewDidLoad() {
        super.viewDidLoad()
        hintController = PageHistoryHintController()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Article", style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = compareButton
        title = CommonStrings.historyTabTitle

        addChild(countsViewController)
        navigationBar.addUnderNavigationBarView(countsViewController.view)
        navigationBar.shadowColorKeyPath = \Theme.colors.border
        countsViewController.didMove(toParent: self)

        collectionView.register(PageHistoryCollectionViewCell.self, forCellWithReuseIdentifier: PageHistoryCollectionViewCell.identifier)
        collectionView.dataSource = self
        view.wmf_addSubviewWithConstraintsToEdges(collectionView)

        apply(theme: theme)

        // TODO: Move networking

        pageHistoryFetcher.fetchPageCreationDate(for: pageTitle, pageURL: pageURL) { result in
            switch result {
            case .failure(let error):
                // TODO: Handle error
                print(error)
            case .success(let firstEditDate):
                self.pageHistoryFetcher.fetchEditCounts(.edits, for: self.pageTitle, pageURL: self.pageURL) { result in
                    switch result {
                    case .failure(let error):
                        // TODO: Handle error
                        print(error)
                    case .success(let editCounts):
                        if case let totalEditCount?? = editCounts[.edits] {
                            DispatchQueue.main.async {
                                self.countsViewController.set(totalEditCount: totalEditCount, firstEditDate: firstEditDate)
                            }
                        }
                    }
                }
            }
        }

        pageHistoryFetcher.fetchEditCounts(.edits, .anonEdits, .botEdits, .revertedEdits, for: pageTitle, pageURL: pageURL) { result in
            switch result {
            case .failure(let error):
                // TODO: Handle error
                print(error)
            case .success(let editCountsGroupedByType):
                DispatchQueue.main.async {
                    self.countsViewController.editCountsGroupedByType = editCountsGroupedByType
                }
            }
        }

        pageHistoryFetcher.fetchEditMetrics(for: pageTitle, pageURL: pageURL) { result in
            switch result {
            case .failure(let error):
                // TODO: Handle error
                print(error)
                self.countsViewController.timeseriesOfEditsCounts = []
            case .success(let timeseriesOfEditCounts):
                DispatchQueue.main.async {
                    self.countsViewController.timeseriesOfEditsCounts = timeseriesOfEditCounts
                }
            }
        }

        getPageHistory()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelComparison(nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.pageHistoryViewControllerDidDisappear(self)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cellLayoutEstimate = nil
    }

    private func getPageHistory() {
        isLoadingData = true

        pageHistoryFetcher.fetchRevisionInfo(pageURL, requestParams: pageHistoryFetcherParams, failure: { error in
            print(error)
            self.isLoadingData = false
        }) { results in
            self.pageHistorySections.append(contentsOf: results.items())
            self.pageHistoryFetcherParams = results.getPageHistoryRequestParameters(self.pageURL)
            self.batchComplete = results.batchComplete()
            self.isLoadingData = false
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        guard shouldLoadNewData else {
            return
        }
        getPageHistory()
    }

    private enum State {
        case idle
        case editing
    }

    private var maxNumberOfRevisionsSelected: Bool {
        assert((0...2).contains(selectedCellsCount))
        return selectedCellsCount == 2
    }
    private var selectedCellsCount = 0

    private var pageHistoryHintController: PageHistoryHintController? {
        return hintController as? PageHistoryHintController
    }

    private var state: State = .idle {
        didSet {
            switch state {
            case .idle:
                selectedCellsCount = 0
                pageHistoryHintController?.hide(true, presenter: self, theme: theme)
                openSelectionIndex = 0
                navigationItem.rightBarButtonItem = compareButton
                collectionView.indexPathsForSelectedItems?.forEach { collectionView.deselectItem(at: $0, animated: true) }
                forEachVisibleCell { (indexPath: IndexPath, cell: PageHistoryCollectionViewCell) in
                    self.updateSelectionThemeModel(nil, for: cell, at: indexPath)
                    self.collectionView.deselectItem(at: indexPath, animated: true)
                    cell.enableEditing(true) // confusing, have a reset method
                    cell.setEditing(false)
                }
                resetComparisonSelectionButtons()
                navigationController?.setToolbarHidden(true, animated: true)
            case .editing:
                navigationItem.rightBarButtonItem = cancelComparisonButton
                collectionView.allowsMultipleSelection = true
                forEachVisibleCell { $1.setEditing(true) }
                compareToolbarButton.isEnabled = false
                NSLayoutConstraint.activate([
                    firstComparisonSelectionButton.widthAnchor.constraint(equalToConstant: 90),
                    secondComparisonSelectionButton.widthAnchor.constraint(equalToConstant: 90)
                ])
                setToolbarItems([UIBarButtonItem(customView: firstComparisonSelectionButton), UIBarButtonItem.wmf_barButtonItem(ofFixedWidth: 10), UIBarButtonItem(customView: secondComparisonSelectionButton), UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),  compareToolbarButton], animated: true)
                navigationController?.setToolbarHidden(false, animated: true)
            }
            collectionView.collectionViewLayout.invalidateLayout()
            navigationItem.rightBarButtonItem?.tintColor = theme.colors.link
        }
    }

    private lazy var compareToolbarButton = UIBarButtonItem(title: "Compare", style: .plain, target: self, action: #selector(showDiff(_:)))
    private lazy var firstComparisonSelectionButton = makeComparisonSelectionButton()
    private lazy var secondComparisonSelectionButton = makeComparisonSelectionButton()

    private func makeComparisonSelectionButton() -> AlignedImageButton {
        let button = AlignedImageButton(frame: .zero)
        button.widthAnchor.constraint(equalToConstant: 90).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.cornerRadius = 8
        button.clipsToBounds = true
        button.backgroundColor = theme.colors.paperBackground
        button.imageView?.tintColor = theme.colors.link
        button.setTitleColor(theme.colors.link, for: .normal)
        button.titleLabel?.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        button.horizontalSpacing = 10
        button.contentHorizontalAlignment = .leading
        button.leftPadding = 10
        button.rightPadding = 10
        return button
    }

    @objc private func compare(_ sender: UIBarButtonItem) {
        state = .editing
    }

    private func forEachVisibleCell(_ block: (IndexPath, PageHistoryCollectionViewCell) -> Void) {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let pageHistoryCollectionViewCell = collectionView.cellForItem(at: indexPath) as? PageHistoryCollectionViewCell else {
                continue
            }
            block(indexPath, pageHistoryCollectionViewCell)
        }
    }

    @objc private func cancelComparison(_ sender: UIBarButtonItem?) {
        state = .idle
    }

    private func resetComparisonSelectionButtons() {
        firstComparisonSelectionButton.setTitle(nil, for: .normal)
        firstComparisonSelectionButton.setImage(nil, for: .normal)
        secondComparisonSelectionButton.setTitle(nil, for: .normal)
        secondComparisonSelectionButton.setImage(nil, for: .normal)
        firstComparisonSelectionButton.backgroundColor = theme.colors.paperBackground
        secondComparisonSelectionButton.backgroundColor = theme.colors.paperBackground
    }

    @objc private func showDiff(_ sender: UIBarButtonItem) {

    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        collectionView.backgroundColor = view.backgroundColor
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link
        navigationItem.leftBarButtonItem?.tintColor = theme.colors.primaryText
        countsViewController.apply(theme: theme)
        navigationController?.toolbar.isTranslucent = false
        navigationController?.toolbar.tintColor = theme.colors.midBackground
        navigationController?.toolbar.barTintColor = theme.colors.midBackground
        compareToolbarButton.tintColor = theme.colors.link
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return pageHistorySections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pageHistorySections[section].items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PageHistoryCollectionViewCell.identifier, for: indexPath) as? PageHistoryCollectionViewCell else {
            return UICollectionViewCell()
        }
        let item = pageHistorySections[indexPath.section].items[indexPath.item]
        configure(cell: cell, for: item, at: indexPath)
        return cell
    }

    override func configure(header: CollectionViewHeader, forSectionAt sectionIndex: Int, layoutOnly: Bool) {
        let section = pageHistorySections[sectionIndex]
        let sectionTitle: String?

        if sectionIndex == 0, let date = section.items.first?.revisionDate {
            sectionTitle = (date as NSDate).wmf_localizedRelativeDateFromMidnightUTCDate()
        } else {
            sectionTitle = section.sectionTitle
        }
        header.style = .pageHistory
        header.title = sectionTitle
        header.titleTextColorKeyPath = \Theme.colors.secondaryText
        header.layoutMargins = .zero
        header.apply(theme: theme)
    }

    // MARK: Layout

    // Reset on refresh
    private var cellContentCache = NSCache<NSIndexPath, CellContent>()

    private class CellContent: NSObject {
        let time: String?
        let displayTime: String?
        let author: String?
        let authorImage: UIImage?
        let sizeDiff: Int?
        let comment: String?
        var selectionThemeModel: SelectionThemeModel?
        var selectionIndex: Int?

        init(time: String?, displayTime: String?, author: String?, authorImage: UIImage?, sizeDiff: Int?, comment: String?, selectionThemeModel: SelectionThemeModel?, selectionIndex: Int?) {
            self.time = time
            self.displayTime = displayTime
            self.author = author
            self.authorImage = authorImage
            self.sizeDiff = sizeDiff
            self.comment = comment
            self.selectionThemeModel = selectionThemeModel
            self.selectionIndex = selectionIndex
            super.init()
        }
    }

    private func configure(cell: PageHistoryCollectionViewCell, for item: WMFPageHistoryRevision, at indexPath: IndexPath) {
        defer {
            cell.setEditing(state == .editing, animated: false)
            cell.enableEditing(!maxNumberOfRevisionsSelected, animated: false)
            cell.apply(theme: theme)
        }
        if let cachedCellContent = cellContentCache.object(forKey: indexPath as NSIndexPath) {
            cell.time = cachedCellContent.time
            cell.displayTime = cachedCellContent.displayTime
            cell.authorImage = cachedCellContent.authorImage
            cell.author = cachedCellContent.author
            cell.sizeDiff = cachedCellContent.sizeDiff
            cell.comment = cachedCellContent.comment
            if cell.isSelected {
                cell.selectionThemeModel = cachedCellContent.selectionThemeModel
            } else {
                cell.selectionThemeModel = maxNumberOfRevisionsSelected ? disabledSelectionThemeModel : nil
            }
            cell.selectionIndex = cachedCellContent.selectionIndex
        } else {
            if let date = item.revisionDate {
                if (date as NSDate).wmf_isTodayUTC() {
                    let diff = Calendar.current.dateComponents([.second, .minute, .hour], from: date, to: Date())
                    if let hours = diff.hour {
                        // TODO: Localize
                        cell.time = "\(hours)h"
                        cell.displayTime = "\(hours)h go"
                    } else if let minutes = diff.minute {
                        cell.time = "\(minutes)m"
                        cell.displayTime = "\(minutes)m ago"
                    } else if let seconds = diff.second {
                        cell.time = "\(seconds)s"
                        cell.displayTime = "\(seconds)s ago"
                    }
                } else if let dateString = DateFormatter.wmf_24hshortTime()?.string(from: date)  {
                    cell.time = "\(dateString)"
                    cell.displayTime = "\(dateString) UTC"
                }
            }
            cell.authorImage = item.isAnon ? UIImage(named: "anon") : UIImage(named: "user-edit")
            cell.author = item.user
            cell.sizeDiff = item.revisionSize
            cell.comment = item.parsedComment?.removingHTML
            if !cell.isSelected {
                cell.selectionThemeModel = maxNumberOfRevisionsSelected ? disabledSelectionThemeModel : nil
            }
        }

        cellContentCache.setObject(CellContent(time: cell.time, displayTime: cell.displayTime, author: cell.author, authorImage: cell.authorImage, sizeDiff: cell.sizeDiff, comment: cell.comment, selectionThemeModel: cell.selectionThemeModel, selectionIndex: cell.selectionIndex), forKey: indexPath as NSIndexPath)

        cell.apply(theme: theme)
    }

    private func updateSelectionThemeModel(_ selectionThemeModel: SelectionThemeModel?, for cell: PageHistoryCollectionViewCell, at indexPath: IndexPath) {
        cell.selectionThemeModel = selectionThemeModel
        cellContentCache.object(forKey: indexPath as NSIndexPath)?.selectionThemeModel = selectionThemeModel
    }

    private func updateSelectionIndex(_ selectionIndex: Int?, for cell: PageHistoryCollectionViewCell, at indexPath: IndexPath) {
        cell.selectionIndex = selectionIndex
        cellContentCache.object(forKey: indexPath as NSIndexPath)?.selectionIndex = selectionIndex
    }

    public class SelectionThemeModel {
        let selectedImage: UIImage?
        let borderColor: UIColor
        let backgroundColor: UIColor
        let authorColor: UIColor
        let commentColor: UIColor
        let timeColor: UIColor
        let sizeDiffAdditionColor: UIColor
        let sizeDiffSubtractionColor: UIColor
        let sizeDiffNoDifferenceColor: UIColor

        init(selectedImage: UIImage?, borderColor: UIColor, backgroundColor: UIColor, authorColor: UIColor, commentColor: UIColor, timeColor: UIColor, sizeDiffAdditionColor: UIColor, sizeDiffSubtractionColor: UIColor, sizeDiffNoDifferenceColor: UIColor) {
            self.selectedImage = selectedImage
            self.borderColor = borderColor
            self.backgroundColor = backgroundColor
            self.authorColor = authorColor
            self.commentColor = commentColor
            self.timeColor = timeColor
            self.sizeDiffAdditionColor = sizeDiffAdditionColor
            self.sizeDiffSubtractionColor = sizeDiffSubtractionColor
            self.sizeDiffNoDifferenceColor = sizeDiffNoDifferenceColor
        }
    }

    private lazy var firstSelectionThemeModel: SelectionThemeModel = {
        return SelectionThemeModel(selectedImage: UIImage(named: "selected-accent"), borderColor: UIColor.osage, backgroundColor: UIColor("FEF9E7"), authorColor: UIColor.osage, commentColor: .abbey, timeColor: .battleshipGray, sizeDiffAdditionColor: theme.colors.accent, sizeDiffSubtractionColor: theme.colors.destructive, sizeDiffNoDifferenceColor: theme.colors.link)
    }()

    private lazy var secondSelectionThemeModel: SelectionThemeModel = {
        return SelectionThemeModel(selectedImage: nil, borderColor: theme.colors.link.withAlphaComponent(0.3), backgroundColor: UIColor.lightBlue, authorColor: theme.colors.link, commentColor: .abbey, timeColor: .battleshipGray, sizeDiffAdditionColor: theme.colors.accent, sizeDiffSubtractionColor: theme.colors.destructive, sizeDiffNoDifferenceColor: theme.colors.link)
    }()

    private lazy var disabledSelectionThemeModel: SelectionThemeModel = {
        return SelectionThemeModel(selectedImage: nil, borderColor: theme.colors.border, backgroundColor: theme.colors.paperBackground, authorColor: theme.colors.secondaryText, commentColor: theme.colors.secondaryText, timeColor: .battleshipGray, sizeDiffAdditionColor: theme.colors.secondaryText, sizeDiffSubtractionColor: theme.colors.secondaryText, sizeDiffNoDifferenceColor: theme.colors.secondaryText)
    }()

    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        if let estimate = cellLayoutEstimate {
            return estimate
        }
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 80)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: PageHistoryCollectionViewCell.identifier) as? PageHistoryCollectionViewCell else {
            return estimate
        }
        let item = pageHistorySections[indexPath.section].items[indexPath.item]
        configure(cell: placeholderCell, for: item, at: indexPath)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        cellLayoutEstimate = estimate
        return estimate
    }

    override func metrics(with boundsSize: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: boundsSize, readableWidth: readableWidth, layoutMargins: layoutMargins, interSectionSpacing: 0, interItemSpacing: 20)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return state == .editing && !maxNumberOfRevisionsSelected
    }

    var openSelectionIndex = 0

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCellsCount += 1
        defer {
            compareToolbarButton.isEnabled = maxNumberOfRevisionsSelected
        }

        guard let cell = collectionView.cellForItem(at: indexPath) as? PageHistoryCollectionViewCell else {
            return
        }

        let button: UIButton?
        let themeModel: SelectionThemeModel?
        if maxNumberOfRevisionsSelected {
            forEachVisibleCell { (indexPath: IndexPath, cell: PageHistoryCollectionViewCell) in
                if !cell.isSelected {
                    self.updateSelectionThemeModel(self.disabledSelectionThemeModel, for: cell, at: indexPath)
                }
                cell.enableEditing(false)
            }
            pageHistoryHintController?.hide(false, presenter: self, theme: theme)
        }
        switch openSelectionIndex {
        case 0:
            button = firstComparisonSelectionButton
            themeModel = firstSelectionThemeModel
        case 1:
            button = secondComparisonSelectionButton
            themeModel = secondSelectionThemeModel
        default:
            button = nil
            themeModel = nil
        }
        if let button = button, let themeModel = themeModel {
            button.backgroundColor = themeModel.backgroundColor
            button.setImage(cell.authorImage, for: .normal)
            button.setTitle(cell.time, for: .normal)
            button.imageView?.tintColor = themeModel.authorColor
            button.setTitleColor(themeModel.authorColor, for: .normal)
            button.tintColor = themeModel.authorColor
        }
        updateSelectionIndex(openSelectionIndex, for: cell, at: indexPath)
        updateSelectionThemeModel(themeModel, for: cell, at: indexPath)
        cell.apply(theme: theme)

        openSelectionIndex += 1
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        selectedCellsCount -= 1
        pageHistoryHintController?.hide(true, presenter: self, theme: theme)
        if let cell = collectionView.cellForItem(at: indexPath) as? PageHistoryCollectionViewCell, let selectionIndex = cell.selectionIndex {
            openSelectionIndex = collectionView.indexPathsForSelectedItems?.count ?? 0 == 0 ? 0 : selectionIndex
            forEachVisibleCell { (indexPath: IndexPath, cell: PageHistoryCollectionViewCell) in
                self.updateSelectionThemeModel(nil, for: cell, at: indexPath)
                cell.enableEditing(true, animated: false)
            }
            let button: UIButton?
            switch selectionIndex {
            case 0:
                button = firstComparisonSelectionButton
            case 1:
                button = secondComparisonSelectionButton
            default:
                button = nil
            }
            button?.backgroundColor = theme.colors.paperBackground
            button?.setImage(nil, for: .normal)
            button?.setTitle(nil, for: .normal)
            updateSelectionIndex(nil, for: cell, at: indexPath)
            updateSelectionThemeModel(nil, for: cell, at: indexPath)
            cell.apply(theme: theme)
        }
        compareToolbarButton.isEnabled = collectionView.indexPathsForSelectedItems?.count ?? 0 == 2
    }
}
