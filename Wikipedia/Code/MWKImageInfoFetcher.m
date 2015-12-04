// //  ArticleImageInfoFetcher.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/4/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKImageInfoFetcher.h"
#import "WMFNetworkUtilities.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "MWKImageInfoResponseSerializer.h"
#import "MWKArticle.h"
#import "MWKImageList.h"
#import "MediaWikiKit.h"
#import "AFHTTPRequestOperationManager+WMFDesktopRetry.h"
#import "UIScreen+WMFImageWidth.h"

@interface MWKImageInfoFetcher ()

@property (nonatomic, strong, readonly) AFHTTPRequestOperationManager* manager;

// Designated initializer, can be used to inject a mock request manager while testing.
- (instancetype)initWithDelegate:(id<FetchFinishedDelegate>)delegate
                  requestManager:(AFHTTPRequestOperationManager*)requestManager;

@end

@implementation MWKImageInfoFetcher

- (instancetype)init {
    return [self initWithDelegate:nil];
}

- (instancetype)initWithDelegate:(id<FetchFinishedDelegate>)delegate {
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
    manager.responseSerializer = [MWKImageInfoResponseSerializer serializer];
    return [self initWithDelegate:delegate requestManager:manager];
}

- (instancetype)initWithDelegate:(id<FetchFinishedDelegate>)delegate
                  requestManager:(AFHTTPRequestOperationManager*)requestManager {
    NSParameterAssert(requestManager);
    self = [super init];
    if (self) {
        self.fetchFinishedDelegate = delegate;
        _manager                   = requestManager;
    }
    return self;
}

- (AnyPromise*)fetchGalleryInfoForImagesOnPages:(NSArray*)pageTitles
                                       fromSite:(MWKSite*)site
                               metadataLanguage:(nullable NSString*)metadataLanguage; {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull resolve) {
        [self fetchInfoForTitles:pageTitles
                        fromSite:site
                  thumbnailWidth:[[UIScreen mainScreen] wmf_galleryImageWidthForScale]
                 extmetadataKeys:[MWKImageInfoResponseSerializer galleryExtMetadataKeys]
                metadataLanguage:metadataLanguage
                    useGenerator:YES
                         success:resolve
                         failure:resolve];
    }];
}

- (AnyPromise*)fetchPartialInfoForImagesOnPages:(NSArray*)pageTitles
                                       fromSite:(MWKSite*)site
                               metadataLanguage:(nullable NSString*)metadataLanguage {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull resolve) {
        [self fetchInfoForTitles:pageTitles
                        fromSite:site
                  thumbnailWidth:[[UIScreen mainScreen] wmf_potdImageWidthForScale]
                 extmetadataKeys:[MWKImageInfoResponseSerializer picOfTheDayExtMetadataKeys]
                metadataLanguage:metadataLanguage
                    useGenerator:YES
                         success:resolve
                         failure:resolve];
    }];
}

- (id<MWKImageInfoRequest>)fetchGalleryInfoForImageFiles:(NSArray*)imageTitles
                                                fromSite:(MWKSite*)site
                                                 success:(void (^)(NSArray*))success
                                                 failure:(void (^)(NSError*))failure {
    return [self fetchInfoForTitles:imageTitles
                           fromSite:site
                     thumbnailWidth:[[UIScreen mainScreen] wmf_galleryImageWidthForScale]
                    extmetadataKeys:[MWKImageInfoResponseSerializer galleryExtMetadataKeys]
                   metadataLanguage:site.language
                       useGenerator:NO
                            success:success
                            failure:failure];
}

- (id<MWKImageInfoRequest>)fetchInfoForTitles:(NSArray*)titles
                                     fromSite:(MWKSite*)site
                               thumbnailWidth:(NSNumber*)thumbnailWidth
                              extmetadataKeys:(NSArray<NSString*>*)extMetadataKeys
                             metadataLanguage:(nullable NSString*)metadataLanguage
                                 useGenerator:(BOOL)useGenerator
                                      success:(void (^)(NSArray*))success
                                      failure:(void (^)(NSError*))failure {
    NSParameterAssert([titles count]);
    NSAssert([titles count] <= 50, @"Only 50 titles can be queried at a time.");
    NSParameterAssert(site);
    NSAssert(site.language.length, @"Site must have a non-empty language in order to send requests: %@", site);

    NSMutableDictionary* params =
        [@{@"format": @"json",
           @"action": @"query",
           @"titles": WMFJoinedPropertyParameters(titles),
           // suppress continue warning
           @"rawcontinue": @"",
           @"prop": @"imageinfo",
           @"iiprop": WMFJoinedPropertyParameters(@[@"url", @"extmetadata", @"dimensions"]),
           @"iiextmetadatafilter": WMFJoinedPropertyParameters(extMetadataKeys),
           @"iiurlwidth": thumbnailWidth } mutableCopy];

    if (useGenerator) {
        params[@"generator"] = @"images";
    }

    if (metadataLanguage) {
        params[@"iiextmetadatalanguage"] = metadataLanguage;
    }

    @weakify(self);
    AFHTTPRequestOperation* request =
        [self.manager wmf_GETWithSite:site
                           parameters:params
                                retry:nil
                              success:^(AFHTTPRequestOperation* operation, NSArray* galleryItems) {
        @strongify(self);
        [self finishWithError:nil fetchedData:galleryItems];
        if (success) {
            success(galleryItems);
        }
    }
                              failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        @strongify(self);
        [self finishWithError:error fetchedData:nil];
        if (failure) {
            failure(error);
        }
    }];
    NSParameterAssert(request);
    return (id<MWKImageInfoRequest>)request;
}

- (void)cancelAllFetches {
    [self.manager.operationQueue cancelAllOperations];
}

@end
