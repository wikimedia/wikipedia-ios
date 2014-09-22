//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SearchResultFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"
#import "Defines.h"
#import "NSString+Extras.h"
#import "WikipediaAppUtils.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "NSManagedObjectContext+SimpleFetch.h"

@interface SearchResultFetcher()

@property (strong, nonatomic) NSString *domain;

@end

@implementation SearchResultFetcher

-(instancetype)initAndSearchForTerm: (NSString *)searchTerm
                        withManager: (AFHTTPRequestOperationManager *)manager
                 thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate;
{
    self = [super init];
    if (self) {
        self.fetchFinishedDelegate = delegate;
        [self searchForTerm:searchTerm withManager:manager];
    }
    return self;
}

- (void)searchForTerm:(NSString *)searchTerm withManager:(AFHTTPRequestOperationManager *)manager
{
    NSString *url = [SessionSingleton sharedInstance].searchApiUrl;

    NSDictionary *params = [self getParamsForTerm:searchTerm];
    
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        // Convert the raw NSData response to a dictionary.
        if (![self isDataResponseValid:responseObject]){
            // Fake out an error if bad response received.
            responseObject = @{@"error": @{@"info": @"Search data not found."}};
        }else{
            // Should be able to proceed with dictionary conversion.
            NSError *jsonError = nil;
            responseObject = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&jsonError];
            responseObject = jsonError ? @{} : responseObject;
        }
        
        //NSLog(@"CAPTCHA RESETTER DATA RETRIEVED = %@", responseObject);
        
        // Handle case where response is received, but API reports error.
        NSError *error = nil;
        if (responseObject[@"error"]){
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain: @"Search Result Fetcher"
                                        code: SEARCH_RESULT_ERROR_API
                                    userInfo: errorDict];
        }

        NSArray *output = @[];
        if (!error) {
            output = [self getSanitizedResponse:responseObject forSearchTerm:searchTerm];
        }

        // If no matches set error.
        if (output.count == 0) {
            NSMutableDictionary *errorDict = @{}.mutableCopy;
            
            errorDict[NSLocalizedDescriptionKey] = MWLocalizedString(@"search-no-matches", nil);
            
            // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
            error = [NSError errorWithDomain:@"Search Result Fetcher" code:SEARCH_RESULT_ERROR_NO_MATCHES userInfo:errorDict];
        }

        if (!error) [self preparePlaceholderImageRecordsForOutput:output];

        [self finishWithError: error
                     userData: output];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        //NSLog(@"CAPTCHA RESETTER FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError: error
                     userData: nil];
    }];
}

-(NSDictionary *)getParamsForTerm:(NSString *)searchTerm
{
    // Based on https://gerrit.wikimedia.org/r/#/c/158011/2/javascripts/modules/search/SearchApi.js
    return @{
             @"action": @"query",
             @"generator": @"prefixsearch",
             @"gpssearch": (searchTerm ? searchTerm : @""),
             @"gpsnamespace": @0,
             @"gpslimit": @(SEARCH_MAX_RESULTS),
             @"prop": @"pageimages",
             @"piprop": @"thumbnail",
             @"pithumbsize" : @(SEARCH_THUMBNAIL_WIDTH),
             @"pilimit": @(SEARCH_MAX_RESULTS),
             @"list": @"prefixsearch",
             @"pssearch": (searchTerm ? searchTerm : @""),
             @"pslimit": @(SEARCH_MAX_RESULTS),
             @"format": @"json"
             };
}

