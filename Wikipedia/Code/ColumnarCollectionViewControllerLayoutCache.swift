class ColumnarCollectionViewControllerLayoutCache {
    private var cachedHeights: [String: CGFloat] = [:]
    
    private func cacheKeyForCellWithIdentifier(_ identifier: String, columnWidth: CGFloat, userInfo: String) -> String {
        return "\(identifier)-\(Int(round(columnWidth*100)))-\(userInfo)"
    }
    
    public func setHeight(_ height: CGFloat, forCellWithIdentifier identifier: String, columnWidth: CGFloat, userInfo: String) {
        let cacheKey = cacheKeyForCellWithIdentifier(identifier, columnWidth: columnWidth, userInfo: userInfo)
        cachedHeights[cacheKey] = height
    }
    
    public func cachedHeightForCellWithIdentifier(_ identifier: String, columnWidth: CGFloat, userInfo: String) -> CGFloat? {
        let cacheKey = cacheKeyForCellWithIdentifier(identifier, columnWidth: columnWidth, userInfo: userInfo)
        return cachedHeights[cacheKey]
    }

    public func reset() {
        cachedHeights.removeAll(keepingCapacity: true)
    }
}
