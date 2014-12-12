//  Created by Monte Hurd on 12/10/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "URLCache.h"
//#import "ArticleDataContextSingleton.h"
//#import "ArticleCoreDataObjects.h"
//#import "NSManagedObjectContext+SimpleFetch.h"
#import "NSString+Extras.h"
#import "SessionSingleton.h"

@interface URLCache ()

@property (readonly) MWKArticle *article;

// Reminder: When using this debugging image to test caching (i.e. seeing if article images
// show the placeholder) be sure to quit and restart the app (double-tap the home button
// and flick the app up offscreen) otherwise the web view keeps showing its memory cache
// version of the actual image it downloaded - that is, it has no need to attempt a cache hit.
// Once the app is then restarted if everything is working the article images should all
// show the placeholder image.
@property (strong, nonatomic) NSData *debuggingPlaceHolderImageData;

@end

@implementation URLCache

- (id)initWithMemoryCapacity:(NSUInteger)memoryCapacity diskCapacity:(NSUInteger)diskCapacity diskPath:(NSString *)path
{
    self = [super initWithMemoryCapacity:memoryCapacity diskCapacity:diskCapacity diskPath:path];
    if (self) {
        self.debuggingPlaceHolderImageData = UIImagePNGRepresentation([UIImage imageNamed:@"logo-onboarding-subtitle.png"]);
    }
    return self;
}

-(MWKArticle *)article
{
    return [SessionSingleton sharedInstance].article;
}

-(BOOL)isMIMETypeRerouted:(NSString *)type
{
    if  ([type isEqualToString:@"image/jpeg"]) return YES;
    if  ([type isEqualToString:@"image/png"]) return YES;
    if  ([type isEqualToString:@"image/gif"]) return YES;
    return NO;
}

-(BOOL)isURLRerouted:(NSURL *)url
{
    return [url.host isEqualToString:@"upload.wikimedia.org"];
}

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request
{
    if (![self isMIMETypeRerouted:cachedResponse.response.MIMEType]) {
        [super storeCachedResponse:cachedResponse forRequest:request];
        if ([[request URL].host hasSuffix:@".m.wikipedia.org"] &&
            [cachedResponse.response.MIMEType rangeOfString:@"application/json"].location != NSNotFound) {
            // NSData *data = cachedResponse.data;
            // NSString *newStr = [[NSString alloc] initWithData:data
            //                                          encoding:NSUTF8StringEncoding];
            // NSLog(@"%@", newStr);
            dispatch_async(dispatch_get_main_queue(), ^(){
                [self processZeroHeaders:cachedResponse.response];
            });
        }
        return;
    }
    if (![self isURLRerouted:request.URL]) {
        // Only cache stuff from upload.wikimedia.org
        return;
    }

    // Save image to articleData store instead of default NSURLCache store.
    NSURL *url = cachedResponse.response.URL;
    NSString *urlStr = [url absoluteString];
    
    // Strip "http:" or "https:"
    urlStr = [urlStr getUrlWithoutScheme];
    
    NSData *imageDataToUse = cachedResponse.data;
    
    MWKImage *image = [self.article imageWithURL:urlStr];
    
    if (!image) {
        // If an Image object wasn't pre-created by :createSectionImageRecordsForSectionHtml:onContext:" then don't try to cache.
        [super storeCachedResponse:cachedResponse forRequest:request];
        return;
    }
    
    /*
     // Quick debugging filter which makes image blue before saving them to our articleData store.
     // (locks up occasionally - probably not thread safe - only for testing so no worry for now)
     CIImage *inputImage = [[CIImage alloc] initWithData:cachedResponse.data];
     
     CIFilter *colorMonochrome = [CIFilter filterWithName:@"CIColorMonochrome"];
     [colorMonochrome setDefaults];
     [colorMonochrome setValue: inputImage forKey: @"inputImage"];
     [colorMonochrome setValue: [CIColor colorWithRed:0.6f green:0.6f blue:1.0f alpha:1.0f] forKey: @"inputColor"];
     
     CIImage *outputImage = [colorMonochrome valueForKey:@"outputImage"];
     CIContext *context = [CIContext contextWithOptions:nil];
     UIImage *outputUIImage = [UIImage imageWithCGImage:[context createCGImage:outputImage fromRect:outputImage.extent]];
     imageDataToUse = UIImagePNGRepresentation(outputUIImage);
     */
    
    // Another quick debugging indicator which caches a "W" logo image instead of the real image.
    // (This one has no thread safety issues.)
    //imageDataToUse = self.debuggingPlaceHolderImageData;

    [self.article importImageData:imageDataToUse image:image mimeType:cachedResponse.response.MIMEType];
    
    // Broadcast the image data so things like the table of contents can update
    // itself as images arrive.
    [[NSNotificationCenter defaultCenter] postNotificationName: @"SectionImageRetrieved"
                                                        object: nil
                                                      userInfo: @{
                                                                  @"fileName": image.fileName,
                                                                  @"data": imageDataToUse,
                                                                  }];

}

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request {
    //NSLog(@"Default Cache.db usage:\n\tcurrentDiskUsage: %lu\n\tdiskCapacity = %lu\n\tcurrentMemoryUsage = %lu\n\tmemoryCapacity = %lu", (unsigned long)self.currentDiskUsage, (unsigned long)self.diskCapacity, (unsigned long)self.currentMemoryUsage, (unsigned long)self.memoryCapacity);

    if (![self isMIMETypeRerouted:[request.URL.pathExtension getImageMimeTypeForExtension]]) {
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

    NSURL *requestURL = [request.URL copy];
    
    __block NSCachedURLResponse *cachedResponse = nil;
    //NSLog(@"[NSThread isMainThread] = %d", [NSThread isMainThread]);
    NSString *imageURL = requestURL.absoluteString;
    
    // Strip "http:" or "https:"
    //imageURL = [imageURL getUrlWithoutScheme];

    //Image *imageFromDB = (Image *)[articleDataContext_.mainContext getEntityForName: @"Image" withPredicateFormat:@"sourceUrl == %@", imageURL];
    MWKImage *imageFromDB = [self.article imageWithURL:imageURL];
    
    // If a core data Image was found, but its data length is zero, the Image record was probably
    // created when the section html was parsed to create sectionImage records, in which case
    // a request needs to actually be made, so set cachedResponse to nil so this happens.
    // NSLog(@"imageFromDB.data = %@", imageFromDB.data);
    if (imageFromDB && !imageFromDB.dateRetrieved) {
        cachedResponse = nil;
    }else if (imageFromDB) {
        NSData *imageData = [self.article.dataStore imageDataWithImage:imageFromDB];
        //NSLog(@"CACHED IMAGE FOUND!!!!!! requestURL = %@", imageURL);
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:requestURL MIMEType:imageFromDB.mimeType expectedContentLength:imageData.length textEncodingName:nil];
        cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:imageData];
    }

    if (cachedResponse) return cachedResponse;

    //NSLog(@"CACHED IMAGE NOT FOUND!!!!! request.URL = %@", imageURL);
    return [super cachedResponseForRequest:request];
}

