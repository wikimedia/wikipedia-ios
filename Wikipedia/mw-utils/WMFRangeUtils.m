//
//  WMFRangeUtils.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFRangeUtils.h"

inline BOOL WMFRangeIsNotFoundOrEmpty(NSRange const range) {
    return range.location == NSNotFound || range.length == 0;
}

inline NSRange WMFRangeMakeNotFound() {
    return NSMakeRange(NSNotFound, 0);
}

inline NSUInteger WMFRangeGetMaxIndex(NSRange const range) {
    return range.location != NSNotFound ?
           range.location + range.length
           : NSNotFound;
}