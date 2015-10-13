//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <Foundation/Foundation.h>

#import <stdarg.h>

@protocol HCMatcher;


/*!
 * @brief Returns an array of values from a variable-length comma-separated list terminated by <code>nil</code>.
 */
FOUNDATION_EXPORT NSMutableArray *HCCollectItems(id item, va_list args);

/*!
 * @brief Returns an array of matchers from a variable-length comma-separated list terminated by <code>nil</code>.
 * @discussion Each item is wrapped in @ref HCWrapInMatcher to transform non-matcher items into equality matchers.
 */
FOUNDATION_EXPORT NSMutableArray *HCCollectMatchers(id item, va_list args);

/*!
 * @brief Returns an array of wrapped items from a variable-length comma-separated list terminated by <code>nil</code>.
 * @discussion Each item is transformed by passing it to the given <em>wrap</em> function.
 */
FOUNDATION_EXPORT NSMutableArray *HCCollectWrappedItems(id item, va_list args, id (*wrap)(id));
