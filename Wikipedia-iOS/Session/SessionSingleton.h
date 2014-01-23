//  Created by Monte Hurd on 12/6/13.

#import <Foundation/Foundation.h>

@interface SessionSingleton : NSObject

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
-(NSString *)bundledLanguagesPath;

+ (SessionSingleton *)sharedInstance;

@end
