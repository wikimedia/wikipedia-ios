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

public protocol ColumnarCollectionViewLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForFooterInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate
    func metrics(withBoundsSize size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics
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
            y += section.frame.size.height + metrics.interSectionSpacing
        }
        
        contentSize = CGSize(width: metrics.boundsSize.width, height: y)
    }
    
    func reset() {
        sections.removeAll(keepingCapacity: true)
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
        return sections[indexPath.section].items[indexPath.item]
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
    
    var originForNextItem: CGPoint {
        return columnForNextItem.originForNextItem
    }
    
    var widthForSupplementaryViews: CGFloat {
        return frame.width
    }
    
    func addItem(_ attributes: ColumnarCollectionViewLayoutAttributes) {
        let column = columnForNextItem
        column.addItem(attributes)
        items.append(attributes)
        if column.frame.height > frame.height {
            frame.size.height = column.frame.height
        }
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


public class ColumnarCollectionViewLayout: UICollectionViewLayout {
    var info: ColumnarCollectionViewLayoutInfo?
    var metrics: ColumnarCollectionViewLayoutMetrics?
    var isLayoutValid: Bool = false
    let defaultColumnWidth: CGFloat = 315
    let maxColumnWidth: CGFloat = 740
    public var slideInNewContentFromTheTop: Bool = false
    
    override public class var layoutAttributesClass: Swift.AnyClass {
        return ColumnarCollectionViewLayoutAttributes.self
    }
    
    override public class var invalidationContextClass: Swift.AnyClass {
        return ColumnarCollectionViewLayoutInvalidationContext.self
    }
    
    private var delegate: ColumnarCollectionViewLayoutDelegate {
        return collectionView!.delegate as! ColumnarCollectionViewLayoutDelegate
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
            for item in section.items {
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
        guard let collectionView = collectionView, width >= 1 else {
            return 0
        }
        let info = ColumnarCollectionViewLayoutInfo()
        let metrics = delegate.metrics(withBoundsSize: CGSize(width: width, height: 100), readableWidth: width, layoutMargins: .zero)
        info.layout(with: metrics, delegate: delegate, collectionView: collectionView, invalidationContext: nil)
        return info.contentSize.height
    }

    override public func prepare() {
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
        
        if let metrics = metrics, !metrics.readableWidth.isEqual(to: readableWidth) {
            isLayoutValid = false
        }
        
        let size = collectionView.bounds.size
        
        guard !isLayoutValid, size.width > 0, size.height > 0 else {
            return
        }

        let delegateMetrics = delegate.metrics(withBoundsSize: size, readableWidth: readableWidth, layoutMargins: collectionView.scrollIndicatorInsets)
        let newInfo = ColumnarCollectionViewLayoutInfo()
        newInfo.layout(with: delegateMetrics, delegate: delegate, collectionView: collectionView, invalidationContext: nil)
        metrics = delegateMetrics
        info = newInfo
        isLayoutValid = true
    }
    
    // MARK - Invalidation
    
    override public func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        defer {
            super.invalidateLayout(with: context)
        }
        
        guard let context = context as? ColumnarCollectionViewLayoutInvalidationContext else {
            return
        }
        
        guard context.boundsDidChange || context.invalidateEverything || context.invalidateDataSourceCounts else {
            return
        }
        
        isLayoutValid = false
    }
    
    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let metrics = metrics else {
            return true
        }
        return newBounds.size.width != metrics.boundsSize.width
    }
    
    override public func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let superContext = super.invalidationContext(forBoundsChange: newBounds)
        let context = superContext as? ColumnarCollectionViewLayoutInvalidationContext ?? ColumnarCollectionViewLayoutInvalidationContext()
        context.boundsDidChange = true
        return context
    }
    
    override public func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        return preferredAttributes.frame != originalAttributes.frame
    }
    
    override public func invalidationContext(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
        let superContext = super.invalidationContext(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
        let context = superContext as? ColumnarCollectionViewLayoutInvalidationContext ?? ColumnarCollectionViewLayoutInvalidationContext()
        context.preferredLayoutAttributes = preferredAttributes
        context.originalLayoutAttributes = originalAttributes
        if let metrics = metrics, let info = info, let collectionView = collectionView {
            info.update(with: metrics, invalidationContext: context, delegate: delegate, collectionView: collectionView)
        }
        return context
    }
    
    // MARK - Animation
    
    override public func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
    }
}
