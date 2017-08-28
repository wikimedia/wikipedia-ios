import Foundation

extension NSArray {
    /// @return The object at `index` if it's within range of the receiver, otherwise `nil`.
    @objc public func wmf_safeObjectAtIndex(_ index: Int) -> Any? {
        guard index > -1 && index < self.count else {
            return nil
        }
        
        return self[index]
    }

    /**
     *  Used to find arrays that contain Nulls
     
     - returns: true if any objects are [NSNull null], otherwise false
     */
    @objc public func wmf_containsNullObjects() -> Bool {
        var foundNull = false
        for (_, value) in self.enumerated() {
            if value is NSNull {
                foundNull = true
            }
        }
        return foundNull
    }

    /**
     Used to find arrays that contain Nulls or contain sub-dictionaries or arrays that contain Nulls
     
     - returns: true if any objects or sub-collection objects are [NSNull null], otherwise false
     */
    @objc public func wmf_recursivelyContainsNullObjects() -> Bool {
        if self.wmf_containsNullObjects(){
            return true
        }

        var foundNull = false
        for (_, value) in self.enumerated() {
            if let value = value as? NSDictionary {
                foundNull = value.wmf_recursivelyContainsNullObjects()
            }
            if let value = value as? NSArray {
                foundNull = value.wmf_recursivelyContainsNullObjects()
            }
        }
        return foundNull
    }
    /**
    Select the first `n` elements from an array.
    
    - parameter intLength: The max length
    
    - returns: A new array with the first `n` items in the receiver, or the receiver if `n` exceeds the number of items 
              in the array.
    */
    @objc public func wmf_arrayByTrimmingToLength(_ intLength: Int) -> NSArray {
        if (self.count == 0 || self.count < intLength) {
            return self;
        }
        return self.wmf_safeSubarrayWithRange(NSMakeRange(0, intLength));
    }

    /**
    Select the last `n` elements from an array
    
    :param: length The max length
    
    :returns: A new array with the last `n` items in the receiver, or the receiver if `n` exceeds the number of items
    in the array.
    */
    @objc public func wmf_arrayByTrimmingToLengthFromEnd(_ intLength: Int) -> NSArray {
        if (self.count == 0 || self.count < intLength || intLength < 0) {
            return self;
        }
        return self.wmf_safeSubarrayWithRange(NSMakeRange(self.count-intLength, intLength));
    }

    /**
    Get all elements in an array except the first.

    - returns: All but the first element of the receiver, or an empty array if there was only one element.
    */
    @objc public func wmf_arrayByRemovingFirstElement() -> NSArray {
        return wmf_safeSubarrayWithRange(NSMakeRange(1, self.count - 1))
    }

    /**
    Returns a subarray from the receiver, limited to its bounds.

    - parameter range: The range of the desired items.

    - returns: A subarray with the desired items, constrained by the number of items in the receiver.
    */
    @objc public func wmf_safeSubarrayWithRange(_ range: NSRange) -> NSArray {
        if range.location > self.count - 1 || WMFRangeIsNotFoundOrEmpty(range) {
            return NSArray()
        }
        let safeLength: Int = {
            if WMFRangeGetMaxIndex(range) <= UInt(self.count) {
                return range.length
            } else {
                let countMinusLocation = self.count - range.location
                guard countMinusLocation > 0 else {
                    return 0
                }
                return countMinusLocation
            }
        }()
        if safeLength == 0 {
            return NSArray()
        }
        let safeRange = NSMakeRange(range.location, safeLength)
        return self.subarray(with: safeRange) as NSArray
    }

    /// - returns: A reversed copy of the receiver.
    @objc public func wmf_reverseArray() -> AnyObject {
        return self.reverseObjectEnumerator().allObjects as AnyObject;
    }
    
    /**
    Return an new array by interleaving the receiver with otherArray.
    The first element in the receiver is always first.
    
    :param: otherArray The array whose lements to interleave
    
    :returns: The interleaved array
    */
    @objc public func wmf_arrayByInterleavingElementsFromArray(_ otherArray: NSArray) -> NSArray {
        
        let newArray = self.mutableCopy() as! NSMutableArray;
        
        otherArray.enumerateObjects({ (object, index, stop) -> Void in
            
            /* 
             When adding items in an array from the begining, 
             you need to adjust the index of each subssequent item to account for the previous added items.
             Multipling the index by 2 does this.
             */
            var newIndex = 2*index + 1;
            newIndex = newIndex > newArray.count ? newArray.count : newIndex;
            newArray.insert(object, at: newIndex);
        })
        
        return newArray;
    }

    @objc public func wmf_hasDuplicateElements() -> Bool {
        return NSSet(array: self as [AnyObject]).count != count;
    }
}
