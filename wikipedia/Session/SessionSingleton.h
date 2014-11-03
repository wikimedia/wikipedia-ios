//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "KeychainCredentials.h"
#import "ZeroConfigState.h"

@class KeychainCredentials;

@interface SessionSingleton : NSObject

// Persistent settings and credentials
@property (strong, nonatomic) KeychainCredentials *keychainCredentials;
@property (strong, nonatomic) ZeroConfigState *zeroConfigState;
@property (nonatomic) BOOL sendUsageReports;

// These 6 persist across app restarts.
//@property (strong, nonatomic) NSString *site;
//@property (strong, nonatomic) NSString *domain;
// Note: "domainMainArticleTitle" is readonly because it gets set whenever "domain" changes.
@property (strong, nonatomic, readonly) NSString *domainMainArticleTitle;
//@property (strong, nonatomic) NSString *domainName;
//@property (strong, nonatomic) NSString *currentArticleTitle;
//@property (strong, nonatomic) NSString *currentArticleDomain;

//@property (strong, nonatomic, readonly) NSString *currentArticleDomainName;

// Data access objects
@property (readonly) MWKDataStore *dataStore;
@property (readonly) MWKSite *site;
@property (readwrite) MWKTitle *title;
@property (readonly) MWKArticleStore *articleStore;
@property (readonly) MWKUserDataStore *userDataStore;

@property (strong, nonatomic, readonly) NSString *searchApiUrl;

@property (strong, atomic) NSArray *unsupportedCharactersLanguageIds;

@property (nonatomic) BOOL fallback;
-(NSURL *)urlForLanguage:(NSString *)language;

-(BOOL)isCurrentArticleMain;

+ (SessionSingleton *)sharedInstance;

@end
