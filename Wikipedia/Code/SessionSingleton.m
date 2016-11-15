#import "SessionSingleton.h"
#import <WMFModel/WMFModel-Swift.h>

@interface SessionSingleton ()

@property (strong, nonatomic, readwrite) MWKDataStore *dataStore;

@property (strong, nonatomic) WMFAssetsFile *mainPages;

@end

@implementation SessionSingleton

#pragma mark - Setup

static SessionSingleton *sharedInstance;

+ (SessionSingleton *)sharedInstance {
    static dispatch_once_t onceToken;
    static SessionSingleton *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        WMFURLCache *urlCache = [[WMFURLCache alloc] initWithMemoryCapacity:MegabytesToBytes(64)
                                                               diskCapacity:MegabytesToBytes(128)
                                                                   diskPath:nil];
        [NSURLCache setSharedURLCache:urlCache];
        
        self.zeroConfigurationManager = [[WMFZeroConfigurationManager alloc] init];
        
        _currentArticleSiteURL = [self lastKnownSite];
    }
    return self;
}

#pragma mark - Site

- (void)setCurrentArticleSiteURL:(NSURL *)currentArticleSiteURL {
    NSParameterAssert(currentArticleSiteURL);
    if (!currentArticleSiteURL || [_currentArticleSiteURL isEqual:currentArticleSiteURL]) {
        return;
    }
    _currentArticleSiteURL = [currentArticleSiteURL wmf_siteURL];
    [[NSUserDefaults wmf_userDefaults] setObject:currentArticleSiteURL.wmf_language forKey:@"CurrentArticleDomain"];
    [[NSUserDefaults wmf_userDefaults] synchronize];
}

#pragma mark - Last known/loaded

- (NSURL *)lastKnownSite {
    return [NSURL wmf_URLWithDefaultSiteAndlanguage:[[NSUserDefaults wmf_userDefaults] objectForKey:@"CurrentArticleDomain"]];
}

#pragma mark - Language URL

- (NSURL *)urlForLanguage:(NSString *)language {
    return self.fallback ? [NSURL wmf_desktopAPIURLForURL:[NSURL wmf_URLWithDefaultSiteAndlanguage:language]] : [NSURL wmf_mobileAPIURLForURL:[NSURL wmf_URLWithDefaultSiteAndlanguage:language]];
}

#pragma mark - Usage Reports

- (BOOL)shouldSendUsageReports {
    return [[NSUserDefaults wmf_userDefaults] wmf_sendUsageReports];
}

- (void)setShouldSendUsageReports:(BOOL)sendUsageReports {
    if (sendUsageReports == [self shouldSendUsageReports]) {
        return;
    }
    [[NSUserDefaults wmf_userDefaults] wmf_setSendUsageReports:sendUsageReports];
    [[QueuesSingleton sharedInstance] reset];
}

@end
