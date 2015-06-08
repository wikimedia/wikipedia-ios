//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

/*
   Note about langlinks:
   This returns info about *any* langlinks found on a page, which might not always directly lead to a
   translation of the current page. Specifically, main pages have lots of langlinks to other wikis' main pages. As such,
   they will all be returned in a lanklinks query[0], giving the client the (arguably false) impression that the EN wiki
   main page has been translated into other languages.
 */

typedef NS_ENUM (NSInteger, LanguageLinksFetchErrorType) {
    LANGUAGE_LINKS_FETCH_ERROR_UNKNOWN = 0,
    LANGUAGE_LINKS_FETCH_ERROR_API     = 1
};

@class AFHTTPRequestOperationManager;

@interface LanguageLinksFetcher : FetcherBase

@property (strong, nonatomic, readonly) MWKTitle* title;
@property (strong, nonatomic, readonly) NSArray* allLanguages;

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
- (instancetype)initAndFetchLanguageLinksForPageTitle:(MWKTitle*)title
                                         allLanguages:(NSArray*)allLanguages
                                          withManager:(AFHTTPRequestOperationManager*)manager
                                   thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate;
@end
