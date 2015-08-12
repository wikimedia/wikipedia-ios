//  Created by Monte Hurd on 8/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

import Foundation

extension NSArray {
    /// @return The object at `index` if it's within range of the receiver, otherwise `nil`.
    func wmf_safeObjectAtIndex(index: UInt) -> AnyObject? {
        let intIndex = Int(index);
        return (intIndex < self.count) ? self[intIndex] : nil;
    }

    /**
    *  Safely trim an array to a specified length.
    *  Will not throw an exception if
    *
    *  @param length The max length
    *
    *  @return The trimmed array
    */
    func wmf_arrayByTrimmingToLength(length: UInt) -> AnyObject {
        let intLength = Int(length);
        if (self.count == 0 || self.count < intLength) {
            return self;
        }
        return self.subarrayWithRange(NSMakeRange(0, intLength));
    }

    /// @return A reversed copy of the receiver.
    func wmf_reverseArray() -> AnyObject {
        return self.reverseObjectEnumerator().allObjects;
    }
}
