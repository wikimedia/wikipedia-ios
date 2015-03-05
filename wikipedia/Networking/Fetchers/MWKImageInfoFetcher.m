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
#import <BlocksKit/BlocksKit.h>

// FIXME: remove this soon
#import "SessionSingleton.h"

@interface MWKImageInfoFetcher ()

@property (nonatomic, strong, readonly) AFHTTPRequestOperationManager* manager;

// Designated initializer, can be used to inject a mock request manager while testing.
- (instancetype)initWithDelegate:(id<FetchFinishedDelegate>)delegate
                  requestManager:(AFHTTPRequestOperationManager*)requestManager;

@end

@implementation MWKImageInfoFetcher

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

- (AFHTTPRequestOperation*)fetchInfoForArticle:(MWKArticle*)article {
    NSArray* filesToBeFetched = [[article.images uniqueLargestVariants] bk_map:^NSString*(MWKImage* image) {
        NSAssert(image.canonicalFilename.length, @"Unable to form canonical filename from image: %@", image.sourceURL);
        return [@"File:" stringByAppendingString:image.canonicalFilename];
    }];
    return [self fetchInfoForPageTitles:filesToBeFetched fromSite:article.site];
}

- (AFHTTPRequestOperation*)fetchInfoForPageTitles:(NSArray*)imageTitles fromSite:(MWKSite*)site {
    NSParameterAssert([imageTitles count]);
    NSParameterAssert(site);
    NSAssert(site.language.length, @"Site must have a non-empty language in order to send requests: %@", site);

    // TODO: loosen this coupling
    NSString* url = [[[SessionSingleton sharedInstance] urlForLanguage:site.language] absoluteString];
    NSAssert(url, @"Unable to form URL for language: %@", site.language);

    __weak MWKImageInfoFetcher* weakSelf = self;
    AFHTTPRequestOperation* request      =
        [self.manager
         GET:url
         parameters:@{
             @"format": @"json",
             @"action": @"query",
             @"titles": WMFJoinedPropertyParameters(imageTitles),
             @"rawcontinue": @"", //< suppress old continue warning
             @"prop": @"imageinfo",
             @"iiprop": WMFJoinedPropertyParameters(@[@"url", @"extmetadata", @"dimensions"]),
             @"iiextmetadatafilter": WMFJoinedPropertyParameters([MWKImageInfoResponseSerializer requiredExtMetadataKeys]),
             // 1280 is a well-populated image width in back-end cache that gives good-enough quality on most iOS devices
             @"iiurlwidth": @1280,
         }
            success:^(AFHTTPRequestOperation* operation, NSArray* galleryItems) {
        MWKImageInfoFetcher* strSelf = weakSelf;
        if (!strSelf) {
            return;
        }
        [strSelf finishWithError:nil fetchedData:galleryItems];
    } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        MWKImageInfoFetcher* strSelf = weakSelf;
        if (!strSelf) {
            return;
        }
        [strSelf finishWithError:error fetchedData:nil];
    }];
    return request;
}

@end
