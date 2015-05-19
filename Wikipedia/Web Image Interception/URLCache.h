//  Created by Monte Hurd on 12/10/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

/**
 * Posted when a section image is cached.
 * @warning This notification is posted on a background thread, dispatch to the
 *          main thread in the notification callback if the observer is a UI object.
 */
extern NSString* const WMFURLCacheSectionImageRetrievedNotification;

/**
 *  Keys passed in the WMFURLCacheSectionImageRetrievedNotification
 */
extern NSString* const kURLCacheKeyFileName;
extern NSString* const kURLCacheKeyData;
extern NSString* const kURLCacheKeyWidth;
extern NSString* const kURLCacheKeyHeight;
extern NSString* const kURLCacheKeyURL;
extern NSString* const kURLCacheKeyFileNameNoSizePrefix;
extern NSString* const kURLCacheKeyIsLeadImage;
extern NSString* const kURLCacheKeyPrimaryFocalUnitRectString;

@interface URLCache : NSURLCache

@end
