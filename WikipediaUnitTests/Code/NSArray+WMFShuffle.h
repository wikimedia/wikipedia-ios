//
//  NSArray+WMFShuffle.h
//  Wikipedia
//
//  Created by Brian Gerstle on 3/30/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (WMFShuffle)

/// @return A shuffled copy of the receiver.
- (instancetype)wmf_shuffledCopy;

@end

@interface NSMutableArray (WMFShuffle)

/// Shuffles the receiver in place, then returns it.
- (instancetype)wmf_shuffle;

@end
