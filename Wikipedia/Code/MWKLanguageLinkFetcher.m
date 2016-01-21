//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWKLanguageLinkFetcher.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+WMFExtras.h"
#import "Defines.h"
#import "WikipediaAppUtils.h"
#import "WMFNetworkUtilities.h"
#import "MWKLanguageLinkResponseSerializer.h"
#import "MediaWikiKit.h"

#import <AFNetworking/AFHTTPRequestOperationManager.h>

@interface MWKLanguageLinkFetcher ()

@property (strong, nonatomic) AFHTTPRequestOperationManager* manager;

@end

@implementation MWKLanguageLinkFetcher

- (instancetype)initAndFetchLanguageLinksForPageTitle:(MWKTitle*)title
                                          withManager:(AFHTTPRequestOperationManager*)manager
                                   thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate {
    self = [self initWithManager:manager delegate:delegate];
    [self fetchLanguageLinksForTitle:title success:nil failure:nil];
    return self;
}

- (instancetype)initWithManager:(AFHTTPRequestOperationManager*)manager delegate:(id<FetchFinishedDelegate>)delegate {
    NSParameterAssert(manager);
    self = [super init];
    if (self) {
        self.manager               = manager;
        self.fetchFinishedDelegate = delegate;
    }
    return self;
}

- (void)finishWithError:(NSError*)error fetchedData:(id)fetchedData block:(void (^)(id))block {
    [super finishWithError:error fetchedData:fetchedData];
    if (block) {
        dispatchOnMainQueue(^{
            block(error ? : fetchedData);
        });
    }
}

- (void)fetchLanguageLinksForTitle:(MWKTitle*)title
                           success:(void (^)(NSArray*))success
                           failure:(void (^)(NSError*))failure {
    if (!title.text.length) {
        NSError* error = [NSError errorWithDomain:WMFNetworkingErrorDomain
                                             code:WMFNetworkingError_InvalidParameters
                                         userInfo:nil];
        [self finishWithError:error fetchedData:nil block:failure];
        return;
    }
    NSURL* url           = [[SessionSingleton sharedInstance] urlForLanguage:title.site.language];
    NSDictionary* params = @{
        @"action": @"query",
        @"prop": @"langlinks",
        @"titles": title.text,
        @"lllimit": @"500",
        @"llprop": WMFJoinedPropertyParameters(@[@"langname", @"autonym"]),
        @"llinlanguagecode": [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode],
        @"redirects": @"",
        @"format": @"json"
    };
    [[MWNetworkActivityIndicatorManager sharedManager] push];
    [self.manager GET:url.absoluteString
           parameters:params
              success:^(AFHTTPRequestOperation* operation, NSDictionary* indexedLanguageLinks) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        NSAssert(indexedLanguageLinks.count < 2,
                 @"Expected language links to return one or no objects for the title we fetched, but got: %@",
                 indexedLanguageLinks);
        NSArray* languageLinksForTitle = [[indexedLanguageLinks allValues] firstObject];
        [self finishWithError:nil fetchedData:languageLinksForTitle block:success];
    } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        [self finishWithError:error fetchedData:nil block:failure];
    }];
}

@end
