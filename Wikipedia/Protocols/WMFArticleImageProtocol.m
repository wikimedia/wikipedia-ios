//  Created by Monte Hurd on 4/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFArticleImageProtocol.h"
#import "NSURL+WMFRest.h"
#import "SessionSingleton.h"
#import "NSString+Extras.h"

NSString* const WMFArticleImageSectionImageRetrievedNotification = @"WMFSectionImageRetrieved";

// We need to set a property on the request to prevent infinite loops due to handling "http(s)" requests.
// See: http://www.raywenderlich.com/59982/nsurlprotocol-tutorial
static NSString* const WMFArticleImageProtocolAlreadyHandled = @"WMFArticleImageProtocolAlreadyHandled";

static NSString* const WMFArticleImageProtocolHost = @"upload.wikimedia.org";

__attribute__((constructor)) static void WMFRegisterArticleImageProtocol() {
    [NSURLProtocol registerClass:[WMFArticleImageProtocol class]];
}

@interface WMFArticleImageProtocol () <NSURLConnectionDelegate>
@property (nonatomic, strong) NSURLConnection* connection;
@property (nonatomic, strong) NSMutableData* mutableImageData;
@property (nonatomic, strong) NSURLResponse* response;
@end

@implementation WMFArticleImageProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest*)request {
    if (
        // Has 'http' or 'https' scheme and 'upload.wikimedia.org' host.
        ![[request URL] wmf_conformsToAnyOfSchemes:[self schemesToExamine] andHasHost:WMFArticleImageProtocolHost] ||

        // Prevent multiple 'startLoading' calls for a given resource.
        [NSURLProtocol propertyForKey:WMFArticleImageProtocolAlreadyHandled inRequest:request] ||

        // Check that extension is one we are interested in.
        ![self isFileExtensionRerouted:request.URL.pathExtension] ||

        // Only interested if image (or a size variant of image) has a data store record.
        // (we make placeholder records when the html is received and parsed)
        ![self imageVariantPlaceHolderRecordFoundForRequest:request]
        ) {
        return NO;
    }

    return YES;
}

+ (BOOL)imageVariantPlaceHolderRecordFoundForRequest:(NSURLRequest*)request {
    NSArray* variants = [self.article.images imageSizeVariants:request.URL.absoluteString];
    return (!variants || (variants.count == 0)) ? NO : YES;
}

+ (MWKArticle*)article {
    return [SessionSingleton sharedInstance].currentArticle;
}

- (MWKArticle*)article {
    return [WMFArticleImageProtocol article];
}

+ (NSArray*)schemesToExamine {
    static NSArray* schemes = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        schemes = @[@"https", @"http"];
    });
    return schemes;
}

+ (NSArray*)mimeTypesToCache {
    static NSArray* types = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        types = @[@"image/jpeg", @"image/png", @"image/gif"];
    });
    return types;
}

+ (BOOL)isFileExtensionRerouted:(NSString*)extension {
    return [self.mimeTypesToCache containsObject:[extension wmf_mimeTypeForExtension]];
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)request {
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest*)a toRequest:(NSURLRequest*)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading {
    MWKImage* image = [self.article existingImageWithURL:[self.request.URL absoluteString]];
    if ([image isCached]) {
        [self respondWithImageData:[image asNSData]];
    } else {
        [self sendImageRequest:self.request];
    }
}

- (void)respondWithImageData:(NSData*)imageData {
    NSURLResponse* response =
        [[NSURLResponse alloc] initWithURL:self.request.URL
                                  MIMEType:[self.request.URL.pathExtension wmf_mimeTypeForExtension]
                     expectedContentLength:imageData.length
                          textEncodingName:nil];

    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [[self client] URLProtocol:self didLoadData:imageData];
    [[self client] URLProtocolDidFinishLoading:self];
}

- (void)sendImageRequest:(NSURLRequest*)request {
    NSMutableURLRequest* mutableRequest = [request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:WMFArticleImageProtocolAlreadyHandled inRequest:mutableRequest];
    self.connection = [NSURLConnection connectionWithRequest:mutableRequest delegate:self];
}

- (void)stopLoading {
    [self.connection cancel];
    self.connection = nil;
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    self.response         = response;
    self.mutableImageData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    [self.client URLProtocol:self didLoadData:data];
    [self.mutableImageData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    [self.client URLProtocolDidFinishLoading:self];

    MWKImage* image = [self saveImageToDataCache:self.mutableImageData];
    if (image) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self broadcastInfoForImage:image];
        });
    }
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    [self.client URLProtocol:self didFailWithError:error];
}

/**
 *  Saves image to the data store record for the current article.
 *
 *  @return Returns image on success, nil on fail.
 */
- (MWKImage*)saveImageToDataCache:(NSData*)imageData {
    NSAssert(self.request, @"No request found.");
    NSAssert(self.request.URL, @"No request URL found.");
    NSAssert(imageData, @"Attempt to save Nil image data to data store for URL: %@", self.request.URL.absoluteString);

    if (!imageData) {
        return nil;
    }

    // "canInitWithRequest:" already determined that this image, or a size variant of it, has a placeholder MWKImage record.
    MWKImage* image = [self.article existingImageWithURL:self.request.URL.absoluteString];
    // If this is a size variant, MWKImage placeholder record won't exist, so we'll need to create one.
    if (!image) {
        // Use kMWKArticleSectionNone (section Images.plist's should be just the orig image urls, not
        // all the variants from the src set).
        image = [self.article importImageURL:self.request.URL.absoluteString sectionId:kMWKArticleSectionNone];
    }

    @try {
        //NSLog(@"Rerouting cached response to WMF data store for %@", self.request);
        [self.article importImageData:imageData image:image];
    }@catch (NSException* e) {
        NSAssert(false, @"Failure to save cached image data: %@ \n %@", e, self.request.URL.absoluteString);
        return nil;
    }

    return image;
}

- (void)broadcastInfoForImage:(MWKImage*)image {
    [[NSNotificationCenter defaultCenter] postNotificationName:WMFArticleImageSectionImageRetrievedNotification
                                                        object:image
                                                      userInfo:nil];
}

@end
