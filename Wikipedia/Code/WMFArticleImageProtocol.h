//  Created by Monte Hurd on 4/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

/**
 *  This protocol routes images for a given article to/from the article's data store
 *  record.
 */

/**
 * Posted when a section image is cached.
 * @warning This notification is posted on a background thread, dispatch to the
 *          main thread in the notification callback if the observer is a UI object.
 */
extern NSString* const WMFArticleImageSectionImageRetrievedNotification;

@interface WMFArticleImageProtocol : NSURLProtocol

@end
