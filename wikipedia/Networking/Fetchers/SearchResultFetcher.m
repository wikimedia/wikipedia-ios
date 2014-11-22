//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SearchResultFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"
#import "NSString+Extras.h"
#import "WikipediaAppUtils.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "NSManagedObjectContext+SimpleFetch.h"

#define GET_SNIPPET_WITH_IN_ARTICLE_RESULTS YES

@interface SearchResultFetcher()

@property (strong, nonatomic) NSString *domain;
@property (nonatomic, strong) NSString *searchTerm;
@property (nonatomic) SearchType searchType;
@property (nonatomic) SearchReason searchReason;

@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) NSString *searchSuggestion;

@property (nonatomic, strong) NSRegularExpression *spaceCollapsingRegex;

@end

@implementation SearchResultFetcher

-(instancetype)initAndSearchForTerm: (NSString *)searchTerm
                         searchType: (SearchType)searchType
                       searchReason: (SearchReason)searchReason
                        withManager: (AFHTTPRequestOperationManager *)manager
                 thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.searchResults = @[];
        self.searchSuggestion = nil;
        self.searchTerm = searchTerm ? searchTerm : @"";
        self.searchType = searchType;
        self.searchReason = searchReason;
        self.fetchFinishedDelegate = delegate;
        self.spaceCollapsingRegex =
            [NSRegularExpression regularExpressionWithPattern:@"\\s{2,}+" options:NSRegularExpressionCaseInsensitive error:nil];
        [self searchWithManager:manager];
    }
    return self;
}

- (void)searchWithManager:(AFHTTPRequestOperationManager *)manager
{
    NSString *url = [SessionSingleton sharedInstance].searchApiUrl;

    NSDictionary *params = [self getParams];
    
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
        
        // NSLog(@"\n\nDATA RETRIEVED = %@\n\n", responseObject);
        
        // Handle case where response is received, but API reports error.
        NSError *error = nil;
        if (responseObject[@"error"]){
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain: @"Search Result Fetcher"
                                        code: SEARCH_RESULT_ERROR_API
                                    userInfo: errorDict];
        }

        if (!error) {
            self.searchResults = [self getSanitizedResponse:responseObject];
            self.searchSuggestion = [self getSearchSuggestionFromResponse:responseObject];
        }

        // If no matches set error.
        if (self.searchResults.count == 0) {
            NSMutableDictionary *errorDict = @{}.mutableCopy;
            
            errorDict[NSLocalizedDescriptionKey] = MWLocalizedString(@"search-no-matches", nil);
            
            // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
            error = [NSError errorWithDomain:@"Search Result Fetcher" code:SEARCH_RESULT_ERROR_NO_MATCHES userInfo:errorDict];
        }else{
            [self preparePlaceholderImageRecordsForSearchResults:self.searchResults];
        }

        [self finishWithError: error
                  fetchedData: nil];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        //NSLog(@"CAPTCHA RESETTER FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError: error
                  fetchedData: nil];
    }];
}

-(NSDictionary *)getParams
{
    switch (self.searchType) {
        case SEARCH_TYPE_TITLES:
            // Based on https://gerrit.wikimedia.org/r/#/c/158011/2/javascripts/modules/search/SearchApi.js
            return @{
                     @"action": @"query",
                     @"generator": @"prefixsearch",
                     @"gpssearch": self.searchTerm,
                     @"gpsnamespace": @0,
                     @"gpslimit": @(SEARCH_MAX_RESULTS),
                     @"prop": @"pageprops|pageimages",
                     @"ppprop": @"wikibase_item",
                     @"piprop": @"thumbnail",
                     @"pithumbsize" : @(SEARCH_THUMBNAIL_WIDTH),
                     @"pilimit": @(SEARCH_MAX_RESULTS),
                     @"list": @"prefixsearch",
                     @"pssearch": self.searchTerm,
                     @"pslimit": @(SEARCH_MAX_RESULTS),
                     @"psnamespace": @0,
                     @"format": @"json"
                     };
            break;
            
        case SEARCH_TYPE_IN_ARTICLES:
            return @{
                     @"action": @"query",
                     @"prop": @"pageprops|pageimages",
                     @"ppprop": @"wikibase_item",
                     @"generator": @"search",
                     @"gsrsearch": self.searchTerm,
                     @"gsrnamespace": @0,
                     @"gsrwhat": @"text",
                     @"gsrinfo": @"",
                     @"gsrprop": @"redirecttitle",
                     @"gsroffset": @0,
                     @"gsrlimit": @(SEARCH_MAX_RESULTS),
                     @"list": @"search",
                     @"srsearch": self.searchTerm,
                     @"srnamespace": @0,
                     @"srwhat": @"text",
                     @"srinfo": @"suggestion",
                     @"srprop": (GET_SNIPPET_WITH_IN_ARTICLE_RESULTS ? @"snippet" : @""),
                     @"sroffset": @0,
                     @"srlimit": @(SEARCH_MAX_RESULTS),
                     @"piprop": @"thumbnail",
                     @"pithumbsize" : @(SEARCH_THUMBNAIL_WIDTH),
                     @"pilimit": @(SEARCH_MAX_RESULTS),
                     @"format": @"json"
                     };
            break;
        default:
            return @{};
            break;
    }
}

