//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM(NSInteger, LanguageLinksFetchErrorType) {
    LANGUAGE_LINKS_FETCH_ERROR_UNKNOWN = 0,
    LANGUAGE_LINKS_FETCH_ERROR_API = 1
};

@class AFHTTPRequestOperationManager;

@interface LanguageLinksFetcher : FetcherBase

@property (strong, nonatomic, readonly) MWKTitle *title;
@property (strong, nonatomic, readonly) NSArray *allLanguages;

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
-(instancetype)initAndFetchLanguageLinksForPageTitle: (MWKTitle *)title
                                        allLanguages: (NSArray *)allLanguages
                                         withManager: (AFHTTPRequestOperationManager *)manager
                                  thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate;
@end