-(void) processZeroHeaders:(NSURLResponse*) response {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    NSHTTPURLResponse *httpUrlResponse = (NSHTTPURLResponse*)response;
    NSDictionary *headers = httpUrlResponse.allHeaderFields;
    NSString *xZeroRatedHeader =  [headers objectForKey:@"X-CS"];
    BOOL zeroRatedHeaderPresent = xZeroRatedHeader != nil;
    NSString *xcs = [SessionSingleton sharedInstance].zeroConfigState.partnerXcs;
    BOOL zeroProviderChanged = zeroRatedHeaderPresent && ![xZeroRatedHeader isEqualToString:xcs];
    BOOL zeroDisposition = [SessionSingleton sharedInstance].zeroConfigState.disposition;
    
    // For testing Wikipedia Zero visual flourishes.
    // Go to WebViewController.m and uncomment the W0 part,
    // then when running the app in the simulator fire the
    // memory warning to toggle the fake state on or off.
    if ([SessionSingleton sharedInstance].zeroConfigState.fakeZeroOn) {
        zeroRatedHeaderPresent = YES;
        xZeroRatedHeader = @"000-00";
    }
    
    if (zeroRatedHeaderPresent && (!zeroDisposition || zeroProviderChanged)) {
        [SessionSingleton sharedInstance].zeroConfigState.disposition = YES;
        [SessionSingleton sharedInstance].zeroConfigState.partnerXcs = xZeroRatedHeader;
        [notificationCenter postNotificationName:@"ZeroStateChanged" object:self userInfo:@{@"state": @YES}];
    } else if (!zeroRatedHeaderPresent && zeroDisposition) {
        [SessionSingleton sharedInstance].zeroConfigState.disposition = NO;
        [SessionSingleton sharedInstance].zeroConfigState.partnerXcs = nil;
        [notificationCenter postNotificationName:@"ZeroStateChanged" object:self userInfo:@{@"state": @NO}];
    }
}

@end
