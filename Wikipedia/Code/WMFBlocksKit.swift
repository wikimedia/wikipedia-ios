import Foundation

extension NSArray {
    @objc public func wmf_map(_ transform: @escaping (Any) -> Any?) -> NSArray {
        return map(transform) as NSArray
    }
    
    @objc public func wmf_select(_ transform: @escaping (Any) -> Bool) -> NSArray {
        return filter(transform) as NSArray
    }
    
    @objc public func wmf_reject(_ transform: @escaping (Any) -> Bool) -> NSArray {
        return filter({ (obj) -> Bool in
            return !transform(obj)
        }) as NSArray
    }
    
    @objc public func wmf_match(_ matcher: @escaping (Any) -> Bool) -> Any? {
        for obj in self {
            guard !matcher(obj) else {
                return obj
            }
        }
        return nil
    }
}

extension NSSet {
    @objc public func wmf_map(_ transform: @escaping (Any) -> Any?) -> NSSet {
        let array = map { (obj) -> Any in
            return transform(obj) ?? NSNull()
        }
        return NSSet(array: array)
    }
    
    @objc public func wmf_select(_ transform: @escaping (Any) -> Bool) -> NSSet {
        let array = filter(transform)
        return NSSet(array: array)
    }
    
    @objc public func wmf_reject(_ transform: @escaping (Any) -> Bool) -> NSSet {
        let array = filter({ (obj) -> Bool in
            return !transform(obj)
        })
        return NSSet(array: array)
    }
    
    @objc public func wmf_match(_ matcher: @escaping (Any) -> Bool) -> Any? {
        for obj in self {
            guard !matcher(obj) else {
                return obj
            }
        }
        return nil
    }
}

extension NSDictionary {
    @objc public func wmf_map(_ transform: @escaping (Any, Any) -> Any?) -> NSDictionary {
        guard count > 0 else {
            return self
        }
        let result = NSMutableDictionary(capacity: count)
        for (key, value) in self {
            result[key] = transform(key, value)
        }
        return result
    }
    
    @objc public func wmf_select(_ transform: @escaping (Any, Any) -> Bool) -> NSDictionary {
        guard count > 0 else {
            return self
        }
        let result = NSMutableDictionary(capacity: count)
        for (key, value) in self {
            guard transform(key, value) else {
                continue
            }
            result[key] = value
        }
        return result
    }
    
    @objc public func wmf_reject(_ transform: @escaping (Any, Any) -> Bool) -> NSDictionary {
        return wmf_select({ (key, value) -> Bool in
            return !transform(key, value)
        })
    }
    
    @objc public func wmf_match(_ matcher: @escaping (Any, Any) -> Bool) -> Any? {
        for (key, value) in self {
            guard !matcher(key, value) else {
                return value
            }
        }
        return nil
    }
}
