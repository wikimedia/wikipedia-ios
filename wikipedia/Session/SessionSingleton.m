//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SessionSingleton.h"
#import "WikipediaAppUtils.h"

@implementation SessionSingleton {
    MWKTitle *_title;
    MWKArticle *_article;
    MWKUserDataStore *_userDataStore;
    MWKSite *_searchSite;
}

+ (SessionSingleton *)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {

        self.keychainCredentials = [[KeychainCredentials alloc] init];
        self.zeroConfigState = [[ZeroConfigState alloc] init];
        self.zeroConfigState.disposition = false;

//TODO: figure out what to do with these:
        // Wiki language character sets that iOS doesn't seem to render properly...
        self.unsupportedCharactersLanguageIds = [@"my am km dv lez arc got ti" componentsSeparatedByString:@" "];

        NSString *documentsFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *basePath = [documentsFolder stringByAppendingPathComponent:@"Data"];
        _dataStore = [[MWKDataStore alloc] initWithBasePath:basePath];
        _userDataStore = [self.dataStore userDataStore];
        
        _title = nil;
        _article = nil;
        
        self.titleToTempDirThumbURLMap = @{}.mutableCopy;
    }
    return self;
}

-(NSURL *)urlForLanguage:(NSString *)language
{
    NSString *endpoint = self.fallback ? @"" : @".m";
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@%@.%@/w/api.php", language, endpoint, self.site.domain]];
}

-(NSString *)searchApiUrl
{
    NSString *endpoint = self.fallback ? @"" : @".m";
    return [NSString stringWithFormat:@"https://%@%@.%@/w/api.php", self.searchLanguage, endpoint, self.site.domain];
}

-(void)setSearchLanguage:(NSString *)searchLanguage
{
    _searchSite = nil;
    [[NSUserDefaults standardUserDefaults] setObject:searchLanguage forKey:@"Domain"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)searchLanguage
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"Domain"];
}

-(MWKSite *)searchSite
{
    if (_searchSite == nil) {
        _searchSite = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:self.searchLanguage];
    }
    return _searchSite;
}

-(BOOL)isCurrentArticleMain
{
    NSString *mainArticleTitle = [WikipediaAppUtils mainArticleTitleForCode: self.site.language];
    // Reminder: Do not do the following instead of the line above:
    //      NSString *mainArticleTitle = self.domainMainArticleTitle;
    // This is because each language domain has its own main page, and self.domainMainArticleTitle
    // is the main article title for the current search domain, but this "isCurrentArticleMain"
    // method needs to return YES if an article is a main page, even if it isn't the current
    // search domain's main page. For example, isCurrentArticleMain is used to decide whether edit
    // pencil icons will be shown for a page (they are not shown for main pages), but if
    // self.domainMainArticleTitle was being used above, the user would see edit icons if they
    // switched their search language from "en" to "fr", then hit back button - the "en" main
    // page would erroneously display edit pencil icons.
    if (!mainArticleTitle) return NO;
    return ([self.title.prefixedText isEqualToString: mainArticleTitle]);
}

-(MWKTitle *)title
{
    if (_title == nil) {
        NSString *lang = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentArticleDomain"];
        NSString *title = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentArticleTitle"];
        MWKSite *site = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:lang];
        _title = [site titleWithString:title];
    }
    assert(_title != nil);
    return _title;
}

-(MWKSite *)site
{
    return self.title.site;
}

- (MWKArticle *)article
{
    assert(self.dataStore != nil);
    if (_article == nil) {
        _article = [self.dataStore articleWithTitle:self.title];
    }
    assert(_article != nil);
    return _article;
}

-(void)setTitle:(MWKTitle *)title
{
    _title = title;
    _article = nil;
    [[NSUserDefaults standardUserDefaults] setObject:title.site.language forKey:@"CurrentArticleDomain"];
    [[NSUserDefaults standardUserDefaults] setObject:title.prefixedDBKey forKey:@"CurrentArticleTitle"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)sendUsageReports
{
    NSNumber *val = [[NSUserDefaults standardUserDefaults] objectForKey:@"SendUsageReports"];
    return [val boolValue];
}

-(void)setSendUsageReports:(BOOL)sendUsageReports
{
    [[NSUserDefaults standardUserDefaults] setObject:@(sendUsageReports) forKey:@"SendUsageReports"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
