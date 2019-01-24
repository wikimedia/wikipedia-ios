#import <WMF/WMFRelatedSearchFetcher.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/MWNetworkActivityIndicatorManager.h>
@import Mantle;
//Models
#import <WMF/WMFRelatedSearchResults.h>
#import <WMF/MWKSearchResult.h>

#import <WMF/NSDictionary+WMFCommonParams.h>
#import <WMF/WMFLogging.h>

#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

NSUInteger const WMFMaxRelatedSearchResultLimit = 20;

#pragma mark - Fetcher Implementation

@implementation WMFRelatedSearchFetcher

- (void)fetchArticlesRelatedArticleWithURL:(NSURL *)URL
                               resultLimit:(NSUInteger)resultLimit
                           completionBlock:(void (^)(WMFRelatedSearchResults *results))completion
                              failureBlock:(void (^)(NSError *error))failure {
    NSString *URLString = URL.absoluteString;
    if (!URLString) {
        if (failure) {
            failure([NSError wmf_errorWithType:WMFErrorTypeInvalidRequestParameters userInfo:nil]);
        }
        return;
    }
    if (resultLimit > WMFMaxRelatedSearchResultLimit) {
        DDLogError(@"Illegal attempt to request %lu articles, limiting to %lu.",
                   (unsigned long)resultLimit, (unsigned long)WMFMaxRelatedSearchResultLimit);
        resultLimit = WMFMaxRelatedSearchResultLimit;
    }
    NSNumber *numResults = @(resultLimit);
    NSString *articleTitle = URL.wmf_title;
    NSString *gsrsearch = [NSString stringWithFormat:@"morelike:%@", articleTitle];
    NSMutableDictionary *baseParams = [NSMutableDictionary wmf_titlePreviewRequestParameters];
    [baseParams setValuesForKeysWithDictionary:@{
                                                 @"generator": @"search",
                                                 // search
                                                 @"gsrsearch": gsrsearch,
                                                 @"gsrnamespace": @0,
                                                 @"gsrwhat": @"text",
                                                 @"gsrinfo": @"",
                                                 @"gsrprop": @"redirecttitle",
                                                 @"gsroffset": @0,
                                                 @"gsrlimit": numResults,
                                                 @"ppprop": @"displaytitle",
                                                 // extracts
                                                 @"exlimit": numResults,
                                                 // pageimage
                                                 @"pilimit": numResults,
                                                 //@"pilicense": @"any",
                                                 }];
    [[MWNetworkActivityIndicatorManager sharedManager] push];
    [self performMediaWikiAPIGETForURL:URL withQueryParameters:baseParams completionHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        if (error) {
            if (failure) {
                failure(error);
            }
            return;
        }
        NSError *mantleError = nil;
        NSArray *results = [WMFLegacySerializer modelsOfClass:[MWKSearchResult class] fromAllValuesOfDictionaryForKeyPath:@"query.pages" inJSONDictionary:result error:&mantleError];
        if (mantleError) {
            if (failure) {
                failure(mantleError);
            }
            return;
        }
        if (completion) {
            completion([[WMFRelatedSearchResults alloc] initWithURL:URL results:results]);
        }
    }];
}

@end

NS_ASSUME_NONNULL_END
