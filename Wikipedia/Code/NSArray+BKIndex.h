//
//  NSArray+BKIndex.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/12/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Extends BlocksKit with indexing functionality.
@interface NSArray (BKIndex)

/**
 * Create a dictionary comprised of the indexed contents of the receiver.
 * @param index A block which returns the indexing key for a given object.
 * @note This will also implicitly remove objects with the same key, as determined by @c index, with the last object
 *       with said key will be in the resulting dictionary.
 * @return A dictionary where keys are the values returned by @c index and the values are the corresponding objects.
 * @see -bk_reduce:withBlock:
 */
- (NSDictionary*)bk_index:(id<NSCopying>(^)(id))index;

/**
 * Index objects in the receiver using their values for @c keypath as the index.
 * @param keypath A keypath which is KVC-compliant for all objects in the receiver.
 * @see -bk_index:
 */
- (NSDictionary*)bk_indexWithKeypath:(NSString*)keypath;

@end

NS_ASSUME_NONNULL_END
