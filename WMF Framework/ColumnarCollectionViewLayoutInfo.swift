struct ColumnarCollectionViewLayoutSectionInvalidationResults {
    let invalidatedHeaderIndexPaths: [IndexPath]
    let invalidatedItemIndexPaths: [IndexPath]
    let invalidatedFooterIndexPaths: [IndexPath]
    
    static let empty: ColumnarCollectionViewLayoutSectionInvalidationResults = ColumnarCollectionViewLayoutSectionInvalidationResults(invalidatedHeaderIndexPaths: [], invalidatedItemIndexPaths: [], invalidatedFooterIndexPaths: [])
}

public class ColumnarCollectionViewLayoutInfo {
    var sections: [ColumnarCollectionViewLayoutSection] = []
    var contentSize: CGSize = .zero
    
    func layout(with metrics: ColumnarCollectionViewLayoutMetrics, delegate: ColumnarCollectionViewLayoutDelegate, collectionView: UICollectionView, invalidationContext context: ColumnarCollectionViewLayoutInvalidationContext?) {
        guard let dataSource = collectionView.dataSource else {
            return
        }
        guard let countOfSections = dataSource.numberOfSections?(in: collectionView), countOfSections > 0 else {
            return
        }
        sections.reserveCapacity(countOfSections)
        let x = metrics.layoutMargins.left
        var y = metrics.layoutMargins.top
        let width = metrics.boundsSize.width - metrics.layoutMargins.left - metrics.layoutMargins.right
        for sectionIndex in 0..<countOfSections {
            let countOfItems = dataSource.collectionView(collectionView, numberOfItemsInSection: sectionIndex)
            let section = ColumnarCollectionViewLayoutSection(sectionIndex: sectionIndex, frame: CGRect(x: x, y: y, width: width, height: 0), metrics: metrics, countOfItems: countOfItems)
            sections.append(section)
            let headerWidth = section.widthForSupplementaryViews
            let headerHeightEstimate = delegate.collectionView(collectionView, estimatedHeightForHeaderInSection: sectionIndex, forColumnWidth: headerWidth)
            if !headerHeightEstimate.height.isEqual(to: 0) {
                let headerAttributes = ColumnarCollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: IndexPath(item: 0, section: sectionIndex))
                headerAttributes.layoutMargins = metrics.itemLayoutMargins
                headerAttributes.precalculated = headerHeightEstimate.precalculated
                headerAttributes.frame = CGRect(origin: section.originForNextSupplementaryView, size: CGSize(width: headerWidth, height: headerHeightEstimate.height))
                headerAttributes.zIndex = -10
                section.addHeader(headerAttributes)
            }
            for itemIndex in 0..<countOfItems {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                let itemWidth = section.widthForNextItem
                let itemSizeEstimate = delegate.collectionView(collectionView, estimatedHeightForItemAt: indexPath, forColumnWidth: itemWidth)
                let itemAttributes = ColumnarCollectionViewLayoutAttributes(forCellWith: indexPath)
                itemAttributes.precalculated = itemSizeEstimate.precalculated
                itemAttributes.layoutMargins = metrics.itemLayoutMargins
                itemAttributes.zIndex = 0
                itemAttributes.frame = CGRect(origin: section.originForNextItem, size: CGSize(width: itemWidth, height: itemSizeEstimate.height))
                section.addItem(itemAttributes)
            }
            let footerWidth = section.widthForSupplementaryViews
            let footerHeightEstimate = delegate.collectionView(collectionView, estimatedHeightForFooterInSection: sectionIndex, forColumnWidth: footerWidth)
            if delegate.collectionView(collectionView, shouldShowFooterForSection: sectionIndex), !footerHeightEstimate.height.isEqual(to: 0) {
                let footerAttributes = ColumnarCollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, with: IndexPath(item: 0, section: sectionIndex))
                footerAttributes.layoutMargins = metrics.itemLayoutMargins
                footerAttributes.precalculated = footerHeightEstimate.precalculated
                let footerOrigin = CGPoint(x: 0, y: y + section.frame.height)
                footerAttributes.frame = CGRect(origin: footerOrigin, size: CGSize(width: width, height: footerHeightEstimate.height))
                footerAttributes.zIndex = -10
                section.addFooter(footerAttributes)
            }
            y += section.frame.size.height + metrics.interSectionSpacing
        }
        y += metrics.layoutMargins.bottom
        contentSize = CGSize(width: metrics.boundsSize.width, height: y)
    }
    
    func update(with metrics: ColumnarCollectionViewLayoutMetrics, invalidationContext context: ColumnarCollectionViewLayoutInvalidationContext, delegate: ColumnarCollectionViewLayoutDelegate, collectionView: UICollectionView) {
        guard let originalAttributes = context.originalLayoutAttributes as? ColumnarCollectionViewLayoutAttributes, let preferredAttributes = context.preferredLayoutAttributes as? ColumnarCollectionViewLayoutAttributes else {
            assert(false)
            return
        }
        
        let indexPath = originalAttributes.indexPath
        let sectionIndex = indexPath.section
        guard sections.indices.contains(sectionIndex) else {
            assert(false)
            return
        }
        
        let section = sections[sectionIndex]
        
        let oldHeight = section.frame.height
        let result = section.invalidate(originalAttributes, with: preferredAttributes)
        let newHeight = section.frame.height
        let deltaY = newHeight - oldHeight
        var invalidatedHeaderIndexPaths: [IndexPath] = result.invalidatedHeaderIndexPaths
        var invalidatedItemIndexPaths: [IndexPath] = result.invalidatedItemIndexPaths
        var invalidatedFooterIndexPaths: [IndexPath] = result.invalidatedFooterIndexPaths
        if !deltaY.isEqual(to: 0) {
            contentSize.height += deltaY
            let nextSectionIndex = sectionIndex + 1
            if nextSectionIndex < sections.count {
                for section in sections[nextSectionIndex..<sections.count] {
                    let result = section.translate(deltaY: deltaY)
                    invalidatedHeaderIndexPaths.append(contentsOf: result.invalidatedHeaderIndexPaths)
                    invalidatedItemIndexPaths.append(contentsOf: result.invalidatedItemIndexPaths)
                    invalidatedFooterIndexPaths.append(contentsOf: result.invalidatedFooterIndexPaths)
                }
            }
        }
        
        if !invalidatedHeaderIndexPaths.isEmpty {
            context.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader, at: invalidatedHeaderIndexPaths)
        }
        
        if !invalidatedItemIndexPaths.isEmpty {
            context.invalidateItems(at: invalidatedItemIndexPaths)
        }
        
        if !invalidatedFooterIndexPaths.isEmpty {
            context.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindSectionFooter, at: invalidatedFooterIndexPaths)
        }
    }
    
    func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard sections.indices.contains(indexPath.section) else {
            return nil
        }
        let section = sections[indexPath.section]
        guard section.items.indices.contains(indexPath.item) else {
            return nil
        }
        return section.items[indexPath.item]
    }
    
    public func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard sections.indices.contains(indexPath.section) else {
            return nil
        }
        let section = sections[indexPath.section]
        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            guard section.headers.indices.contains(indexPath.item) else {
                return nil
            }
            return section.headers[indexPath.item]
        case UICollectionView.elementKindSectionFooter:
            guard section.footers.indices.contains(indexPath.item) else {
                return nil
            }
            return section.footers[indexPath.item]
        default:
            return nil
        }
    }
}

class ColumnarCollectionViewLayoutInvalidationContext: UICollectionViewLayoutInvalidationContext {
    var originalLayoutAttributes: UICollectionViewLayoutAttributes?
    var preferredLayoutAttributes: UICollectionViewLayoutAttributes?
    var boundsDidChange: Bool = false
}

public class ColumnarCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
    public var precalculated: Bool = false
    public var layoutMargins: UIEdgeInsets = .zero
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone)
        guard let la = copy as? ColumnarCollectionViewLayoutAttributes else {
            return copy
        }
        la.precalculated = precalculated
        la.layoutMargins = layoutMargins
        return la
    }
}

public struct ColumnarCollectionViewLayoutHeightEstimate {
    public var precalculated: Bool
    public var height: CGFloat
    public init(precalculated: Bool, height: CGFloat) {
        self.precalculated = precalculated
        self.height = height
    }
}
