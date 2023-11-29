public protocol ColumnarCollectionViewLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForFooterInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate
    func collectionView(_ collectionView: UICollectionView, shouldShowFooterForSection section: Int) -> Bool
    func metrics(with boundsSize: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics
}

public class ColumnarCollectionViewLayout: UICollectionViewLayout {
    var info: ColumnarCollectionViewLayoutInfo? {
        didSet {
            oldInfo = oldValue
        }
    }
    var oldInfo: ColumnarCollectionViewLayoutInfo?
    var metrics: ColumnarCollectionViewLayoutMetrics?
    var isLayoutValid: Bool = false
    let defaultColumnWidth: CGFloat = 315
    let maxColumnWidth: CGFloat = 740
    public var slideInNewContentFromTheTop: Bool = false
    public var animateItems: Bool = false

    override public class var layoutAttributesClass: Swift.AnyClass {
        return ColumnarCollectionViewLayoutAttributes.self
    }
    
    override public class var invalidationContextClass: Swift.AnyClass {
        return ColumnarCollectionViewLayoutInvalidationContext.self
    }
    
    private var delegate: ColumnarCollectionViewLayoutDelegate? {
        return collectionView?.delegate as? ColumnarCollectionViewLayoutDelegate
    }
    
    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let sections = info?.sections else {
            return []
        }
        var attributes: [UICollectionViewLayoutAttributes] = []
        for section in sections {
            guard rect.intersects(section.frame) else {
                continue
            }
            for item in section.headers {
                guard rect.intersects(item.frame) else {
                    continue
                }
                attributes.append(item)
            }
            for item in section.items {
                guard rect.intersects(item.frame) else {
                    continue
                }
                attributes.append(item)
            }
            for item in section.footers {
                guard rect.intersects(item.frame) else {
                    continue
                }
                attributes.append(item)
            }
        }
        return attributes
    }
    
    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return info?.layoutAttributesForItem(at: indexPath)
    }
    
    public override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return nil
    }
    
    public override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return info?.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
    }
    
    public var itemLayoutMargins: UIEdgeInsets {
        guard let metrics = metrics else {
            return .zero
        }
        return metrics.itemLayoutMargins
    }
    
    override public var collectionViewContentSize: CGSize {
        guard let info = info else {
            return .zero
        }
        return info.contentSize
    }
    
    public func layoutHeight(forWidth width: CGFloat) -> CGFloat {
        guard let collectionView = collectionView, let delegate = delegate, width >= 1 else {
            return 0
        }
        let oldMetrics = metrics
        let newInfo = ColumnarCollectionViewLayoutInfo()
        let newMetrics = delegate.metrics(with: CGSize(width: width, height: 100), readableWidth: width, layoutMargins: .zero)
        metrics = newMetrics // needs to be set so that layout margins can be queried. probably not the best solution.
        newInfo.layout(with: newMetrics, delegate: delegate, collectionView: collectionView, invalidationContext: nil)
        metrics = oldMetrics
        return newInfo.contentSize.height
    }

    override public func prepare() {
        defer {
            super.prepare()
        }
        
        guard let collectionView = collectionView else {
            return
        }
        
        let size = collectionView.bounds.size
        guard size.width > 0 && size.height > 0 else {
            return
        }
        
        let readableWidth: CGFloat = collectionView.readableContentGuide.layoutFrame.size.width
        
        if let metrics = metrics, !metrics.readableWidth.isEqual(to: readableWidth) {
            isLayoutValid = false
        }
        
        guard let delegate = delegate, !isLayoutValid else {
            return
        }

        let delegateMetrics = delegate.metrics(with: size, readableWidth: readableWidth, layoutMargins: collectionView.layoutMargins)
        metrics = delegateMetrics
        let newInfo = ColumnarCollectionViewLayoutInfo()
        newInfo.layout(with: delegateMetrics, delegate: delegate, collectionView: collectionView, invalidationContext: nil)
        info = newInfo
        isLayoutValid = true
    }
    
    // MARK: - Invalidation
    
    override public func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        defer {
            super.invalidateLayout(with: context)
        }
        
        guard let context = context as? ColumnarCollectionViewLayoutInvalidationContext else {
            return
        }
        
        guard context.invalidateEverything || context.invalidateDataSourceCounts || context.boundsDidChange else {
            return
        }
        
        isLayoutValid = false
    }
    
    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let metrics = metrics else {
            return true
        }
        return !newBounds.size.width.isEqual(to: metrics.boundsSize.width)
    }
    
    override public func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let superContext = super.invalidationContext(forBoundsChange: newBounds)
        let context = superContext as? ColumnarCollectionViewLayoutInvalidationContext ?? ColumnarCollectionViewLayoutInvalidationContext()
        context.boundsDidChange = true
        return context
    }
    
    override public func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        return !preferredAttributes.frame.equalTo(originalAttributes.frame)
    }
    
    override public func invalidationContext(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
        let superContext = super.invalidationContext(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
        let context = superContext as? ColumnarCollectionViewLayoutInvalidationContext ?? ColumnarCollectionViewLayoutInvalidationContext()
        context.preferredLayoutAttributes = preferredAttributes
        context.originalLayoutAttributes = originalAttributes
        if let delegate = delegate, let metrics = metrics, let info = info, let collectionView = collectionView {
            info.update(with: metrics, invalidationContext: context, delegate: delegate, collectionView: collectionView)
        }
        return context
    }

    // MARK: - Animation
    
    var maxNewSection: Int = -1
    var newSectionDeltaY: CGFloat = 0
    var appearingIndexPaths: Set<IndexPath> = []
    var disappearingIndexPaths: Set<IndexPath> = []
    override public func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
        guard animateItems, let info = info else {
            appearingIndexPaths.removeAll(keepingCapacity: true)
            disappearingIndexPaths.removeAll(keepingCapacity: true)
            maxNewSection = -1
            newSectionDeltaY = 0
            return
        }
        
        if slideInNewContentFromTheTop {
            var maxSection = -1
            for updateItem in updateItems {
                guard let after = updateItem.indexPathAfterUpdate, after.item == NSNotFound, updateItem.indexPathBeforeUpdate == nil else {
                    continue
                }
                let section: Int = after.section
                guard section == maxSection + 1 else {
                    continue
                }
                maxSection = section
            }
            guard maxSection > -1 && maxSection < info.sections.count else {
                maxNewSection = -1
                return
            }
            maxNewSection = maxSection
            let sectionFrame = info.sections[maxSection].frame
            newSectionDeltaY = 0 - sectionFrame.maxY
            appearingIndexPaths.removeAll(keepingCapacity: true)
            disappearingIndexPaths.removeAll(keepingCapacity: true)
        } else {
            appearingIndexPaths.removeAll(keepingCapacity: true)
            disappearingIndexPaths.removeAll(keepingCapacity: true)
            newSectionDeltaY = 0
            maxNewSection = -1
            for updateItem in updateItems {
                if let after = updateItem.indexPathAfterUpdate, updateItem.indexPathBeforeUpdate == nil {
                    appearingIndexPaths.insert(after)
                } else if let before = updateItem.indexPathBeforeUpdate, updateItem.indexPathAfterUpdate == nil {
                    disappearingIndexPaths.insert(before)
                }
            }
        }
    }
    
    private func adjustAttributesIfNecessary(_ attributes: UICollectionViewLayoutAttributes, forItemOrElementAppearingAtIndexPath indexPath: IndexPath) {
        guard indexPath.section <= maxNewSection else {
            guard animateItems, appearingIndexPaths.contains(indexPath) else {
                return
            }
            attributes.zIndex = -1
            attributes.alpha = 0
            return
        }
        attributes.frame.origin.y += newSectionDeltaY
        attributes.alpha = 1
    }
    
    public override func initialLayoutAttributesForAppearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.initialLayoutAttributesForAppearingSupplementaryElement(ofKind: elementKind, at: elementIndexPath) else {
            return nil
        }
        adjustAttributesIfNecessary(attributes, forItemOrElementAppearingAtIndexPath: elementIndexPath)
        return attributes
    }
    
    public override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath) else {
            return nil
        }
        adjustAttributesIfNecessary(attributes, forItemOrElementAppearingAtIndexPath: itemIndexPath)
        return attributes
    }
    
    public override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath) else {
            return nil
        }
        guard animateItems, disappearingIndexPaths.contains(itemIndexPath) else {
            return attributes
        }
        attributes.zIndex = -1
        attributes.alpha = 0
        return attributes
    }

    // MARK: Scroll View

    public var currentSection: Int?

    public override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        var superTarget = super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        if let currentSection = currentSection,
            let oldInfo = oldInfo,
            let info = info,
            oldInfo.sections.indices.contains(currentSection),
            info.sections.indices.contains(currentSection) {
            let oldY = oldInfo.sections[currentSection].frame.origin.y
            let newY = info.sections[currentSection].frame.origin.y
            let deltaY = newY - oldY
            superTarget.y += deltaY
        }
        return superTarget
    }
}

extension ColumnarCollectionViewLayout: NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        let newLayout = ColumnarCollectionViewLayout()
        newLayout.info = info
        newLayout.oldInfo = oldInfo
        newLayout.metrics = metrics
        newLayout.isLayoutValid = isLayoutValid
        newLayout.slideInNewContentFromTheTop = slideInNewContentFromTheTop
        newLayout.animateItems = animateItems
        
        newLayout.maxNewSection = maxNewSection
        newLayout.newSectionDeltaY = newSectionDeltaY
        newLayout.appearingIndexPaths = appearingIndexPaths
        newLayout.disappearingIndexPaths = disappearingIndexPaths
        
        return newLayout
    }
}
