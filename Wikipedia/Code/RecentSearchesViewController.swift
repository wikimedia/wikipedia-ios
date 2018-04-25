import UIKit
import WMF

@objc(WMFRecentSearchesViewControllerDelegate)
protocol RecentSearchesViewControllerDelegate: NSObjectProtocol {
    func recentSearchController(_: RecentSearchesViewController, didSelectSearchTerm: MWKRecentSearchEntry?)
}

@objc(WMFRecentSearchesViewController)
class RecentSearchesViewController: ArticleCollectionViewController {
    @objc weak var recentSearchesViewControllerDelegate: RecentSearchesViewControllerDelegate?
    @objc var recentSearches: MWKRecentSearchList?
    
    @objc func reloadRecentSearches() {
        collectionView.reloadData()
        updateHeaderVisibility()
        updateTrashButtonEnabledState()
    }
    
    func updateHeaderVisibility() {
        
    }
    
    func updateTrashButtonEnabledState() {
        
    }

    @objc(deselectAllAnimated:)
    func deselectAll(animated: Bool) {
        guard let selected = collectionView.indexPathsForSelectedItems else {
            return
        }
        for indexPath in selected {
            collectionView.deselectItem(at: indexPath, animated: animated)
        }
    }
    
    override func articleURL(at indexPath: IndexPath) -> URL? {
        return nil
    }
    
    override func article(at indexPath: IndexPath) -> WMFArticle? {
        return nil
    }
    
    override func canDelete(at indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func willPerformAction(_ action: Action) -> Bool {
        return self.editController.didPerformAction(action)
    }
    
    override func delete(at indexPath: IndexPath) {
        guard let entry = recentSearches?.entries[indexPath.item] else {
            return
        }
        recentSearches?.removeEntry(entry)
        recentSearches?.save()
        collectionView.reloadData()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recentSearches?.entries.count ?? 0
    }
    
    override func configure(cell: ArticleRightAlignedImageCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        guard let entry = recentSearches?.entries[indexPath.item] else {
            return
        }
        cell.articleSemanticContentAttribute = .unspecified
        cell.configureForCompactList(at: indexPath.item)
        cell.titleLabel.text = entry.searchTerm
        cell.isImageViewHidden = true
        cell.apply(theme: theme)
        cell.actions = availableActions(at: indexPath)
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        recentSearchesViewControllerDelegate?.recentSearchController(self, didSelectSearchTerm: recentSearches?.entry(at: UInt(indexPath.item)))
    }
}
