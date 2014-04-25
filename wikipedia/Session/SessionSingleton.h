//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "KeychainCredentials.h"
#import "ZeroConfigState.h"

@class KeychainCredentials;

@interface SessionSingleton : NSObject

@property (strong, nonatomic) KeychainCredentials *keychainCredentials;
@property (strong, nonatomic) ZeroConfigState *zeroConfigState;

// These 5 persist across app restarts.
@property (strong, nonatomic) NSString *site;
@property (strong, nonatomic) NSString *domain;
@property (strong, nonatomic) NSString *domainName;
@property (strong, nonatomic) NSString *currentArticleTitle;
@property (strong, nonatomic) NSString *currentArticleDomain;

@property (strong, nonatomic, readonly) NSString *currentArticleDomainName;

@property (strong, nonatomic, readonly) NSString *searchApiUrl;

@property (strong, atomic) NSArray *unsupportedCharactersLanguageIds;

-(NSURL *)urlForDomain:(NSString *)domain;
-(NSMutableArray *)getBundledLanguagesJson;
-(NSString *)domainNameForCode:(NSString *)code;

+ (SessionSingleton *)sharedInstance;

@end
