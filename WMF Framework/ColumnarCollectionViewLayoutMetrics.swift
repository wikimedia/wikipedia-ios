public struct ColumnarCollectionViewLayoutMetrics {
    let boundsSize: CGSize
    let layoutMargins: UIEdgeInsets
    let countOfColumns: Int
    let itemLayoutMargins: UIEdgeInsets
    let readableWidth: CGFloat
    let interSectionSpacing: CGFloat
    let interColumnSpacing: CGFloat
    let interItemSpacing: CGFloat
    var shouldMatchColumnHeights = false
    
    public static func metrics(with boundsSize: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        
        let useTwoColumns = boundsSize.width >= 600 || (boundsSize.width > boundsSize.height && readableWidth >= 500)
        let countOfColumns = useTwoColumns ? 2 : 1
        let interColumnSpacing: CGFloat = useTwoColumns ? 20 : 0
        let interItemSpacing: CGFloat = 20
        let interSectionSpacing: CGFloat = useTwoColumns ? 20 : 0
        
        let layoutMarginsForMetrics: UIEdgeInsets
        if useTwoColumns {
            let marginWidth = max(max(layoutMargins.left, layoutMargins.right), round(0.5 * (boundsSize.width - (readableWidth * CGFloat(countOfColumns)))))
            layoutMarginsForMetrics = UIEdgeInsetsMake(20, marginWidth, 20, marginWidth)
        } else {
            let marginWidth = max(layoutMargins.left, layoutMargins.right)
            layoutMarginsForMetrics = UIEdgeInsetsMake(0, marginWidth, 0, marginWidth)
        }
        
        let itemLayoutMargins = UIEdgeInsetsMake(15, 13, 15, 13);
        return ColumnarCollectionViewLayoutMetrics(boundsSize: boundsSize, layoutMargins: layoutMarginsForMetrics, countOfColumns: countOfColumns, itemLayoutMargins: itemLayoutMargins, readableWidth: readableWidth, interSectionSpacing: interSectionSpacing, interColumnSpacing: interColumnSpacing, interItemSpacing: interItemSpacing, shouldMatchColumnHeights: false)
    }
    
    
    public static func singleColumnMetrics(with boundsSize: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return  ColumnarCollectionViewLayoutMetrics.singleColumnMetrics(with: boundsSize, readableWidth: readableWidth, layoutMargins: layoutMargins, interItemSpacing: 0, interSectionSpacing: 0)
    }
    
    public static func singleColumnMetrics(with boundsSize: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets, interItemSpacing: CGFloat, interSectionSpacing: CGFloat) -> ColumnarCollectionViewLayoutMetrics {
        let marginWidth = max(max(layoutMargins.left, layoutMargins.right), round(0.5 * (boundsSize.width - readableWidth)))
        let itemLayoutMargins = UIEdgeInsetsMake(10, marginWidth, 10, marginWidth)
        let layoutMarginsForMetrics = UIEdgeInsetsMake(0, marginWidth, 0, marginWidth)
        return ColumnarCollectionViewLayoutMetrics(boundsSize: boundsSize, layoutMargins: layoutMarginsForMetrics, countOfColumns: 1, itemLayoutMargins: itemLayoutMargins, readableWidth: readableWidth, interSectionSpacing: interSectionSpacing, interColumnSpacing: 0,  interItemSpacing: interItemSpacing, shouldMatchColumnHeights: false)
    }
}
