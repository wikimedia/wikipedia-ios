//  Created by Monte Hurd on 12/10/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFURLCache.h"
#import "SessionSingleton.h"

NSString* const WMFURLCacheZeroStateChanged     = @"ZeroStateChanged";
static NSString* const WMFURLCacheWikipediaHost = @".m.wikipedia.org";
static NSString* const WMFURLCacheJsonMIMEType  = @"application/json";
static NSString* const WMFURLCache00000         = @"000-00";
static NSString* const WMFURLCacheState         = @"state";
static NSString* const WMFURLCacheXCS           = @"X-CS";

@implementation WMFURLCache

- (void)storeCachedResponse:(NSCachedURLResponse*)cachedResponse forRequest:(NSURLRequest*)request {
    [super storeCachedResponse:cachedResponse forRequest:request];

    if ([self isJsonResponse:cachedResponse fromMDotRequest:request]) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            //NSLog(@"Processing zero headers for cached repsonse from %@", request);
//TODO: should refactor a lot of this into ZeroConfigState itself and make it thread safe so we can do its work off the main thread.
            [self processZeroHeaders:cachedResponse.response];
        });
    }
}

- (BOOL)isJsonResponse:(NSCachedURLResponse*)cachedResponse fromMDotRequest:(NSURLRequest*)request  {
    return ([[request URL].host hasSuffix:WMFURLCacheWikipediaHost] && [cachedResponse.response.MIMEType isEqualToString:WMFURLCacheJsonMIMEType]);
}

- (void)processZeroHeaders:(NSURLResponse*)response {
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    NSHTTPURLResponse* httpUrlResponse       = (NSHTTPURLResponse*)response;
    NSDictionary* headers                    = httpUrlResponse.allHeaderFields;
    NSString* xZeroRatedHeader               = [headers objectForKey:WMFURLCacheXCS];
    BOOL zeroRatedHeaderPresent              = xZeroRatedHeader != nil;
    NSString* xcs                            = [SessionSingleton sharedInstance].zeroConfigState.partnerXcs;
    BOOL zeroProviderChanged                 = zeroRatedHeaderPresent && ![xZeroRatedHeader isEqualToString:xcs];
    BOOL zeroDisposition                     = [SessionSingleton sharedInstance].zeroConfigState.disposition;

    // For testing Wikipedia Zero visual flourishes.
    // Go to WebViewController.m and uncomment the W0 part,
    // then when running the app in the simulator fire the
    // memory warning to toggle the fake state on or off.
    if ([SessionSingleton sharedInstance].zeroConfigState.fakeZeroOn) {
        zeroRatedHeaderPresent = YES;
        xZeroRatedHeader       = WMFURLCache00000;
    }

    if (zeroRatedHeaderPresent && (!zeroDisposition || zeroProviderChanged)) {
        [SessionSingleton sharedInstance].zeroConfigState.disposition = YES;
        [SessionSingleton sharedInstance].zeroConfigState.partnerXcs  = xZeroRatedHeader;
        [notificationCenter postNotificationName:WMFURLCacheZeroStateChanged object:self userInfo:@{WMFURLCacheState: @YES}];
    } else if (!zeroRatedHeaderPresent && zeroDisposition) {
        [SessionSingleton sharedInstance].zeroConfigState.disposition = NO;
        [SessionSingleton sharedInstance].zeroConfigState.partnerXcs  = nil;
        [notificationCenter postNotificationName:WMFURLCacheZeroStateChanged object:self userInfo:@{WMFURLCacheState: @NO}];
    }
}

@end
