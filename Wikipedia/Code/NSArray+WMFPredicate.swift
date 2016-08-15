import Foundation

// Fast retrieval of first object in array matching predicate.

extension NSArray {
    func wmf_firstMatchForPredicate(predicate: NSPredicate) -> AnyObject? {
        let i = self.indexOfObjectPassingTest{ (obj, idx, stop) -> Bool in
            if(predicate.evaluateWithObject(obj)){
                stop.initialize(true)
                return true
            }else{
                return false
            }
        }
        return i == NSNotFound ? nil : self.objectAtIndex(i)
    }
}