import UIKit

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

public struct ColumnarCollectionViewLayoutMetrics {
    let boundsSize: CGSize
    let layoutInset: UIEdgeInsets
    let itemLayoutMargins: UIEdgeInsets
    let countOfColumns: Int = 1
    let readableWidth: CGFloat
    let interSectionSpacing: CGFloat
    let interItemSpacing: CGFloat
    var shouldMatchColumnHeights = false
    
    public static func singleColumnMetrics(withBoundsSize: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics(boundsSize: withBoundsSize, layoutInset: layoutMargins, itemLayoutMargins: UIEdgeInsets.zero, readableWidth: readableWidth, interSectionSpacing: 0, interItemSpacing: 0, shouldMatchColumnHeights: false)
    }
    
    public static func singleColumnMetrics(withBoundsSize: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets, interItemSpacing: CGFloat, interSectionSpacing: CGFloat) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics(boundsSize: withBoundsSize, layoutInset: layoutMargins, itemLayoutMargins: UIEdgeInsets.zero, readableWidth: readableWidth, interSectionSpacing: 0, interItemSpacing: 0, shouldMatchColumnHeights: false)
    }
}

public class ColumnarCollectionViewLayoutInfo {
    var sections: [ColumnarCollectionViewLayoutSection] = []
    var contentSize: CGSize = .zero
    
