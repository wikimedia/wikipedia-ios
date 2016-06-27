//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SessionSingleton.h"
#import "WikipediaAppUtils.h"
#import "QueuesSingleton.h"
#import "WMFURLCache.h"
#import "WMFAssetsFile.h"
#import "MediaWikiKit.h"
#import "Wikipedia-Swift.h"


@interface SessionSingleton ()

@property (strong, nonatomic, readwrite) MWKDataStore* dataStore;

@property (strong, nonatomic) WMFAssetsFile* mainPages;

@property (strong, nonatomic, readwrite) MWKSite* currentArticleSite;

@property (strong, nonatomic) MWKTitle* currentArticleTitle;

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

@end
