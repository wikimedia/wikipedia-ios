
private extension CGFloat {
    var roundedColumnWidth: Int {
        return Int(self*100)
    }
}
class ColumnarCollectionViewControllerLayoutCache {
    private var cachedHeights: [String: [Int: CGFloat]] = [:]
    
    private func cacheKeyForCellWithIdentifier(_ identifier: String, userInfo: String) -> String {
        return "\(identifier)-\(userInfo)"
    }
    
    public func setHeight(_ height: CGFloat, forCellWithIdentifier identifier: String, columnWidth: CGFloat, userInfo: String) {
        let cacheKey = cacheKeyForCellWithIdentifier(identifier, userInfo: userInfo)
        cachedHeights[cacheKey, default: [:]][columnWidth.roundedColumnWidth] = height
    }
    
    public func cachedHeightForCellWithIdentifier(_ identifier: String, columnWidth: CGFloat, userInfo: String) -> CGFloat? {
        let cacheKey = cacheKeyForCellWithIdentifier(identifier, userInfo: userInfo)
        return cachedHeights[cacheKey]?[columnWidth.roundedColumnWidth]
    }
    
    public func removeCachedHeightsForCellWithIdentifier(_ identifier: String, userInfo: String) {
        let cacheKey = cacheKeyForCellWithIdentifier(identifier, userInfo: userInfo)
        cachedHeights.removeValue(forKey: cacheKey)
    }

    public func reset() {
        cachedHeights.removeAll(keepingCapacity: true)
    }
}
