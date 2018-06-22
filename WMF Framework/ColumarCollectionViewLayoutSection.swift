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
    
    init(sectionIndex: Int, frame: CGRect, metrics: ColumnarCollectionViewLayoutMetrics) {
        let countOfColumns = metrics.countOfColumns
        let columnSpacing = metrics.interColumnSpacing
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
        self.metrics = metrics
    }
    
    private func columnForItem(at index: Int) -> ColumnarCollectionViewLayoutColumn {
        return columns[index % columns.count]
    }
    
    private var columnForNextItem: ColumnarCollectionViewLayoutColumn {
        return columnForItem(at: items.count)
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
        if metrics.interItemSpacing > 0 && items.count >= columns.count {
            column.addSpace(metrics.interItemSpacing)
        }
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
