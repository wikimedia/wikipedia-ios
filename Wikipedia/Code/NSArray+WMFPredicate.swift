//  Created by Monte Hurd on 8/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

import Foundation

// Fast retrieval of first object in array matching predicate.

extension NSArray {
    func wmf_firstMatchForPredicate(_ predicate: NSPredicate) -> AnyObject? {
        let i = self.indexOfObject{ (obj, idx, stop) -> Bool in
            if(predicate.evaluate(with: obj)){
                stop.initialize(to: true)
                return true
            }else{
                return false
            }
        }
        return i == NSNotFound ? nil : self.object(at: i)
    }
}
