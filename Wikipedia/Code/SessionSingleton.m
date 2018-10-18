#import <WMF/SessionSingleton.h>
#import <WMF/WMF-Swift.h>

@interface SessionSingleton ()

@property (strong, nonatomic, readwrite) MWKDataStore *dataStore;

@property (strong, nonatomic) WMFAssetsFile *mainPages;

@property (strong, nonatomic, readwrite) NSURL *currentArticleSiteURL;

@property (strong, nonatomic) NSURL *currentArticleURL;

@end

@implementation SessionSingleton
@synthesize currentArticle = _currentArticle;

#pragma mark - Setup

+ (SessionSingleton *)sharedInstance {
    static dispatch_once_t onceToken;
    static SessionSingleton *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init {
    return [self initWithDataStore:[[MWKDataStore alloc] init]];
}

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    self = [super init];
    if (self) {
        WMFURLCache *urlCache = [[WMFURLCache alloc] initWithMemoryCapacity:MegabytesToBytes(512)
                                                               diskCapacity:MegabytesToBytes(2048)
                                                                   diskPath:nil];
        [NSURLCache setSharedURLCache:urlCache];

        self.zeroConfigurationManager = [[WMFZeroConfigurationManager alloc] init];

        self.dataStore = dataStore;

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
    [[NSUserDefaults wmf] setObject:currentArticleSiteURL.wmf_language forKey:@"CurrentArticleDomain"];
}

#pragma mark - Article

- (void)setCurrentArticleURL:(NSURL *)currentArticleURL {
    NSParameterAssert(currentArticleURL);
    if (!_currentArticleURL || [_currentArticleURL isEqual:currentArticleURL]) {
        return;
    }
    _currentArticleURL = currentArticleURL;
    [[NSUserDefaults wmf] setObject:currentArticleURL.wmf_title forKey:@"CurrentArticleTitle"];
}

- (void)setCurrentArticle:(MWKArticle *)currentArticle {
    if (!currentArticle || [_currentArticle isEqual:currentArticle]) {
        return;
    }
    _currentArticle = currentArticle;
    self.currentArticleURL = currentArticle.url;
    self.currentArticleSiteURL = currentArticle.url;
}

- (MWKArticle *)currentArticle {
    if (!_currentArticle) {
        self.currentArticle = [self lastLoadedArticle];
    }
    return _currentArticle;
}

#pragma mark - Last known/loaded

- (NSURL *)lastKnownSite {
    return [NSURL wmf_URLWithDefaultSiteAndlanguage:[[NSUserDefaults wmf] objectForKey:@"CurrentArticleDomain"]];
}

- (NSURL *)lastLoadedArticleURL {
    NSURL *lastKnownSite = [self lastKnownSite];
    NSString *titleText = [[NSUserDefaults wmf] objectForKey:@"CurrentArticleTitle"];
    if (!titleText.length) {
        return nil;
    }
    return [lastKnownSite wmf_URLWithTitle:titleText];
}

- (MWKArticle *)lastLoadedArticle {
    NSURL *lastLoadedURL = [self lastLoadedArticleURL];
    if (!lastLoadedURL) {
        return nil;
    }
    MWKArticle *article = [self.dataStore articleWithURL:lastLoadedURL];
    return article;
}

#pragma mark - Language URL

- (NSURL *)urlForLanguage:(NSString *)language {
    return self.fallback ? [NSURL wmf_desktopAPIURLForURL:[NSURL wmf_URLWithDefaultSiteAndlanguage:language]] : [NSURL wmf_mobileAPIURLForURL:[NSURL wmf_URLWithDefaultSiteAndlanguage:language]];
}

@end
