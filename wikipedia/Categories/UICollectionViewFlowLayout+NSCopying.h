//
//  UICollectionViewFlowLayout+NSCopying.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UICollectionViewFlowLayout (NSCopying)
<NSCopying>

/**
 * Returns a copy of the receiver.
 * @note Certain properties aren't copyable, including registered nibs or classes for reuse identifiers. Also, the
 *       receiver's @c collectionView isn't copied, since it is only set after being set into a collection view.
 */
- (instancetype)copyWithZone:(NSZone*)zone;

@end
