//  Created by Monte Hurd on 12/10/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

/**
 *  Get notified when a section image is loaded
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
