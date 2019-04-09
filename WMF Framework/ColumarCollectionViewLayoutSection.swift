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
        
        func addSpace(_ space: CGFloat) {
            frame.size.height += space
        }
    }
    
    let sectionIndex: Int
    var frame: CGRect = .zero
    let metrics: ColumnarCollectionViewLayoutMetrics
    var headers: [ColumnarCollectionViewLayoutAttributes] = []
    var items: [ColumnarCollectionViewLayoutAttributes] = []
    var footers: [ColumnarCollectionViewLayoutAttributes] = []
    private let columns: [ColumnarCollectionViewLayoutColumn]
    private var columnIndexByItemIndex: [Int: Int] = [:]
    private var shortestColumnIndex: Int = 0
    
    init(sectionIndex: Int, frame: CGRect, metrics: ColumnarCollectionViewLayoutMetrics, countOfItems: Int) {
        let countOfColumns = metrics.countOfColumns
        let columnSpacing = metrics.interColumnSpacing
        let columnWidth: CGFloat = floor((frame.size.width - (columnSpacing * CGFloat(countOfColumns - 1))) / CGFloat(countOfColumns))
        var columns: [ColumnarCollectionViewLayoutColumn] = []
        columns.reserveCapacity(countOfColumns)
        var x: CGFloat = frame.origin.x
        for _ in 0..<countOfColumns {
            columns.append(ColumnarCollectionViewLayoutColumn(frame: CGRect(x: x, y: frame.origin.y, width: columnWidth, height: 0)))
            x += columnWidth + columnSpacing
        }
        self.columns = columns
        self.frame = frame
        self.sectionIndex = sectionIndex
        self.metrics = metrics
        items.reserveCapacity(countOfItems)
    }
    
    private func columnForItem(at itemIndex: Int) -> ColumnarCollectionViewLayoutColumn? {
        guard let columnIndex = columnIndexByItemIndex[itemIndex] else {
            return nil
        }
        return columns[columnIndex]
    }
    
    private var columnForNextItem: ColumnarCollectionViewLayoutColumn {
        let itemIndex = items.count
        let columnIndex = shortestColumnIndex
        columnIndexByItemIndex[itemIndex] = columnIndex
        return columns[columnIndex]
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
        for column in columns {
            column.addSpace(attributes.frame.size.height)
        }
    }
    
    func addItem(_ attributes: ColumnarCollectionViewLayoutAttributes) {
        let column = columnForNextItem
        if metrics.interItemSpacing > 0 {
            column.addSpace(metrics.interItemSpacing)
        }
        column.addItem(attributes)
        items.append(attributes)
        if column.frame.height > frame.height {
            frame.size.height = column.frame.height
        }
        updateShortestColumnIndex()
    }
    
    func updateShortestColumnIndex() {
        guard columns.count > 1 else {
            return
        }
        var minHeight: CGFloat = CGFloat.greatestFiniteMagnitude
        for (index, column) in columns.enumerated() {
            guard column.frame.height < minHeight else {
                continue
            }
            minHeight = column.frame.height
            shortestColumnIndex = index
        }
    }
    
    func addFooter(_ attributes: ColumnarCollectionViewLayoutAttributes) {
        footers.append(attributes)
        frame.size.height += attributes.frame.size.height
    }
    
    func updateAttributes(at index: Int, in array: [ColumnarCollectionViewLayoutAttributes], with attributes: ColumnarCollectionViewLayoutAttributes) -> CGFloat {
        guard array.indices.contains(index) else {
            return 0
        }
        let oldAttributes = array[index]
        let newFrame = CGRect(origin: oldAttributes.frame.origin, size: attributes.frame.size)
        let deltaY = newFrame.height - oldAttributes.frame.height
        guard !deltaY.isEqual(to: 0) else {
            return 0
        }
        oldAttributes.frame = newFrame
        return deltaY
    }
    
    
    func translateAttributesBy(_ deltaY: CGFloat, at index: Int, in array: [ColumnarCollectionViewLayoutAttributes]) -> [IndexPath] {
        guard !deltaY.isEqual(to: 0), array.indices.contains(index) else {
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
        
        case UICollectionView.ElementCategory.decorationView:
            return ColumnarCollectionViewLayoutSectionInvalidationResults.empty
        case UICollectionView.ElementCategory.supplementaryView:
            switch originalAttributes.representedElementKind {
            case UICollectionView.elementKindSectionHeader:
                let deltaY = updateAttributes(at: index, in: headers, with: attributes)
                frame.size.height += deltaY
                var invalidatedHeaderIndexPaths = translateAttributesBy(deltaY, at: index + 1, in: headers)
                invalidatedHeaderIndexPaths.append(originalAttributes.indexPath)
                let invalidatedItemIndexPaths = translateAttributesBy(deltaY, at: 0, in: items)
                let invalidatedFooterIndexPaths = translateAttributesBy(deltaY, at: 0, in: footers)
                return ColumnarCollectionViewLayoutSectionInvalidationResults(invalidatedHeaderIndexPaths: invalidatedHeaderIndexPaths, invalidatedItemIndexPaths: invalidatedItemIndexPaths, invalidatedFooterIndexPaths: invalidatedFooterIndexPaths)
            case UICollectionView.elementKindSectionFooter:
                let deltaY = updateAttributes(at: index, in: footers, with: attributes)
                frame.size.height += deltaY
                var invalidatedFooterIndexPaths = translateAttributesBy(deltaY, at: index + 1, in: footers)
                invalidatedFooterIndexPaths.append(originalAttributes.indexPath)
                return ColumnarCollectionViewLayoutSectionInvalidationResults(invalidatedHeaderIndexPaths: [], invalidatedItemIndexPaths: [], invalidatedFooterIndexPaths: invalidatedFooterIndexPaths)
            default:
                return ColumnarCollectionViewLayoutSectionInvalidationResults.empty
            }
        default:
            var invalidatedItemIndexPaths: [IndexPath] = [originalAttributes.indexPath]
            let deltaY = updateAttributes(at: index, in: items, with: attributes)
            guard
                let columnIndex = columnIndexByItemIndex[index]
                else {
                    return ColumnarCollectionViewLayoutSectionInvalidationResults.empty
            }
            
            let column = columns[columnIndex]
            
            column.frame.size.height += deltaY
            if column.frame.height > frame.height {
                frame.size.height = column.frame.height
            }
            
            let nextIndex = index + 1
            if items.indices.contains(nextIndex) {
                for affectedIndex in nextIndex..<items.count {
                    guard columnIndexByItemIndex[affectedIndex] == columnIndex else {
                        continue
                    }
                    items[affectedIndex].frame.origin.y += deltaY
                    invalidatedItemIndexPaths.append(IndexPath(item: affectedIndex, section: sectionIndex))
                }
            }
            
            updateShortestColumnIndex()
            let invalidatedFooterIndexPaths = translateAttributesBy(deltaY, at: 0, in: footers)
            return ColumnarCollectionViewLayoutSectionInvalidationResults(invalidatedHeaderIndexPaths: [], invalidatedItemIndexPaths: invalidatedItemIndexPaths, invalidatedFooterIndexPaths: invalidatedFooterIndexPaths)
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
