//  Created by Monte Hurd on 12/10/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "URLCache.h"
#import "NSString+Extras.h"
#import "SessionSingleton.h"

NSString* const WMFURLCacheSectionImageRetrievedNotification = @"WMFSectionImageRetrieved";

NSString* const kURLCacheKeyFileName                   = @"fileName";
NSString* const kURLCacheKeyData                       = @"data";
NSString* const kURLCacheKeyWidth                      = @"width";
NSString* const kURLCacheKeyHeight                     = @"height";
NSString* const kURLCacheKeyURL                        = @"url";
NSString* const kURLCacheKeyFileNameNoSizePrefix       = @"fileNameNoSizePrefix";
NSString* const kURLCacheKeyIsLeadImage                = @"isLeadImage";
NSString* const kURLCacheKeyPrimaryFocalUnitRectString = @"primaryFocalUnitRectString";


#if 0
#define URLCacheLog(...) NSLog(__VA_ARGS__)
#else
#define URLCacheLog(...)
#endif

@interface URLCache ()

@property (readonly) MWKArticle* article;

@end

@implementation URLCache

- (MWKArticle*)article {
    return [SessionSingleton sharedInstance].currentArticle;
}

- (BOOL)isMIMETypeRerouted:(NSString*)type {
    if ([type isEqualToString:@"image/jpeg"]) {
        return YES;
    }
    if ([type isEqualToString:@"image/png"]) {
        return YES;
    }
    if ([type isEqualToString:@"image/gif"]) {
        return YES;
    }
    return NO;
}

- (BOOL)isURLRerouted:(NSURL*)url {
    return [url.host isEqualToString:@"upload.wikimedia.org"];
}

- (void)storeCachedResponse:(NSCachedURLResponse*)cachedResponse forRequest:(NSURLRequest*)request {
    if (![self isMIMETypeRerouted:cachedResponse.response.MIMEType]) {
        URLCacheLog(@"Storing cached response for %@ due to MIMEType", request);
        [super storeCachedResponse:cachedResponse forRequest:request];
        if ([[request URL].host hasSuffix:@".m.wikipedia.org"] &&
            [cachedResponse.response.MIMEType rangeOfString:@"application/json"].location != NSNotFound) {
            // NSData *data = cachedResponse.data;
            // NSString *newStr = [[NSString alloc] initWithData:data
            //                                          encoding:NSUTF8StringEncoding];
            // URLCacheLog(@"%@", newStr);
            dispatch_async(dispatch_get_main_queue(), ^(){
                URLCacheLog(@"Processing zero headers for cached repsonse from %@", request);
                [self processZeroHeaders:cachedResponse.response];
            });
        }
        return;
    }
    if (![self isURLRerouted:request.URL]) {
        // Only cache stuff from upload.wikimedia.org
        URLCacheLog(@"%@ is not being cached since it's not from upload.wikimedia.org", request);
        return;
    }

    // Save image to article data store instead of default NSURLCache store if
    // "WMFInjectArticleWithImagesFromSection:" pre-created a placeholder MWKImage record.

    MWKImage* image = [self.article existingImageWithURL:[cachedResponse.response.URL absoluteString]];

    // If no placeholder record, call super and return for default NSURLCache behavior.
    if (!image) {
        // If an Image folder wasn't pre-created by "WMFInjectArticleWithImagesFromSection:" then don't try to cache.
        URLCacheLog(@"Storing cached response without image record for %@", request);
        [super storeCachedResponse:cachedResponse forRequest:request];
        return;
    }

    // Placeholder record found, so route image data to article data store.
    NSData* imageDataToUse = cachedResponse.data;

    @try {
        URLCacheLog(@"Rerouting cached response to WMF data store for %@", request);
        [self.article importImageData:imageDataToUse image:image];
    }@catch (NSException* e) {
        URLCacheLog(@"Failure to save cached image data: %@", e);
        return;
    }

    // Broadcast the image data so things like the table of contents can update
    // itself as images arrive.
    [[NSNotificationCenter defaultCenter] postNotificationName:WMFURLCacheSectionImageRetrievedNotification
                                                        object:nil
                                                      userInfo:@{
         kURLCacheKeyFileName: image.fileName,
         kURLCacheKeyData: imageDataToUse,
         kURLCacheKeyWidth: image.width,
         kURLCacheKeyHeight: image.height,
         kURLCacheKeyURL: image.sourceURL,
         kURLCacheKeyFileNameNoSizePrefix: image.fileNameNoSizePrefix,
         kURLCacheKeyIsLeadImage: @([image isLeadImage]),
         kURLCacheKeyPrimaryFocalUnitRectString: NSStringFromCGRect([image primaryFocalRectNormalizedToImageSize:NO])
     }];
}

