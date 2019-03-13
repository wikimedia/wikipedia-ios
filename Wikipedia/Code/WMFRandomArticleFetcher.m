#import <WMF/WMFRandomArticleFetcher.h>
#import <WMF/MWNetworkActivityIndicatorManager.h>
#import <WMF/WMFNumberOfExtractCharacters.h>
#import <WMF/UIScreen+WMFImageWidth.h>
#import <WMF/MWKSearchResult.h>
#import <WMF/WMF-Swift.h>
#import <WMF/WMFLegacySerializer.h>

NS_ASSUME_NONNULL_BEGIN

@implementation WMFRandomArticleFetcher

- (void)fetchRandomArticleWithSiteURL:(NSURL *)siteURL completion:(void (^)(NSError *_Nullable error, MWKSearchResult *_Nullable result))completion {
    NSParameterAssert(siteURL);
    if (siteURL == nil) {
        NSError *error = [WMFFetcher invalidParametersError];
        completion(error, nil);
        return;
    }
    
    NSDictionary *params = [[self class] params];
    [self performMediaWikiAPIGETForURL:siteURL withQueryParameters:params completionHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            completion(error, nil);
            return;
        }
        
        if (response.statusCode == 304) {
            NSError *error = [WMFFetcher noNewDataError];
            completion(error, nil);
            return;
        }
        
        NSError *serializerError = nil;
        
        NSDictionary *resultsDictionary = [result valueForKeyPath:@"query.pages"];
        if (![resultsDictionary isKindOfClass:[NSDictionary class]]) {
            completion([WMFFetcher unexpectedResponseError], nil);
            return;
        }
        
        NSArray *results = [resultsDictionary allValues];
        results = [results wmf_select:^BOOL(NSDictionary *obj) {
            if (![obj isKindOfClass:[NSDictionary class]]) {
                return NO;
            }
            NSDictionary *pageprops = obj[@"pageprops"];
            if (![pageprops isKindOfClass:[NSDictionary class]]) {
                return YES;
            }
            return pageprops[@"disambiguation"] == nil;
        }];
        
        NSArray<MWKSearchResult *> *randomResults = [WMFLegacySerializer modelsOfClass:[MWKSearchResult class] fromUntypedArray:results error:&serializerError];
        if (serializerError) {
            completion(serializerError, nil);
            return;
        }
        
        if ([randomResults count] == 0) {
            completion([WMFFetcher unexpectedResponseError], nil);
            return;
        }
        
        MWKSearchResult *article = [self getBestRandomResultFromResults:randomResults];
        
        completion(nil, article);
    }];
}

- (MWKSearchResult *)getBestRandomResultFromResults:(NSArray *)results {
    NSSortDescriptor *extractSorter = [[NSSortDescriptor alloc] initWithKey:@"extract.length" ascending:NO];
    NSSortDescriptor *descripSorter = [[NSSortDescriptor alloc] initWithKey:@"wikidataDescription" ascending:NO];
    NSSortDescriptor *thumbSorter = [[NSSortDescriptor alloc] initWithKey:@"thumbnailURL.absoluteString" ascending:NO];
    results = [results sortedArrayUsingDescriptors:@[thumbSorter, descripSorter, extractSorter]];
    return [results firstObject];
}

+ (NSDictionary *)params {
    NSNumber *numberOfRandomItemsToFetch = @8;
    return @{
             @"action": @"query",
             @"prop": @"extracts|description|pageimages|pageprops|revisions",
             //random
             @"generator": @"random",
             @"grnnamespace": @0,
             @"grnfilterredir": @"nonredirects",
             @"grnlimit": numberOfRandomItemsToFetch,
             // extracts
             @"exintro": @YES,
             @"exlimit": numberOfRandomItemsToFetch,
             @"explaintext": @"",
             @"exchars": @(WMFNumberOfExtractCharacters),
             // pageprops
             @"ppprop": @"displaytitle|disambiguation",
             // pageimage
             @"piprop": @"thumbnail",
             //@"pilicense": @"any",
             @"pithumbsize": [[UIScreen mainScreen] wmf_leadImageWidthForScale],
             @"pilimit": numberOfRandomItemsToFetch,
             // revision
             // @"rrvlimit": @(1),
             @"rvprop": @"ids",
             @"format": @"json",
             };
}

@end

NS_ASSUME_NONNULL_END