    func layout(with metrics: ColumnarCollectionViewLayoutMetrics, delegate: ColumnarCollectionViewLayoutDelegate, collectionView: UICollectionView, invalidationContext context: ColumnarCollectionViewLayoutInvalidationContext?) {
        guard let dataSource = collectionView.dataSource else {
            return
        }
        
        guard let countOfSections = dataSource.numberOfSections?(in: collectionView) else {
            return
        }
        let bounds = CGRect(origin: .zero, size: metrics.boundsSize)
        let insetBounds = UIEdgeInsetsInsetRect(bounds, metrics.layoutInset)
        let x = insetBounds.minX
        var y = insetBounds.minY
        let width = insetBounds.width
        for sectionIndex in 0..<countOfSections {
            let section = ColumnarCollectionViewLayoutSection(sectionIndex: sectionIndex, frame: CGRect(x: x, y: y, width: width, height: 0), countOfColumns: metrics.countOfColumns, columnSpacing: 0)
            sections.append(section)
            let headerWidth = section.widthForSupplementaryViews
            let headerHeightEstimate = delegate.collectionView(collectionView, estimatedHeightForHeaderInSection: sectionIndex, forColumnWidth: headerWidth)
            if !headerHeightEstimate.height.isEqual(to: 0) {
                let headerAttributes = ColumnarCollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, with: IndexPath(item: 0, section: sectionIndex))
                headerAttributes.precalculated = headerHeightEstimate.precalculated
                headerAttributes.frame = CGRect(origin: section.originForNextSupplementaryView, size: CGSize(width: headerWidth, height: headerHeightEstimate.height))
                section.addHeader(headerAttributes)
            }
            let countOfItems = dataSource.collectionView(collectionView, numberOfItemsInSection: sectionIndex)
            for itemIndex in 0..<countOfItems {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                let itemWidth = section.widthForNextItem
                let itemSizeEstimate = delegate.collectionView(collectionView, estimatedHeightForItemAt: indexPath, forColumnWidth: itemWidth)
                let itemAttributes = ColumnarCollectionViewLayoutAttributes(forCellWith: indexPath)
                itemAttributes.precalculated = itemSizeEstimate.precalculated
                itemAttributes.frame = CGRect(origin: section.originForNextItem, size: CGSize(width: itemWidth, height: itemSizeEstimate.height))
                section.addItem(itemAttributes)
            }
            let footerWidth = section.widthForSupplementaryViews
            let footerHeightEstimate = delegate.collectionView(collectionView, estimatedHeightForFooterInSection: sectionIndex, forColumnWidth: footerWidth)
            if !footerHeightEstimate.height.isEqual(to: 0) {
                let footerAttributes = ColumnarCollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, with: IndexPath(item: 0, section: sectionIndex))
                footerAttributes.precalculated = footerHeightEstimate.precalculated
                footerAttributes.frame = CGRect(origin: section.originForNextSupplementaryView, size: CGSize(width: width, height: footerHeightEstimate.height))
                section.addFooter(footerAttributes)
            }
            y += section.frame.size.height + metrics.interSectionSpacing
        }
        
        contentSize = CGSize(width: metrics.boundsSize.width, height: y)
    }
    
    func update(with metrics: ColumnarCollectionViewLayoutMetrics, invalidationContext context: ColumnarCollectionViewLayoutInvalidationContext, delegate: ColumnarCollectionViewLayoutDelegate, collectionView: UICollectionView) {
        guard let originalAttributes = context.originalLayoutAttributes as? ColumnarCollectionViewLayoutAttributes, let preferredAttributes = context.preferredLayoutAttributes as? ColumnarCollectionViewLayoutAttributes else {
            assert(false)
            return
        }
        
        let indexPath = originalAttributes.indexPath
        let sectionIndex = indexPath.section
        guard sectionIndex < sections.count else {
            assert(false)
            return
        }
        
        let section = sections[sectionIndex]
        
        let oldHeight = section.frame.height
        let result = section.invalidate(originalAttributes, with: preferredAttributes)
        let newHeight = section.frame.height
        let deltaY = newHeight - oldHeight
        guard !deltaY.isEqual(to: 0) else {
            return
        }
        var invalidatedHeaderIndexPaths: [IndexPath] = result.invalidatedHeaderIndexPaths
        var invalidatedItemIndexPaths: [IndexPath] = result.invalidatedItemIndexPaths
        var invalidatedFooterIndexPaths: [IndexPath] = result.invalidatedFooterIndexPaths
        let nextSectionIndex = sectionIndex + 1
        if nextSectionIndex < sections.count {
            for section in sections[nextSectionIndex..<sections.count] {
                let result = section.translate(deltaY: deltaY)
                invalidatedHeaderIndexPaths.append(contentsOf: result.invalidatedHeaderIndexPaths)
                invalidatedItemIndexPaths.append(contentsOf: result.invalidatedItemIndexPaths)
                invalidatedFooterIndexPaths.append(contentsOf: result.invalidatedFooterIndexPaths)
            }
        }
        if invalidatedHeaderIndexPaths.count > 0 {
            context.invalidateSupplementaryElements(ofKind: UICollectionElementKindSectionHeader, at: invalidatedHeaderIndexPaths)
        }
        if invalidatedItemIndexPaths.count > 0 {
            context.invalidateItems(at: invalidatedItemIndexPaths)
        }
        if invalidatedFooterIndexPaths.count > 0 {
            context.invalidateSupplementaryElements(ofKind: UICollectionElementKindSectionFooter, at: invalidatedFooterIndexPaths)
        }
    }
    
    func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.section < sections.count else {
            return nil
        }
        let section = sections[indexPath.section]
        guard indexPath.item < section.items.count else {
            return nil
        }
        return section.items[indexPath.item]
    }
    
    public func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.section < sections.count else {
            return nil
        }
        let section = sections[indexPath.section]
        switch elementKind {
        case UICollectionElementKindSectionHeader:
            guard indexPath.item < section.headers.count else {
                return nil
            }
            return section.headers[indexPath.item]
        case UICollectionElementKindSectionFooter:
            guard indexPath.item < section.footers.count else {
                return nil
            }
            return section.footers[indexPath.item]
        default:
            return nil
        }
    }
}

struct ColumnarCollectionViewLayoutSectionInvalidationResults {
    let invalidatedHeaderIndexPaths: [IndexPath]
    let invalidatedItemIndexPaths: [IndexPath]
    let invalidatedFooterIndexPaths: [IndexPath]
}

