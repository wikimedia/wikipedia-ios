#import <Foundation/Foundation.h>
#import "MWKHistoryEntry.h"
#import "WMFZeroConfigurationManager.h"

@class MWKDataStore;
@class MWKArticle;

@interface SessionSingleton : NSObject

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;

+ (SessionSingleton *)sharedInstance;

// Persistent settings and credentials
@property (strong, nonatomic) WMFZeroConfigurationManager *zeroConfigurationManager;
@property (nonatomic) BOOL shouldSendUsageReports;

// Data access objects
@property (strong, nonatomic, readonly) MWKDataStore *dataStore;

/**
 *  The current article's site. This set automatically when setting the current article.
 *
 *  Initial value will be the site for the device language.
 *  (since the first page shown is the main page for the device language)
 *  On subsequent launches value will be the site of the last loaded article.
 *  This will never be nil.
 *
 */
@property (strong, nonatomic, readonly) NSURL *currentArticleSiteURL;

/**
 *  The current article. Set this when an article is loaded.
 *
 *  Initial value will be main page for the device language.
 *  On subsequent launches value will be last loaded article.
 *  This will never be nil.
 *
 *  //TODO: This tightly coupled to the webview controller
 *  article display logic. Refactor to a specific article service.
 */
@property (nonatomic, strong) MWKArticle *currentArticle;

@property (nonatomic) BOOL fallback WMF_TECH_DEBT_DEPRECATED; ///< Is this really necessary?

- (NSURL *)urlForLanguage:(NSString *)language WMF_TECH_DEBT_DEPRECATED_MSG("Use -[NSURL apiEndpoint] instead.");

@end