-(NSArray *)getSanitizedResponse:(NSDictionary *)rawResponse forSearchTerm:(NSString *)searchTerm
{
    // Make output array contain just dictionaries for each result.
    NSMutableArray *output = @[].mutableCopy;
    NSDictionary *jsonDict = (NSDictionary *)rawResponse;
    if (jsonDict.count > 0) {
        NSDictionary *query = (NSDictionary *)jsonDict[@"query"];
        if (query) {
        
            NSDictionary *pages = (NSDictionary *)query[@"pages"];
            NSArray *pagesOrdered = (NSArray *)query[@"prefixsearch"];
            
            if (pages && pagesOrdered) {

                // Loop through the prefixsearch results (rather than the pages results) so we maintain correct order.
                // Based on https://gerrit.wikimedia.org/r/#/c/158011/2/javascripts/modules/search/SearchApi.js
                for (NSDictionary *prefixPage in pagesOrdered) {

                    // "dictionaryWithDictionary" used because it creates a deep mutable copy of the __NSCFDictionary.
                    NSMutableDictionary *mutablePrefixPage = [NSMutableDictionary dictionaryWithDictionary:prefixPage];
                    
                    // Add thumb placeholder.
                    mutablePrefixPage[@"thumbnail"] = @{}.mutableCopy;
                    
                    // Grab the thumbnail info from the non-prefixsearch result for this pageid.
                    for (NSDictionary *page in pages.allValues) {
                        id pageId = page[@"pageid"];
                        id prefixPageId = mutablePrefixPage[@"pageid"];
                        if (pageId && prefixPageId && [prefixPageId isKindOfClass:[NSNumber class]] && [pageId isKindOfClass:[NSNumber class]]){
                            if ([prefixPageId isEqualToNumber:pageId]) {
                                if (page[@"thumbnail"]){
                                    mutablePrefixPage[@"thumbnail"] = page[@"thumbnail"];
                                    break;
                                }
                            }
                        }
                    }
                    
                    mutablePrefixPage[@"title"] = mutablePrefixPage[@"title"] ? [mutablePrefixPage[@"title"] wikiTitleWithoutUnderscores] : @"";
                    
                    if (mutablePrefixPage) [output addObject:mutablePrefixPage];
                }
            }
        }
    }

    return output;
}

#pragma mark Core data Image record placeholder for thumbnail (so they get cached)

-(void)preparePlaceholderImageRecordsForOutput:(NSArray *)output
{
    // Prepare placeholder Image records.
    [[ArticleDataContextSingleton sharedInstance].mainContext performBlockAndWait:^(){
        for (NSDictionary *page in output) {
            // If url thumb found, prepare a core data Image object so URLCache
            // will know this is an image to intercept.
            NSDictionary *thumbData = page[@"thumbnail"];
            if (thumbData) {
                NSString *src = thumbData[@"source"];
                NSNumber *height = thumbData[@"height"];
                NSNumber *width = thumbData[@"width"];
                if (src && height && width) {
                    [self insertPlaceHolderImageEntityIntoContext: [ArticleDataContextSingleton sharedInstance].mainContext
                                                  forImageWithUrl: src
                                                            width: width
                                                           height: height];
                }
            }
        }
        NSError *error = nil;
        [[ArticleDataContextSingleton sharedInstance].mainContext save:&error];
    }];
}

-(void)insertPlaceHolderImageEntityIntoContext: (NSManagedObjectContext *)context
                               forImageWithUrl: (NSString *)url
                                         width: (NSNumber *)width
                                        height: (NSNumber *)height
{
    Image *existingImage = (Image *)[context getEntityForName: @"Image" withPredicateFormat:@"sourceUrl == %@", [url getUrlWithoutScheme]];
    // If there's already an image record for this exact url, don't create another one!!!
    if (!existingImage) {
        Image *image = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:context];
        image.imageData = [NSEntityDescription insertNewObjectForEntityForName:@"ImageData" inManagedObjectContext:context];
        image.imageData.data = [[NSData alloc] init];
        image.dataSize = @(image.imageData.data.length);
        image.fileName = [url lastPathComponent];
        image.fileNameNoSizePrefix = [image.fileName getWikiImageFileNameWithoutSizePrefix];
        image.extension = [url pathExtension];
        image.imageDescription = nil;
        image.sourceUrl = [url getUrlWithoutScheme];
        image.dateRetrieved = [NSDate date];
        image.dateLastAccessed = [NSDate date];
        image.width = @(width.integerValue);
        image.height = @(height.integerValue);
        image.mimeType = [image.extension getImageMimeTypeForExtension];
    }
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC'ING ACCT CREATION TOKEN FETCHER!");
}
*/

@end