class ColumnarCollectionViewLayoutSection {
    private class ColumnarCollectionViewLayoutColumn {
        var frame: CGRect
        init(frame: CGRect) {
            self.frame = frame
        }
        
        func addItem(_ attributes: ColumnarCollectionViewLayoutAttributes) {
            frame.size.height += attributes.frame.height
        }
        
        var widthForNextItem: CGFloat {
            return frame.width
        }
        
        var originForNextItem: CGPoint {
            return CGPoint(x: frame.minX, y: frame.maxY)
        }
    }
    
    let sectionIndex: Int
    var frame: CGRect = .zero
    var headers: [ColumnarCollectionViewLayoutAttributes] = []
    var items: [ColumnarCollectionViewLayoutAttributes] = []
    var footers: [ColumnarCollectionViewLayoutAttributes] = []
    private let columns: [ColumnarCollectionViewLayoutColumn]
    
    init(sectionIndex: Int, frame: CGRect, countOfColumns: Int, columnSpacing: CGFloat) {
        let columnWidth: CGFloat = floor((frame.size.width - (columnSpacing * CGFloat(countOfColumns - 1))) / CGFloat(countOfColumns))
        var columns: [ColumnarCollectionViewLayoutColumn] = []
        var x: CGFloat = frame.origin.x
        for _ in 0..<countOfColumns {
            columns.append(ColumnarCollectionViewLayoutColumn(frame: CGRect(x: x, y: frame.origin.y, width: columnWidth, height: 0)))
            x += columnWidth + columnSpacing
        }
        self.columns = columns
        self.frame = frame
        self.sectionIndex = sectionIndex
    }
    
    private func columnForItem(at index: Int) -> ColumnarCollectionViewLayoutColumn {
        return columns[index % columns.count]
    }
    
    private var columnForNextItem: ColumnarCollectionViewLayoutColumn {
        return columnForItem(at: columns.count)
    }
    
    var widthForNextItem: CGFloat {
        return columnForNextItem.widthForNextItem
    }
    
    var widthForNextSupplementaryView: CGFloat {
        return frame.size.width
    }
    
    var originForNextSupplementaryView: CGPoint {
        return CGPoint(x: frame.minX, y: frame.minY)
    }
    
    var originForNextItem: CGPoint {
        return columnForNextItem.originForNextItem
    }
    
    var widthForSupplementaryViews: CGFloat {
        return frame.width
    }
    
    func addHeader(_ attributes: ColumnarCollectionViewLayoutAttributes) {
        headers.append(attributes)
        frame.size.height += attributes.frame.size.height
    }
    
    func addItem(_ attributes: ColumnarCollectionViewLayoutAttributes) {
        let column = columnForNextItem
        column.addItem(attributes)
        items.append(attributes)
        if column.frame.height > frame.height {
            frame.size.height = column.frame.height
        }
    }
    
    func addFooter(_ attributes: ColumnarCollectionViewLayoutAttributes) {
        footers.append(attributes)
        frame.size.height += attributes.frame.size.height
    }
    
