//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SessionSingleton.h"
#import "WikipediaAppUtils.h"
#import "QueuesSingleton.h"
#import "URLCache.h"
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
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [WikipediaAppUtils copyAssetsFolderToAppDataDocuments];

        [self registerStandardUserDefaults];

        URLCache* urlCache = [[URLCache alloc] initWithMemoryCapacity:MegabytesToBytes(64)
                                                         diskCapacity:MegabytesToBytes(64)
                                                             diskPath:nil];
        [NSURLCache setSharedURLCache:urlCache];

        self.keychainCredentials         = [[KeychainCredentials alloc] init];
        self.zeroConfigState             = [[ZeroConfigState alloc] init];
        self.zeroConfigState.disposition = false;

        NSString* documentsFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString* basePath        = [documentsFolder stringByAppendingPathComponent:@"Data"];
        _dataStore     = [[MWKDataStore alloc] initWithBasePath:basePath];
        _userDataStore = [self.dataStore userDataStore];

        _currentArticleSite = [self lastKnownSite];

        self.titleToTempDirThumbURLMap = @{}.mutableCopy;
    }
    return self;
}

- (void)registerStandardUserDefaults {
    NSString* systemLang = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString* lang       = [WikipediaAppUtils wikiLangForSystemLang:systemLang];
    if (lang == nil) {
        lang = @"en";
    }

    NSString* langName = [WikipediaAppUtils domainNameForCode:lang];
    if (langName == nil) {
        langName = lang;
    }

    NSString* mainPage = [self mainArticleTitleTextForLanguageCode:lang];
    if (mainPage == nil) {
        mainPage = @"Main Page";
    }

    NSDictionary* userDefaultsDefaults = @{
        @"CurrentArticleTitle": mainPage,
        @"CurrentArticleDomain": lang,
        @"Domain": lang,
        @"DomainName": langName,
        @"DomainMainArticleTitle": mainPage,
        @"Site": @"wikipedia.org",
        @"ZeroWarnWhenLeaving": @YES,
        @"ZeroOnDialogShownOnce": @NO,
        @"FakeZeroOn": @NO,
        @"ShowOnboarding": @YES,
        @"LastHousekeepingDate": [NSDate date],
        @"SendUsageReports": @YES,
        @"AccessSavedPagesMessageShown": @NO
    };
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsDefaults];
}

#pragma mark - Site

- (void)setCurrentArticleSite:(MWKSite*)site {
    if (site) {
        _currentArticleSite = site;
        [[NSUserDefaults standardUserDefaults] setObject:site.language forKey:@"CurrentArticleDomain"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark - Main Article

- (WMFAssetsFile*)mainPages {
    if (!_mainPages) {
        _mainPages = [[WMFAssetsFile alloc] initWithFileType:WMFAssetsFileTypeMainPages];
    }

    return _mainPages;
}

- (NSString*)mainArticleTitleTextForLanguageCode:(NSString*)code {
    NSDictionary* mainPageNames = self.mainPages.dictionary;
    NSString* titleText         = mainPageNames[code];
    return titleText;
}

- (MWKTitle*)mainArticleTitleForSite:(MWKSite*)site languageCode:(NSString*)code {
    MWKTitle* title = [site titleWithString:[self mainArticleTitleTextForLanguageCode:code]];
    return title;
}

- (MWKTitle*)mainArticleTitle {
    MWKTitle* title = [self mainArticleTitleForSite:self.searchSite languageCode:self.searchSite.language];
    return title;
}

- (BOOL)articleIsAMainArticle:(MWKArticle*)article {
    MWKTitle* mainArticleTitleForArticleLanguage = [self mainArticleTitleForSite:article.site languageCode:article.site.language];

    return ([article.title.prefixedText isEqualToString:mainArticleTitleForArticleLanguage.prefixedText]);
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
    NSString* lang = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentArticleDomain"];
    MWKSite* site  = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:lang];
    return site;
}

- (MWKTitle*)lastLoadedTitle {
    MWKSite* lastKnownSite = [self lastKnownSite];
    NSString* titleText    = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentArticleTitle"];
    MWKTitle* title        = [lastKnownSite titleWithString:titleText];
    return title;
}

- (MWKArticle*)lastLoadedArticle {
    MWKTitle* lastLoadedTitle = [self lastLoadedTitle];
    MWKArticle* article       = [self.dataStore articleWithTitle:lastLoadedTitle];
    return article;
}

#pragma mark - Search

- (NSString*)searchApiUrl {
    NSString* endpoint = self.fallback ? @"" : @".m";
    return [NSString stringWithFormat:@"https://%@%@.%@/w/api.php", self.searchLanguage, endpoint, self.currentArticleSite.domain];
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
        _searchSite = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:[self searchLanguage]];
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
