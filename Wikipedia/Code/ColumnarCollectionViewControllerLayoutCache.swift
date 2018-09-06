
private extension CGFloat {
    var roundedColumnWidth: Int {
        return Int(self*100)
    }
}
class ColumnarCollectionViewControllerLayoutCache {
    private var cachedHeights: [String: [Int: CGFloat]] = [:]
    private var cacheKeysByGroupKey: [String: Set<String>] = [:]
    private var cacheKeysByArticleKey: [String: Set<String>] = [:]
    private var groupKeysByArticleKey: [String: Set<String>] = [:]
    
    private func cacheKeyForCellWithIdentifier(_ identifier: String, userInfo: String) -> String {
        return "\(identifier)-\(userInfo)"
    }
    
    public func setHeight(_ height: CGFloat, forCellWithIdentifier identifier: String, columnWidth: CGFloat, groupKey: String? = nil, articleKey: String? = nil, userInfo: String) {
        let cacheKey = cacheKeyForCellWithIdentifier(identifier, userInfo: userInfo)
        if let groupKey = groupKey {
            cacheKeysByGroupKey[groupKey, default: []].insert(cacheKey)
        }
        if let articleKey = articleKey {
            cacheKeysByArticleKey[articleKey, default: []].insert(cacheKey)
            if let groupKey = groupKey {
                groupKeysByArticleKey[articleKey, default: []].insert(groupKey)
            }
        }
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
        cacheKeysByArticleKey.removeAll(keepingCapacity: true)
        cacheKeysByGroupKey.removeAll(keepingCapacity: true)
    }
    
    public func invalidateArticleKey(_ articleKey: String?) {
        guard let articleKey = articleKey else {
            return
        }
        if let cacheKeys = cacheKeysByArticleKey[articleKey] {
            for cacheKey in cacheKeys {
                cachedHeights.removeValue(forKey: cacheKey)
            }
            cacheKeysByArticleKey.removeValue(forKey: articleKey)
        }
        if let groupKeys = groupKeysByArticleKey[articleKey] {
            for groupKey in groupKeys {
                invalidateGroupKey(groupKey)
            }
        }
    }
    
    public func invalidateGroupKey(_ groupKey: String?) {
        guard let groupKey = groupKey, let cacheKeys = cacheKeysByGroupKey[groupKey] else {
            return
        }
        for cacheKey in cacheKeys {
            cachedHeights.removeValue(forKey: cacheKey)
        }
        cacheKeysByGroupKey.removeValue(forKey: groupKey)
    }
}