    func updateAttributes(at index: Int, in array: [ColumnarCollectionViewLayoutAttributes], with attributes: ColumnarCollectionViewLayoutAttributes) -> CGFloat {
        guard index < array.count else {
            return 0
        }
        let oldAttributes = array[index]
        oldAttributes.frame = attributes.frame
        return attributes.frame.height - oldAttributes.frame.height
    }
    
    
    func translateAttributesBy(_ deltaY: CGFloat, at index: Int, in array: [ColumnarCollectionViewLayoutAttributes]) -> [IndexPath] {
        guard !deltaY.isEqual(to: 0), index < array.count else {
            return []
        }
        var invalidatedIndexPaths: [IndexPath] = []
        for (index, attributes) in array[index..<array.count].enumerated() {
            attributes.frame.origin.y += deltaY
            invalidatedIndexPaths.append(IndexPath(item: index, section: sectionIndex))
        }
        return invalidatedIndexPaths
    }
    
    
    func invalidate(_ originalAttributes: ColumnarCollectionViewLayoutAttributes, with attributes: ColumnarCollectionViewLayoutAttributes) -> ColumnarCollectionViewLayoutSectionInvalidationResults {
        let index = originalAttributes.indexPath.item
        switch originalAttributes.representedElementCategory {
        case UICollectionElementCategory.cell:
            var invalidatedItemIndexPaths: [IndexPath] = []
            let deltaY = updateAttributes(at: index, in: items, with: attributes)
            let column = columnForItem(at: index)
            column.frame.size.height += deltaY
            if column.frame.height > frame.height {
                frame.size.height = column.frame.height
            }
            var affectedIndex = index + columns.count // next item in the column
            while affectedIndex < items.count {
                items[affectedIndex].frame.origin.y += deltaY
                invalidatedItemIndexPaths.append(IndexPath(item: affectedIndex, section: sectionIndex))
                affectedIndex += columns.count
            }
            let invalidatedFooterIndexPaths = translateAttributesBy(deltaY, at: 0, in: footers)
            return ColumnarCollectionViewLayoutSectionInvalidationResults(invalidatedHeaderIndexPaths: [], invalidatedItemIndexPaths: invalidatedItemIndexPaths, invalidatedFooterIndexPaths: invalidatedFooterIndexPaths)
        case UICollectionElementCategory.decorationView:
            return ColumnarCollectionViewLayoutSectionInvalidationResults(invalidatedHeaderIndexPaths: [], invalidatedItemIndexPaths: [], invalidatedFooterIndexPaths: [])
        case UICollectionElementCategory.supplementaryView:
            switch originalAttributes.representedElementKind {
            case UICollectionElementKindSectionHeader:
                let deltaY = updateAttributes(at: index, in: headers, with: attributes)
                frame.size.height += deltaY
                let invalidatedHeaderIndexPaths = translateAttributesBy(deltaY, at: index + 1, in: items)
                let invalidatedItemIndexPaths = translateAttributesBy(deltaY, at: 0, in: items)
                let invalidatedFooterIndexPaths = translateAttributesBy(deltaY, at: 0, in: footers)
                return ColumnarCollectionViewLayoutSectionInvalidationResults(invalidatedHeaderIndexPaths: invalidatedHeaderIndexPaths, invalidatedItemIndexPaths: invalidatedItemIndexPaths, invalidatedFooterIndexPaths: invalidatedFooterIndexPaths)
            case UICollectionElementKindSectionFooter:
                let deltaY = updateAttributes(at: index, in: footers, with: attributes)
                frame.size.height += deltaY
                let invalidatedFooterIndexPaths = translateAttributesBy(deltaY, at: index + 1, in: footers)
                return ColumnarCollectionViewLayoutSectionInvalidationResults(invalidatedHeaderIndexPaths: [], invalidatedItemIndexPaths: [], invalidatedFooterIndexPaths: invalidatedFooterIndexPaths)
            default:
                return ColumnarCollectionViewLayoutSectionInvalidationResults(invalidatedHeaderIndexPaths: [], invalidatedItemIndexPaths: [], invalidatedFooterIndexPaths: [])
            }
        }
        
    }
    
    func translate(deltaY: CGFloat) -> ColumnarCollectionViewLayoutSectionInvalidationResults {
        let invalidatedHeaderIndexPaths = translateAttributesBy(deltaY, at: 0, in: headers)
        let invalidatedItemIndexPaths = translateAttributesBy(deltaY, at: 0, in: items)
        let invalidatedFooterIndexPaths = translateAttributesBy(deltaY, at: 0, in: footers)
        frame.origin.y += deltaY
        return ColumnarCollectionViewLayoutSectionInvalidationResults(invalidatedHeaderIndexPaths: invalidatedHeaderIndexPaths, invalidatedItemIndexPaths: invalidatedItemIndexPaths, invalidatedFooterIndexPaths: invalidatedFooterIndexPaths)
    }
}
