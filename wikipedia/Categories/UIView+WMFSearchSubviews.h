//  Created by Monte Hurd on 4/2/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UIView (WMFSearchSubviews)

/**
 * Returns the first object in the receiver's @c subviews array that is an instance or subclass of @c aClass.
 * @return A matching subview or @c nil if none are found.
 */
- (id)wmf_firstSubviewOfClass:(Class)aClass;

/**
 * Get a filtered view of the receiver's @c subviews array which only objects that are instances or subclasses of
 * @c aClass.
 * @return A possibly empty array of matching subviews.
 */
- (NSArray*)wmf_subviewsOfClass:(Class)aClass;

@end
