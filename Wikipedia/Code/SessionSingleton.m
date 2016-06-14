//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SessionSingleton.h"
#import "WikipediaAppUtils.h"
#import "QueuesSingleton.h"
#import "WMFURLCache.h"
#import "WMFAssetsFile.h"
#import "MediaWikiKit.h"
#import "Wikipedia-Swift.h"
#import "LoginTokenFetcher.h"
#import "AccountLogin.h"
#import "AFHTTPSessionManager+WMFCancelAll.h"
#import "NSHTTPCookieStorage+WMFCloneCookie.h"
#import "MWKLanguageLinkController.h"
#import "WMFAuthManagerInfoFetcher.h"
#import "WMFAuthManagerInfo.h"


@interface SessionSingleton ()<FetchFinishedDelegate>

@property (strong, nonatomic, readwrite) MWKDataStore* dataStore;

@property (strong, nonatomic) WMFAssetsFile* mainPages;

@property (strong, nonatomic, readwrite) MWKSite* currentArticleSite;

@property (strong, nonatomic) MWKTitle* currentArticleTitle;

@property (strong, nonatomic) WMFAuthManagerInfoFetcher* authManagerInfoFetcher;
@property (strong, nonatomic) WMFAuthManagerInfo* authManagerInfo;

@end

@implementation SessionSingleton
@synthesize currentArticleSite = _currentArticleSite;
@synthesize currentArticle     = _currentArticle;

#pragma mark - Setup

+ (SessionSingleton*)sharedInstance {
    static dispatch_once_t onceToken;
    static SessionSingleton* sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init {
    return [self initWithDataStore:[[MWKDataStore alloc] initWithBasePath:[[MWKDataStore class] mainDataStorePath]]];
}

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    self = [super init];
    if (self) {
        [WikipediaAppUtils copyAssetsFolderToAppDataDocuments];

        WMFURLCache* urlCache = [[WMFURLCache alloc] initWithMemoryCapacity:MegabytesToBytes(64)
                                                               diskCapacity:MegabytesToBytes(128)
                                                                   diskPath:nil];
        [NSURLCache setSharedURLCache:urlCache];

        self.keychainCredentials         = [[KeychainCredentials alloc] init];
        self.zeroConfigState             = [[ZeroConfigState alloc] init];
        self.zeroConfigState.disposition = NO;

        self.dataStore = dataStore;

        _currentArticleSite = [self lastKnownSite];
    }
    return self;
}

- (MWKUserDataStore*)userDataStore {
    return self.dataStore.userDataStore;
}

#pragma mark - Site

