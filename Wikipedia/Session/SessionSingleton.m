//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SessionSingleton.h"
#import "WikipediaAppUtils.h"
#import "QueuesSingleton.h"
#import "WMFURLCache.h"
#import "WMFAssetsFile.h"

@interface SessionSingleton ()

@property (strong, nonatomic, readwrite) MWKDataStore* dataStore;
@property (strong, nonatomic, readwrite) MWKUserDataStore* userDataStore;

@property (strong, nonatomic) WMFAssetsFile* mainPages;

@property (strong, nonatomic, readwrite) MWKSite* currentArticleSite;

@property (strong, nonatomic) MWKTitle* currentArticleTitle;

@property (strong, nonatomic) MWKSite* searchSite;

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

+ (NSString*)mainDataStorePath {
    // !!!: Do not change w/o doing something with the previous path (e.g. moving atomically or deleting)
    NSString* documentsFolder =
        [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [documentsFolder stringByAppendingPathComponent:@"Data"];
}

- (instancetype)init {
    return [self initWithDataStore:[[MWKDataStore alloc] initWithBasePath:[[self class] mainDataStorePath]]];
}

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    self = [super init];
    if (self) {
        #warning FIXME: move to AppDelegate, if we should be doing this at all (slows down app launch)
        [WikipediaAppUtils copyAssetsFolderToAppDataDocuments];

        WMFURLCache* urlCache = [[WMFURLCache alloc] initWithMemoryCapacity:MegabytesToBytes(64)
                                                               diskCapacity:MegabytesToBytes(64)
                                                                   diskPath:nil];
        [NSURLCache setSharedURLCache:urlCache];

        self.keychainCredentials         = [[KeychainCredentials alloc] init];
        self.zeroConfigState             = [[ZeroConfigState alloc] init];
        self.zeroConfigState.disposition = false;

        self.dataStore     = dataStore;
        self.userDataStore = [dataStore userDataStore];

        _currentArticleSite = [self lastKnownSite];

        self.titleToTempDirThumbURLMap = @{}.mutableCopy;
    }
    return self;
}

#pragma mark - Site

- (void)setCurrentArticleSite:(MWKSite*)site {
    if (site) {
        _currentArticleSite = site;
        [[NSUserDefaults standardUserDefaults] setObject:site.language forKey:@"CurrentArticleDomain"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark - Article

- (void)setCurrentArticleTitle:(MWKTitle*)currentArticle {
    if (currentArticle) {
        _currentArticleTitle = currentArticle;
        [[NSUserDefaults standardUserDefaults] setObject:currentArticle.prefixedDBKey forKey:@"CurrentArticleTitle"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)setCurrentArticle:(MWKArticle*)currentArticle {
    if (currentArticle) {
        _currentArticle          = currentArticle;
        self.currentArticleTitle = currentArticle.title;
        self.currentArticleSite  = currentArticle.site;
    }
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
    if (!titleText) {
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

#pragma mark - Search

- (NSString*)searchApiUrl {
    return [self searchApiUrlForLanguage:self.searchLanguage];
}

- (NSString*)searchApiUrlForLanguage:(NSString*)language {
    NSString* endpoint = self.fallback ? @"" : @".m";
    return [NSString stringWithFormat:@"https://%@%@.%@/w/api.php", language, endpoint, self.currentArticleSite.domain];
}

- (void)setSearchLanguage:(NSString*)searchLanguage {
    [[NSUserDefaults standardUserDefaults] setObject:searchLanguage forKey:@"Domain"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.searchSite = nil;
}

- (NSString*)searchLanguage {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"Domain"];
}

- (MWKSite*)searchSite {
    if (_searchSite == nil) {
        _searchSite = [[MWKSite alloc] initWithDomain:WMFDefaultSiteDomain language:[self searchLanguage]];
    }
    return _searchSite;
}

#pragma mark - Language URL

- (NSURL*)urlForLanguage:(NSString*)language {
    NSString* endpoint = self.fallback ? @"" : @".m";
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@%@.%@/w/api.php", language, endpoint, self.currentArticleSite.domain]];
}

#pragma mark - Usage Reports

- (BOOL)shouldSendUsageReports {
    NSNumber* val = [[NSUserDefaults standardUserDefaults] objectForKey:@"SendUsageReports"];
    return [val boolValue];
}

- (void)setShouldSendUsageReports:(BOOL)sendUsageReports {
    [[NSUserDefaults standardUserDefaults] setObject:@(sendUsageReports) forKey:@"SendUsageReports"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[QueuesSingleton sharedInstance] reset];
}

@end
