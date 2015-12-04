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

extern NSString* const WMFSearchLanguageDidChangeNotification;

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

@property (strong, nonatomic, readonly) NSString* searchApiUrl;

@property (nonatomic) BOOL fallback WMF_TECH_DEBT_DEPRECATED; //< Is this really necessary?

- (NSString*)searchApiUrlForLanguage:(NSString*)language WMF_TECH_DEBT_DEPRECATED_MSG("Use -[MWKSite apiEndpoint] instead.");
- (NSString*)searchLanguage;

- (NSURL*)urlForLanguage:(NSString*)language WMF_TECH_DEBT_DEPRECATED_MSG("Use -[MWKSite apiEndpoint] instead.");

@end