- (void)setCurrentArticleSite:(MWKSite*)site {
    NSParameterAssert(site);
    if (!site || [_currentArticleSite isEqual:site]) {
        return;
    }
    _currentArticleSite = site;
    [[NSUserDefaults standardUserDefaults] setObject:site.language forKey:@"CurrentArticleDomain"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Article

- (void)setCurrentArticleTitle:(MWKTitle*)currentArticle {
    NSParameterAssert(currentArticle);
    if (!_currentArticle || [_currentArticle isEqual:currentArticle]) {
        return;
    }
    _currentArticleTitle = currentArticle;
    [[NSUserDefaults standardUserDefaults] setObject:currentArticle.dataBaseKey forKey:@"CurrentArticleTitle"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setCurrentArticle:(MWKArticle*)currentArticle {
    if (!currentArticle || [_currentArticle isEqual:currentArticle]) {
        return;
    }
    _currentArticle          = currentArticle;
    self.currentArticleTitle = currentArticle.title;
    self.currentArticleSite  = currentArticle.site;
}

- (MWKArticle*)currentArticle {
    if (!_currentArticle) {
        self.currentArticle = [self lastLoadedArticle];
    }
    return _currentArticle;
}

#pragma mark - Last known/loaded

- (MWKSite*)lastKnownSite {
    return [MWKSite siteWithLanguage:[[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentArticleDomain"]];
}

- (MWKTitle*)lastLoadedTitle {
    MWKSite* lastKnownSite = [self lastKnownSite];
    NSString* titleText    = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentArticleTitle"];
    if (!titleText.length) {
        return nil;
    }
    MWKTitle* title = [lastKnownSite titleWithString:titleText];
    return title;
}

- (MWKArticle*)lastLoadedArticle {
    MWKTitle* lastLoadedTitle = [self lastLoadedTitle];
    if (!lastLoadedTitle) {
        return nil;
    }
    MWKArticle* article = [self.dataStore articleWithTitle:lastLoadedTitle];
    return article;
}

#pragma mark - Language URL

- (NSURL*)urlForLanguage:(NSString*)language {
    NSString* endpoint = self.fallback ? @"" : @".m";
    MWKSite* site      = [MWKSite siteWithLanguage:language];
    return [NSURL URLWithString:
            [NSString stringWithFormat:@"https://%@%@.%@/w/api.php", language, endpoint, site.domain]];
}

#pragma mark - Usage Reports

- (BOOL)shouldSendUsageReports {
    return [[NSUserDefaults standardUserDefaults] wmf_sendUsageReports];
}

- (void)setShouldSendUsageReports:(BOOL)sendUsageReports {
    if (sendUsageReports == [self shouldSendUsageReports]) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] wmf_setSendUsageReports:sendUsageReports];
    [[QueuesSingleton sharedInstance] reset];
}

- (void)autoLogin {
    if (self.keychainCredentials.userName == nil || self.keychainCredentials.password == nil) {
        return;
    }

    self.authManagerInfoFetcher = [[WMFAuthManagerInfoFetcher alloc] init];

    [self.authManagerInfoFetcher fetchAuthManagerLoginAvailableForSite:[[MWKLanguageLinkController sharedInstance] appLanguage].site].then(^(WMFAuthManagerInfo* info){
        self.authManagerInfo = info;
        [[QueuesSingleton sharedInstance].loginFetchManager wmf_cancelAllTasksWithCompletionHandler:^{
            (void)[[LoginTokenFetcher alloc] initAndFetchTokenForDomain:[[MWKLanguageLinkController sharedInstance] appLanguage].languageCode
                                                               userName:self.keychainCredentials.userName
                                                               password:self.keychainCredentials.password
                                                         useAuthManager:(info != nil) withManager:[QueuesSingleton sharedInstance].loginFetchManager
                                                     thenNotifyDelegate:self];
        }];
    });
}

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError*)error {
    if ([sender isKindOfClass:[LoginTokenFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                (void)[[AccountLogin alloc] initAndLoginForDomain:[sender domain]
                                                         userName:[sender userName]
                                                         password:[sender password]
                                                            token:[sender token]
                                                   useAuthManager:(self.authManagerInfo != nil)
                                                      withManager:[QueuesSingleton sharedInstance].loginFetchManager
                                               thenNotifyDelegate:self];
            }
            break;
            default:
                break;
        }
    }

    if ([sender isKindOfClass:[AccountLogin class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                [self cloneSessionCookies];
            }
            break;
            case FETCH_FINAL_STATUS_FAILED: {
                // If autoLogin fails the credentials need to be cleared out if they're no longer valid so the
                // user has an indication that they're no longer logged in.
                if (error.domain == WMFAccountLoginErrorDomain && error.code != LOGIN_ERROR_UNKNOWN && error.code != LOGIN_ERROR_API) {
                    [self logout];
                }
            }
            break;
            default:
                break;
        }
    }
}

- (void)cloneSessionCookies {
    // Make the session cookies expire at same time user cookies. Just remember they still can't be
    // necessarily assumed to be valid as the server may expire them, but at least make them last as
    // long as we can to lessen number of server requests. Uses user tokens as templates for copying
    // session tokens. See "recreateCookie:usingCookieAsTemplate:" for details.

    NSString* domain = [[MWKLanguageLinkController sharedInstance] appLanguage].languageCode;

    NSString* cookie1Name = [NSString stringWithFormat:@"%@wikiSession", domain];
    NSString* cookie2Name = [NSString stringWithFormat:@"%@wikiUserID", domain];

    [[NSHTTPCookieStorage sharedHTTPCookieStorage] wmf_recreateCookie:cookie1Name
                                                usingCookieAsTemplate:cookie2Name
    ];

    [[NSHTTPCookieStorage sharedHTTPCookieStorage] wmf_recreateCookie:@"centralauth_Session"
                                                usingCookieAsTemplate:@"centralauth_User"
    ];
}

- (void)logout {
    [SessionSingleton sharedInstance].keychainCredentials.userName   = nil;
    [SessionSingleton sharedInstance].keychainCredentials.password   = nil;
    [SessionSingleton sharedInstance].keychainCredentials.editTokens = nil;
    // Clear session cookies too.
    for (NSHTTPCookie* cookie in[[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies copy]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

@end
