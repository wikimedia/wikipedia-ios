//
//  ShareFunnel.m
//  Wikipedia
//
//  Created by Adam Baso on 2/3/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFShareFunnel.h"

static NSString *const kSchemaName = @"MobileWikiAppShareAFact";
static const int kSchemaVersion = 10916168;
static NSString *const kActionHighlight = @"highlight";
static NSString *const kActionShareIntent = @"shareintent"; // lowercase
static NSString *const kActionShare = @"share";
static NSString *const kActionKey = @"action";
static NSString *const kAppInstallIdKey = @"appInstallID"; // uppercase
static NSString *const kShareSessionTokenKey = @"shareSessionToken";
static NSString *const kTextKey = @"text";
static NSString *const kArticleKey = @"article";
static NSString *const kPageIdKey = @"pageID"; // ID uppercase
static NSString *const kRevIdKey = @"revID"; // ID uppercase
static NSString *const kTargetKey = @"target";

@interface WMFShareFunnel ()
@property NSString *sessionToken;
@property NSString *appInstallId;
@property MWKArticle *article;
@end

@implementation WMFShareFunnel

-(id)initWithArticle:(MWKArticle*) article
{
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppShareAFact
    self = [super initWithSchema:kSchemaName version:kSchemaVersion];
    if (self) {
        _sessionToken = [self singleUseUUID];
        _appInstallId = [self persistentUUID:kSchemaName];
        _article = article;
    }
    return self;
}

-(NSDictionary *)preprocessData:(NSDictionary *)eventData
{
    NSMutableDictionary *dict = [eventData mutableCopy];
    dict[kShareSessionTokenKey] = self.sessionToken;
    dict[kAppInstallIdKey] = self.appInstallId;
    dict[kPageIdKey] = [NSNumber numberWithInt:self.article.articleId];
    dict[kArticleKey] = self.article.title.prefixedText;
    
    // TODO: refactor MWKArticle (and ArticleFetcher - the prop would be 'revision')
    
    dict[kRevIdKey] = [NSNumber numberWithInt:0];
    return [NSDictionary dictionaryWithDictionary: dict];
}

-(void)logHighlight
{
    [self log:@{kActionKey: kActionHighlight}];
}

-(void)logShareIntentWithSelection:(NSString*) selection
{
    [self log:@{kActionKey: kActionShareIntent, kTextKey: selection}];
}

-(void)logShareWithSelection:(NSString*) selection platformOutcome: (NSString*) platformOutcome;
{
    [self log:@{kActionKey: kActionShare,
                kTextKey: selection,
                kTargetKey: platformOutcome}];
}

@end
