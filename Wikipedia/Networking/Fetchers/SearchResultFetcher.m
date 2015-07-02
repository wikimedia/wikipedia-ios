//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SearchResultFetcher.h"
#import <AFNetworking/AFHTTPRequestOperation.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"
#import "NSString+Extras.h"
#import "WikipediaAppUtils.h"

#define LEAD_IMAGE_WIDTH (([UIScreen mainScreen].scale > 1) ? 640 : 320)

@interface SearchResultFetcher ()

@property (strong, nonatomic) NSString* domain;
@property (nonatomic, strong) NSString* searchTerm;
@property (nonatomic) SearchType searchType;
@property (nonatomic) SearchReason searchReason;

@property (nonatomic, assign) NSUInteger maxSearchResults;

@property (nonatomic, strong) NSArray* searchResults;
@property (nonatomic, strong) NSString* searchSuggestion;

@property (nonatomic, strong) NSRegularExpression* spaceCollapsingRegex;
@property (nonatomic, strong) NSString* language;

@end

@implementation SearchResultFetcher

- (instancetype)initAndSearchForTerm:(NSString*)searchTerm
                          searchType:(SearchType)searchType
                        searchReason:(SearchReason)searchReason
                            language:(NSString*)language
                          maxResults:(NSUInteger)maxResults
                         withManager:(AFHTTPRequestOperationManager*)manager
                  thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate {
    self = [super init];
    if (self) {
        [self searchForTerm:searchTerm searchType:searchType searchReason:searchReason language:language maxResults:maxResults withManager:manager thenNotifyDelegate:delegate];
    }
    return self;
}

- (AFHTTPRequestOperation*)searchForTerm:(NSString*)searchTerm
                              searchType:(SearchType)searchType
                            searchReason:(SearchReason)searchReason
                                language:(NSString*)language
                              maxResults:(NSUInteger)maxResults
                             withManager:(AFHTTPRequestOperationManager*)manager
                      thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate {
    self.searchResults         = @[];
    self.searchSuggestion      = nil;
    self.searchTerm            = searchTerm ? searchTerm : @"";
    self.searchType            = searchType;
    self.searchReason          = searchReason;
    self.language              = language;
    self.fetchFinishedDelegate = delegate;
    self.maxSearchResults      = maxResults;
    self.spaceCollapsingRegex  =
        [NSRegularExpression regularExpressionWithPattern:@"\\s{2,}+" options:NSRegularExpressionCaseInsensitive error:nil];
    return [self searchWithManager:manager];
}

- (AFHTTPRequestOperation*)searchWithManager:(AFHTTPRequestOperationManager*)manager {
    NSString* url = [[SessionSingleton sharedInstance] searchApiUrlForLanguage:self.language];

    NSDictionary* params = [self getParams];

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    return [manager GET:url parameters:params success:^(AFHTTPRequestOperation* operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        // Convert the raw NSData response to a dictionary.
        responseObject = [self dictionaryFromDataResponse:responseObject];

        // NSLog(@"\n\nDATA RETRIEVED = %@\n\n", responseObject);

        // Handle case where response is received, but API reports error.
        NSError* error = nil;
        if (responseObject[@"error"]) {
            NSMutableDictionary* errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain:@"Search Result Fetcher"
                                        code:SEARCH_RESULT_ERROR_API
                                    userInfo:errorDict];
        }

        if (!error) {
            self.searchResults = [self getSanitizedResponse:responseObject];
            self.searchSuggestion = [self getSearchSuggestionFromResponse:responseObject];
        }

        [self finishWithError:error
                  fetchedData:self.searchResults];
    } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        //NSLog(@"CAPTCHA RESETTER FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError:error
                  fetchedData:nil];
    }];
}

