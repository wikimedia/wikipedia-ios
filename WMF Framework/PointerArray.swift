public class PointerArray<T: AnyObject> {
    let semaphore = DispatchSemaphore(value: 1)
    let taskGroup = DispatchGroup()
    let pointers = NSPointerArray.weakObjects()
    
    public func append(_ object: T) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        let pointer = Unmanaged.passUnretained(object).toOpaque()
        pointers.addPointer(pointer)
    }
    
    public var allObjects: [T] {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        pointers.compact()
        return pointers.allObjects.compactMap { $0 as? T }
    }
}