- (NSCachedURLResponse*)cachedResponseForRequest:(NSURLRequest*)request {
    //URLCacheLog(@"Default Cache.db usage:\n\tcurrentDiskUsage: %lu\n\tdiskCapacity = %lu\n\tcurrentMemoryUsage = %lu\n\tmemoryCapacity = %lu", (unsigned long)self.currentDiskUsage, (unsigned long)self.diskCapacity, (unsigned long)self.currentMemoryUsage, (unsigned long)self.memoryCapacity);

    if (![self isMIMETypeRerouted:[request.URL.pathExtension wmf_imageMimeTypeForExtension]]) {
        return [super cachedResponseForRequest:request];
    }
    if (![self isURLRerouted:request.URL]) {
        return [super cachedResponseForRequest:request];
    }

    /*
       NSData *imgData = UIImagePNGRepresentation([UIImage imageNamed:@"logo-onboarding-subtitle.png"]);
       NSURLResponse *r = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:@"image/jpeg" expectedContentLength:imgData.length textEncodingName:nil];
       NSCachedURLResponse *d = [[NSCachedURLResponse alloc] initWithResponse:r data:imgData];
       return d;
     */

    NSURL* requestURL = [request.URL copy];

    __block NSCachedURLResponse* cachedResponse = nil;
    //URLCacheLog(@"[NSThread isMainThread] = %d", [NSThread isMainThread]);
    NSString* imageURL = requestURL.absoluteString;

    //Image *imageFromDB = (Image *)[articleDataContext_.mainContext getEntityForName: @"Image" withPredicateFormat:@"sourceUrl == %@", imageURL];
    MWKImage* imageFromDB = [self.article imageWithURL:imageURL];

    // If a core data Image was found, but its data length is zero, the Image record was probably
    // created when the section html was parsed to create sectionImage records, in which case
    // a request needs to actually be made, so set cachedResponse to nil so this happens.
    // URLCacheLog(@"imageFromDB.data = %@", imageFromDB.data);
    if (![imageFromDB isCached]) {
        cachedResponse = nil;
    } else if (imageFromDB) {
        NSData* imageData = [self.article.dataStore imageDataWithImage:imageFromDB];
        //URLCacheLog(@"CACHED IMAGE FOUND!!!!!! requestURL = %@", imageURL);
        NSURLResponse* response = [[NSURLResponse alloc] initWithURL:requestURL MIMEType:imageFromDB.mimeType expectedContentLength:imageData.length textEncodingName:nil];
        cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:imageData];
    }

    if (cachedResponse) {
        return cachedResponse;
    }

    //URLCacheLog(@"CACHED IMAGE NOT FOUND!!!!! request.URL = %@", imageURL);
    return [super cachedResponseForRequest:request];
}

- (void)processZeroHeaders:(NSURLResponse*)response {
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    NSHTTPURLResponse* httpUrlResponse       = (NSHTTPURLResponse*)response;
    NSDictionary* headers                    = httpUrlResponse.allHeaderFields;
    NSString* xZeroRatedHeader               = [headers objectForKey:@"X-CS"];
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
        xZeroRatedHeader       = @"000-00";
    }

    if (zeroRatedHeaderPresent && (!zeroDisposition || zeroProviderChanged)) {
        [SessionSingleton sharedInstance].zeroConfigState.disposition = YES;
        [SessionSingleton sharedInstance].zeroConfigState.partnerXcs  = xZeroRatedHeader;
        [notificationCenter postNotificationName:@"ZeroStateChanged" object:self userInfo:@{@"state": @YES}];
    } else if (!zeroRatedHeaderPresent && zeroDisposition) {
        [SessionSingleton sharedInstance].zeroConfigState.disposition = NO;
        [SessionSingleton sharedInstance].zeroConfigState.partnerXcs  = nil;
        [notificationCenter postNotificationName:@"ZeroStateChanged" object:self userInfo:@{@"state": @NO}];
    }
}

@end