- (NSDictionary*)getParams {
    switch (self.searchType) {
        case SEARCH_TYPE_TITLES:
            // Based on https://gerrit.wikimedia.org/r/#/c/158011/2/javascripts/modules/search/SearchApi.js
            return @{
                       @"action": @"query",
                       @"generator": @"prefixsearch",
                       @"gpssearch": self.searchTerm,
                       @"gpsnamespace": @0,
                       @"gpslimit": @(self.maxSearchResults),
                       @"prop": @"pageterms|pageimages",
                       @"piprop": @"thumbnail",
                       @"wbptterms": @"description",
                       @"pithumbsize": @(LEAD_IMAGE_WIDTH),
                       @"pilimit": @(self.maxSearchResults),
                       // -- Parameters causing prefix search to efficiently return suggestion.
                       @"list": @"search",
                       @"srsearch": self.searchTerm,
                       @"srnamespace": @0,
                       @"srwhat": @"text",
                       @"srinfo": @"suggestion",
                       @"srprop": @"",
                       @"sroffset": @0,
                       @"srlimit": @1,
//                       @"redirects": @1,
                       // --
                       @"continue": @"",
                       @"format": @"json"
            };
            break;

        case SEARCH_TYPE_IN_ARTICLES:
            return @{
                       @"action": @"query",
                       @"prop": @"pageterms|pageimages",
                       @"wbptterms": @"description",
                       @"generator": @"search",
                       @"gsrsearch": self.searchTerm,
                       @"gsrnamespace": @0,
                       @"gsrwhat": @"text",
                       @"gsrinfo": @"",
                       @"gsrprop": @"redirecttitle",
                       @"gsroffset": @0,
                       @"gsrlimit": @(self.maxSearchResults),
                       @"piprop": @"thumbnail",
                       @"pithumbsize": @(LEAD_IMAGE_WIDTH),
                       @"pilimit": @(self.maxSearchResults),
                       @"continue": @"",
                       @"format": @"json"
//                       @"redirects": @1,
            };
            break;
        default:
            return @{};
            break;
    }
}

- (NSArray*)getSanitizedResponse:(NSDictionary*)rawResponse {
    // Make output array contain just dictionaries for each result.
    NSMutableArray* output = @[].mutableCopy;
    if (rawResponse.count > 0) {
        NSDictionary* query = (NSDictionary*)rawResponse[@"query"];
        if (query) {
            NSDictionary* pages = (NSDictionary*)query[@"pages"];

            NSSortDescriptor* sortByIndex = [NSSortDescriptor sortDescriptorWithKey:@"index"
                                                                          ascending:YES];
            if (!pages) {
                return output;
            }

            NSArray* pagesOrdered = [pages.allValues sortedArrayUsingDescriptors:@[sortByIndex]];

            for (NSDictionary* prefixPage in pagesOrdered) {
                // Use "dictionaryWithDictionary" because it creates
                // a deep mutable copy of the __NSCFDictionary.
                NSMutableDictionary* mutablePrefixPage =
                    [NSMutableDictionary dictionaryWithDictionary:prefixPage];

                NSString* snippet = prefixPage[@"snippet"] ? prefixPage[@"snippet"] : @"";
                // Strip HTML and collapse repeating spaces in snippet.
                if (snippet.length > 0) {
                    snippet = [snippet wmf_stringByRemovingHTML];
                    snippet = [self.spaceCollapsingRegex stringByReplacingMatchesInString:snippet
                                                                                  options:0
                                                                                    range:NSMakeRange(0, [snippet length])
                                                                             withTemplate:@" "];
                }
                mutablePrefixPage[@"snippet"] = snippet;

                mutablePrefixPage[@"title"] = mutablePrefixPage[@"title"] ? [mutablePrefixPage[@"title"] wmf_stringByReplacingUndrescoresWithSpaces] : @"";

                mutablePrefixPage[@"searchtype"] = @(self.searchType);
                mutablePrefixPage[@"searchterm"] = self.searchTerm;

                NSString* description = @"";
                NSDictionary* terms   = mutablePrefixPage[@"terms"];
                if (terms && terms[@"description"]) {
                    NSArray* descriptions = terms[@"description"];
                    if (descriptions && (descriptions.count > 0)) {
                        description = descriptions[0];
                        description = [description wmf_stringByCapitalizingFirstCharacter];
                    }
                    [mutablePrefixPage removeObjectForKey:@"terms"];
                }
                mutablePrefixPage[@"description"] = description;

                if (mutablePrefixPage) {
                    [output addObject:mutablePrefixPage];
                }
            }
        }
    }

    return output;
}

- (NSString*)getSearchSuggestionFromResponse:(NSDictionary*)rawResponse {
    NSString* output = nil;
    if (rawResponse.count > 0) {
        NSDictionary* query = (NSDictionary*)rawResponse[@"query"];
        if (query) {
            NSDictionary* searchinfo = (NSDictionary*)query[@"searchinfo"];
            if (searchinfo[@"suggestion"]) {
                NSString* suggestion = searchinfo[@"suggestion"];
                if ([suggestion isKindOfClass:[NSString class]] && suggestion.length > 0) {
                    output = suggestion;
                }
            }
        }
    }
    return output;
}

/*
   -(void)dealloc
   {
    NSLog(@"DEALLOC'ING ACCT CREATION TOKEN FETCHER!");
   }
 */

@end
