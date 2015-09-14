//
//  AnyPromise+WMFExtensions.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "Wikipedia-Swift.h"


@interface AnyPromise (WMFExtensions)

/**
 * Convenience which will recover a promise chain in case of any errors that aren't `cancelled`.
 *
 * Promises chained after this call will not have any arguments passed to their callback.  For example:
 *
 * @code
 *
 * [self somethingAsync]
 * .then(^ (id value) { ...} )
 * .wmf_ignoringErrors
 * .then(^ { return [self somethingElseAsync]; }); //< block given to then declared w/o arguments
 * .catch( ^ (NSError* somethingElseAsyncError) { ... } )
 *
 * @endcode
 *
 * Therefore, if `somethingAsync` fails, `somethingElseAsync` will still be triggered.  However, if `somethingAsync`
 * is cancelled, `somethingElseAsync` will never be triggered (since cancellation is not ignored).
 *
 * @see NSError.cancelled
 */
- (AnyPromise*)wmf_ignoringErrors;

@end
