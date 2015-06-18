//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWKLanguageLinkFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"
#import "Defines.h"
#import "WikipediaAppUtils.h"
#import "WMFNetworkUtilities.h"
#import "MWKLanguageLinkResponseSerializer.h"

@interface MWKLanguageLinkFetcher ()

@property (readwrite, strong, nonatomic) MWKTitle* title;
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
    self = [super init];
    if (self) {
        self.manager               = manager;
        self.fetchFinishedDelegate = delegate;
        NSAssert([manager.responseSerializer isKindOfClass:[MWKLanguageLinkResponseSerializer class]],
                 @"%@ needs to have an instance of %@ as its response serializer",
                 self, [MWKLanguageLinkResponseSerializer class]);
    }
    return self;
}

- (void)fetchLanguageLinksForTitle:(MWKTitle*)title
                           success:(void (^)(NSArray*))success
                           failure:(void (^)(NSError*))failure {
    self.title = title;
    NSURL* url           = [[SessionSingleton sharedInstance] urlForLanguage:self.title.site.language];
    NSDictionary* params = @{
        @"action": @"query",
        @"prop": @"langlinks",
        @"titles": self.title.text,
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
        NSAssert([[indexedLanguageLinks allValues] firstObject],
                 @"Expected language links to return one object for the title we fetched, but got: %@",
                 indexedLanguageLinks);
        NSArray* languageLinksForTitle = [[indexedLanguageLinks allValues] firstObject];
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success(languageLinksForTitle);
            });
        }
        [self finishWithError:nil fetchedData:languageLinksForTitle];
    } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
        [self finishWithError:error fetchedData:nil];
    }];
}

@end
