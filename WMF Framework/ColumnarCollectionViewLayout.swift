import UIKit

public protocol ColumnarCollectionViewLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForFooterInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate
    func metrics(withBoundsSize size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics
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
