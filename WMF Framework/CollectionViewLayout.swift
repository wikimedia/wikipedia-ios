import UIKit

class CollectionViewLayoutInvalidationContext: UICollectionViewLayoutInvalidationContext {
    var originalLayoutAttributes: UICollectionViewLayoutAttributes?
    var preferredLayoutAttributes: UICollectionViewLayoutAttributes?
    var boundsDidChange: Bool = false
}

class CollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
    var precalculated: Bool = false
    var layoutMargins: UIEdgeInsets = .zero
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone)
        guard let la = copy as? CollectionViewLayoutAttributes else {
            return copy
        }
        la.precalculated = precalculated
        la.layoutMargins = layoutMargins
        return la
    }
}

struct CollectionViewLayoutHeightEstimate {
    var precalculated: Bool = false
    var height: CGFloat = 0
}

protocol CollectionViewLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> CollectionViewLayoutHeightEstimate
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> CollectionViewLayoutHeightEstimate
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForFooterInSection section: Int, forColumnWidth columnWidth: CGFloat) -> CollectionViewLayoutHeightEstimate
    func collectionView(_ collectionView: UICollectionView, prefersWiderColumnForSectionAt index: Int) -> Bool
    func metrics(withBoundsSize size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> CollectionViewLayoutMetrics
}


struct CollectionViewLayoutMetrics {
    let boundsSize: CGSize
    let layoutInset: UIEdgeInsets
    let itemLayoutMargins: UIEdgeInsets
    let readableWidth: CGFloat
    var shouldMatchColumnHeights = false
}

class CollectionViewLayoutInfo {
    var sections: [CollectionViewLayoutSection] = []
    var contentSize: CGSize = .zero
    func layout(with metrics: CollectionViewLayoutMetrics, delegate: CollectionViewLayoutDelegate, collectionView: UICollectionView, invalidationContext context: CollectionViewLayoutInvalidationContext?) {
        
        
        
    }
    
    func update(with metrics: CollectionViewLayoutMetrics, invalidationContext context: CollectionViewLayoutInvalidationContext, delegate: CollectionViewLayoutDelegate, collectionView: UICollectionView) {
    }
    
    func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return nil
    }

}

class CollectionViewLayoutSection {
    var headers: [CollectionViewLayoutAttributes] = []
    var items: [CollectionViewLayoutAttributes] = []
    var footers: [CollectionViewLayoutAttributes] = []
    var columns: [CollectionViewLayoutColumn] = []
}

class CollectionViewLayoutColumn {
    var items: [CollectionViewLayoutAttributes] = []
}

class CollectionViewLayout: UICollectionViewLayout {
    var info: CollectionViewLayoutInfo?
    var metrics: CollectionViewLayoutMetrics?
    var isLayoutValid: Bool = false
    let defaultColumnWidth: CGFloat = 315
    let maxColumnWidth: CGFloat = 740
    
    override class var layoutAttributesClass: Swift.AnyClass {
        return CollectionViewLayoutAttributes.self
    }
    
    override class var invalidationContextClass: Swift.AnyClass {
        return CollectionViewLayoutInvalidationContext.self
    }
    
    private var delegate: CollectionViewLayoutDelegate {
        return collectionView!.delegate as! CollectionViewLayoutDelegate
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return []
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return info?.layoutAttributesForItem(at: indexPath)
    }
    
    var itemLayoutMargins: UIEdgeInsets {
        guard let metrics = metrics else {
            return .zero
        }
        return metrics.itemLayoutMargins
    }
    
    override var collectionViewContentSize: CGSize {
        guard let info = info else {
            return .zero
        }
        return info.contentSize
    }
    
    public func layoutHeight(forWidth width: CGFloat) -> CGFloat {
        guard let collectionView = collectionView, width >= 1 else {
            return 0
        }
        let info = CollectionViewLayoutInfo()
        let metrics = delegate.metrics(withBoundsSize: CGSize(width: width, height: 100), readableWidth: width, layoutMargins: .zero)
        info.layout(with: metrics, delegate: delegate, collectionView: collectionView, invalidationContext: nil)
        return info.contentSize.height
    }

    override func prepare() {
        defer {
            super.prepare()
        }
        
        guard let collectionView = collectionView else {
            return
        }
        
        let readableWidth: CGFloat
        if #available(iOS 11.0, *) {
            readableWidth = collectionView.readableContentGuide.layoutFrame.size.width
        } else {
            readableWidth = min(maxColumnWidth, collectionView.bounds.size.width - collectionView.layoutMargins.left - collectionView.layoutMargins.right)
        }
        
        
        if let metrics = metrics, metrics.readableWidth != readableWidth {
            isLayoutValid = false
        }
        
        let size = collectionView.bounds.size
        
        guard !isLayoutValid, size.width > 0, size.height > 0 else {
            return
        }

        let delegateMetrics = delegate.metrics(withBoundsSize: size, readableWidth: readableWidth, layoutMargins: collectionView.scrollIndicatorInsets)
        let newInfo = CollectionViewLayoutInfo()
        newInfo.layout(with: delegateMetrics, delegate: delegate, collectionView: collectionView, invalidationContext: nil)
        metrics = delegateMetrics
        info = newInfo
        isLayoutValid = true
    }
    
    // MARK - Invalidation
    
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        defer {
            super.invalidateLayout(with: context)
        }
        
        guard let context = context as? CollectionViewLayoutInvalidationContext else {
            return
        }
        
        guard context.boundsDidChange || context.invalidateEverything || context.invalidateDataSourceCounts else {
            return
        }
        
        isLayoutValid = false
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let metrics = metrics else {
            return true
        }
        return newBounds.size.width != metrics.boundsSize.width
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let superContext = super.invalidationContext(forBoundsChange: newBounds)
        guard let context = superContext as? CollectionViewLayoutInvalidationContext else {
            return superContext
        }
        context.boundsDidChange = true
        return context
    }
    
    override func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        return preferredAttributes.frame != originalAttributes.frame
    }
    
    override func invalidationContext(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
        let superContext = super.invalidationContext(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
        guard let context = superContext as? CollectionViewLayoutInvalidationContext else {
            return superContext
        }
        context.preferredLayoutAttributes = preferredAttributes
        context.originalLayoutAttributes = originalAttributes
        if let metrics = metrics, let info = info, let collectionView = collectionView {
            info.update(with: metrics, invalidationContext: context, delegate: delegate, collectionView: collectionView)
        }
        return context
    }
    
    // MARK - Animation
    
    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
    }
}
