//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "KeychainCredentials.h"
#import "ZeroConfigState.h"

@class KeychainCredentials;

@interface SessionSingleton : NSObject

+ (SessionSingleton*)sharedInstance;

// Persistent settings and credentials
@property (strong, nonatomic) KeychainCredentials* keychainCredentials;
@property (strong, nonatomic) ZeroConfigState* zeroConfigState;
@property (nonatomic) BOOL shouldSendUsageReports;

// Data access objects
@property (strong, nonatomic, readonly) MWKDataStore* dataStore;
@property (strong, nonatomic, readonly) MWKUserDataStore* userDataStore;

/**
 *  Set the language for searches.
 *  Setting this will update the searchSite with the new language.
 *  Initial value will be the device language.
 *
 *  @param language The new language for searches
 */
- (void)setSearchLanguage:(NSString*)language;

/**
 *  The search site. This set automatically when setting the search language.
 *
 *  Initial value will be the site for the device language.
 *  This will never be nil.
 */
@property (strong, nonatomic, readonly) MWKSite* searchSite;

/**
 *  Main Article Title for current search site and language
 */
@property (nonatomic, strong, readonly) MWKTitle* mainArticleTitle;

/**
 *  Main Article Title for the specified language code
 *
 *  @param site The site to use for the main article
 *  @param code The language for the main article
 *
 *  @return The main article
 */
- (MWKTitle*)mainArticleTitleForSite:(MWKSite*)site languageCode:(NSString*)code;

/**
 *  Determine if an article is "a" main article.
 *  This will return yes if the article is the main article for the given article's domain.
 *  This is agnostic to the searchSite. For example:
 *  This will return YES for the french main article even if the searchSite is set to english.
 *
 *  @param article The article to test
 *
 *  @return Yes if the article is a main article, otherwise no
 */
- (BOOL)articleIsAMainArticle:(MWKArticle*)article;

/**
 *  The current article's site. This set automatically when setting the current article.
 *
 *  Initial value will be the site for the device language.
 *  (since the first page shown is the main page for the device language)
 *  On subsequent launches value will be the site of the last loaded article.
 *  This will never be nil.
 *
 */
@property (strong, nonatomic, readonly) MWKSite* currentArticleSite;

/**
 *  The current artcle. Set this when an article is loaded.
 *
 *  Initial value will be main page for the device language.
 *  On subsequent launches value will be last loaded article.
 *  This will never be nil.
 *
 *  //TODO: This tightly coupled to the webview controller
 *  article display logic. Refactor to a specific article service.
 */
@property (nonatomic, strong) MWKArticle* currentArticle;



@property (strong, nonatomic, readonly) NSString* searchApiUrl;

@property (nonatomic) BOOL fallback;

- (NSURL*)urlForLanguage:(NSString*)language;


// Search and Nearby fetch thumbnails which are tossed in the tmp dir so we
// don't have to worry about pruning. However, when we then load an article
// we need to yank out the thumb for that article so it can be saved in the
// data store. This dictionary gives us an easy place to see what temp thumb
// file is known to be associated with an article title.
@property (strong, nonatomic) NSMutableDictionary* titleToTempDirThumbURLMap;

@end
