//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "MWKHistoryEntry.h"
#import "KeychainCredentials.h"
#import "ZeroConfigState.h"

@class KeychainCredentials;
@class MWKDataStore;
@class MWKUserDataStore;
@class MWKSite;
@class MWKTitle;
@class MWKArticle;

@interface SessionSingleton : NSObject

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

+ (SessionSingleton*)sharedInstance;

// Persistent settings and credentials
@property (strong, nonatomic) KeychainCredentials* keychainCredentials;
@property (strong, nonatomic) ZeroConfigState* zeroConfigState;
@property (nonatomic) BOOL shouldSendUsageReports;

// Data access objects
@property (strong, nonatomic, readonly) MWKDataStore* dataStore;
@property (strong, nonatomic, readonly) MWKUserDataStore* userDataStore;

/**
 * Language code used as a component in the Wikipedia host name: <code>searchLanguage + "wikipedia.org"</code>.
 * @note This is usually RFC 639-x or BCP-47, but not always. Some language wikis either don't have a standard language
 *       code or are another weird edge case.
 */
@property (copy, nonatomic) NSString* searchLanguage;


/// @return Site initialized with @c searchLanguage and the default domain.
- (MWKSite*)searchSite;

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


/**
 *  The way the current article was discovered.
 *  Same caviates as the currentArticle
 */
@property (nonatomic, assign) MWKHistoryDiscoveryMethod currentArticleDiscoveryMethod;

@property (strong, nonatomic, readonly) NSString* searchApiUrl;

@property (nonatomic) BOOL fallback __deprecated; //< Is this really necessary?

- (NSString*)searchApiUrlForLanguage:(NSString*)language __deprecated_msg("Use -[MWKSite apiEndpoint] instead.");
- (NSString*)searchLanguage;

- (NSURL*)urlForLanguage:(NSString*)language __deprecated_msg("Use -[MWKSite apiEndpoint] instead.");

// Search and Nearby fetch thumbnails which are tossed in the tmp dir so we
// don't have to worry about pruning. However, when we then load an article
// we need to yank out the thumb for that article so it can be saved in the
// data store. This dictionary gives us an easy place to see what temp thumb
// file is known to be associated with an article title.
@property (strong, nonatomic) NSMutableDictionary* titleToTempDirThumbURLMap;

/**
 * Toggle save state of the current article, if there is one.
 * @param error Out-param of any error that occurred while toggling save state and saving.
 * @return A boxed boolean indicating the new save state of `currentArticle` or `nil` if an error occured.
 * @see -[MWKSavedPageList toggleSaveStateForTitle:error:]
 */
- (NSNumber*)toggleSaveStateForCurrentArticle:(NSError* __autoreleasing*)error;

@end
