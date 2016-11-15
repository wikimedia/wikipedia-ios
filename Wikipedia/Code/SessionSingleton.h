#import <Foundation/Foundation.h>
#import "MWKHistoryEntry.h"
#import "WMFZeroConfigurationManager.h"

@class MWKArticle;

@interface SessionSingleton : NSObject

+ (SessionSingleton *)sharedInstance;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore NS_UNAVAILABLE;

// Persistent settings and credentials
@property (strong, nonatomic) WMFZeroConfigurationManager *zeroConfigurationManager;
@property (nonatomic) BOOL shouldSendUsageReports;

/**
 *  The current article's site. This set automatically when setting the current article.
 *
 *  Initial value will be the site for the device language.
 *  (since the first page shown is the main page for the device language)
 *  On subsequent launches value will be the site of the last loaded article.
 *  This will never be nil.
 *
 */
@property (strong, nonatomic) NSURL *currentArticleSiteURL;

@property (nonatomic) BOOL fallback WMF_TECH_DEBT_DEPRECATED; ///< Is this really necessary?

- (NSURL *)urlForLanguage:(NSString *)language WMF_TECH_DEBT_DEPRECATED_MSG("Use -[NSURL apiEndpoint] instead.");

@end