-(NSArray *)getSanitizedResponse:(NSDictionary *)rawResponse
{
    // Make output array contain just dictionaries for each result.
    NSMutableArray *output = @[].mutableCopy;
    if (rawResponse.count > 0) {
        NSDictionary *query = (NSDictionary *)rawResponse[@"query"];
        if (query) {
        
            NSDictionary *pages = (NSDictionary *)query[@"pages"];
            
            NSString *searchTypeString = (self.searchType == SEARCH_TYPE_TITLES) ? @"prefixsearch" : @"search";
            
            NSArray *pagesOrdered = (NSArray *)query[searchTypeString];
            
            if (pages && pagesOrdered) {

                // Loop through the prefixsearch results (rather than the pages results) so we maintain correct order.
                // Based on https://gerrit.wikimedia.org/r/#/c/158011/2/javascripts/modules/search/SearchApi.js
                for (NSDictionary *prefixPage in pagesOrdered) {

                    // "dictionaryWithDictionary" used because it creates a deep mutable copy of the __NSCFDictionary.
                    NSMutableDictionary *mutablePrefixPage = [NSMutableDictionary dictionaryWithDictionary:prefixPage];
                    
                    // Add thumb placeholder.
                    mutablePrefixPage[@"thumbnail"] = @{}.mutableCopy;
                    
                    NSString *snippet = prefixPage[@"snippet"] ? prefixPage[@"snippet"] : @"";
                    // Strip HTML and collapse repeating spaces in snippet.
                    if (snippet.length > 0) {
                        snippet = [snippet getStringWithoutHTML];
                        snippet = [self.spaceCollapsingRegex stringByReplacingMatchesInString: snippet
                                                                                      options: 0
                                                                                        range: NSMakeRange(0, [snippet length])
                                                                                 withTemplate: @" "];
                    }
                    mutablePrefixPage[@"snippet"] = snippet;

                    // Grab thumbnail and pageprops info from non-prefixsearch result for this pageid.
                    for (NSDictionary *page in pages.allValues) {

                        // Grab thumbnail info.
                        id pageTitle = page[@"title"];
                        id prefixPageTitle = mutablePrefixPage[@"title"];
                        if (pageTitle && prefixPageTitle && [prefixPageTitle isKindOfClass:[NSString class]] && [pageTitle isKindOfClass:[NSString class]]){
                            if ([prefixPageTitle isEqualToString:pageTitle]) {
                                
                                if (page[@"thumbnail"]){
                                    mutablePrefixPage[@"thumbnail"] = page[@"thumbnail"];
                                }
                                
                                // Grab wiki data id.
                                id pageprops = page[@"pageprops"];
                                if (pageprops && [pageprops isKindOfClass:[NSDictionary class]]){
                                    if (pageprops[@"wikibase_item"]){
                                        mutablePrefixPage[@"wikibase_item"] = pageprops[@"wikibase_item"];
                                    }
                                }
                                
                                break;
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

-(NSString *)getSearchSuggestionFromResponse:(NSDictionary *)rawResponse
{
    NSString *output = nil;
    if (rawResponse.count > 0) {
        NSDictionary *query = (NSDictionary *)rawResponse[@"query"];
        if (query) {
            NSDictionary *searchinfo = (NSDictionary *)query[@"searchinfo"];
            if (searchinfo[@"suggestion"]) {
                NSString *suggestion = searchinfo[@"suggestion"];
                if ([suggestion isKindOfClass:[NSString class]] && suggestion.length > 0) {
                    output = suggestion;
                }
            }
        }
    }
    return output;
}

#pragma mark Core data Image record placeholder for thumbnail (so they get cached)

-(void)preparePlaceholderImageRecordsForSearchResults:(NSArray *)searchResults
{
    // Prepare placeholder Image records.
    [[ArticleDataContextSingleton sharedInstance].mainContext performBlockAndWait:^(){
        for (NSDictionary *page in searchResults) {
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
