//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SessionSingleton.h"
#import "AssetsFile.h"

@implementation SessionSingleton

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

    }
    return self;
}

-(NSURL *)urlForDomain:(NSString *)domain
{
    NSString *endpoint = self.fallback ? @"" : @".m";
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@%@.%@/w/api.php", domain, endpoint, [self site]]];
}

-(NSString *)searchApiUrl
{
    NSString *endpoint = self.fallback ? @"" : @".m";
    return [NSString stringWithFormat:@"https://%@%@.%@/w/api.php", [self domain], endpoint, [self site]];
}

-(void)setDomain:(NSString *)domain
{
    self.domainMainArticleTitle = [self mainArticleTitleForCode:domain];

    [[NSUserDefaults standardUserDefaults] setObject:domain forKey:@"Domain"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)domain
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"Domain"];
}

-(void)setDomainMainArticleTitle:(NSString *)domainMainArticleTitle
{
    [[NSUserDefaults standardUserDefaults] setObject:domainMainArticleTitle forKey:@"DomainMainArticleTitle"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)domainMainArticleTitle
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"DomainMainArticleTitle"];
}

-(void)setDomainName:(NSString *)domainName
{
    [[NSUserDefaults standardUserDefaults] setObject:domainName forKey:@"DomainName"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)domainName
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"DomainName"];
}

-(void)setSite:(NSString *)site
{
    [[NSUserDefaults standardUserDefaults] setObject:site forKey:@"Site"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)site
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"Site"];
}

-(void)setCurrentArticleTitle:(NSString *)currentArticleTitle
{
    [[NSUserDefaults standardUserDefaults] setObject:currentArticleTitle forKey:@"CurrentArticleTitle"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)currentArticleTitle
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentArticleTitle"];
}

-(void)setCurrentArticleDomain:(NSString *)currentArticleDomain
{
    [[NSUserDefaults standardUserDefaults] setObject:currentArticleDomain forKey:@"CurrentArticleDomain"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)currentArticleDomain
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentArticleDomain"];
}

-(NSString *)currentArticleDomainName
{
    return [self domainNameForCode:self.currentArticleDomain];
}

-(NSString *)domainNameForCode:(NSString *)code
{
    AssetsFile *assetsFile = [[AssetsFile alloc] initWithFile:ASSETS_FILE_LANGUAGES];
    NSArray *result = assetsFile.array;
    if (result.count > 0) {
        for (NSDictionary *d in result) {
            if ([d[@"code"] isEqualToString:code]) {
                return d[@"name"];
            }
        }
        return nil;
    }else{
        return nil;
    }
}

-(NSString *)mainArticleTitleForCode:(NSString *)code
{
    AssetsFile *assetsFile = [[AssetsFile alloc] initWithFile:ASSETS_FILE_MAINPAGES];
    NSDictionary *mainPageNames = assetsFile.dictionary;
    return mainPageNames[code];
}

-(BOOL)isCurrentArticleMain
{
    NSString *mainArticleTitle = [self mainArticleTitleForCode: self.currentArticleDomain];
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
    return ([self.currentArticleTitle isEqualToString: mainArticleTitle]);
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
