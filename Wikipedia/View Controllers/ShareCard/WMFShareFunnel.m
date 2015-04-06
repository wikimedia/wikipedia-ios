//
//  ShareFunnel.m
//  Wikipedia
//
//  Created by Adam Baso on 2/3/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFShareFunnel.h"
#import "NSMutableDictionary+WMFMaybeSet.h"
#import "NSString+Extras.h"

static NSString* const kSchemaName             = @"MobileWikiAppShareAFact";
static const int kSchemaVersion                = 11331974;
static NSString* const kActionKey              = @"action";
static NSString* const kActionHighlight        = @"highlight";
static NSString* const kActionShareTap         = @"sharetap";
static NSString* const kActionAbandoned        = @"abandoned";
static NSString* const kActionShareIntent      = @"shareintent";
static NSString* const kShareModeKey           = @"sharemode";
static NSString* const kShareModeImage         = @"image";
static NSString* const kShareModeText          = @"text";
static NSString* const kActionFailure          = @"failure";
static NSString* const kActionSystemShareSheet = @"systemsharesheet";
static NSString* const kActionShare            = @"share";
static NSString* const kTargetKey              = @"target";

static NSString* const kAppInstallIdKey      = @"appInstallID"; // uppercase
static NSString* const kShareSessionTokenKey = @"shareSessionToken";
static NSString* const kTextKey              = @"text"; // same as kShareModeImage by design
static NSString* const kArticleKey           = @"article";
static NSString* const kPageIdKey            = @"pageID"; // ID uppercase
static NSString* const kRevIdKey             = @"revID"; // ID uppercase

static NSString* const kInitWithArticleAssertVerbiage = @"Article title invalid";
static NSString* const kEventDataAssertVerbiage       = @"Event data not present";
static NSString* const kSelectionAssertVerbiage       = @"No selection provided";

@interface WMFShareFunnel ()
@property NSString* sessionToken;
@property NSString* appInstallId;
@property NSString* articleTitle;
@property int articleId;
@property NSString* selection;
@property NSString* shareMode;
@end

@implementation WMFShareFunnel

- (id)initWithArticle:(MWKArticle*)article {
    NSString* title = [[article title] prefixedText];
    // ...implicitly, the articleId is okay if the title is okay.
    // But in case the title is broken (and, implicitly, articleId is, too)
    if (!title) {
        NSAssert(false, @"%@ : %@",
                 kInitWithArticleAssertVerbiage,
                 [article title]);
        return nil;
    }
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppShareAFact
    self = [super initWithSchema:kSchemaName version:kSchemaVersion];
    if (self) {
        _sessionToken = [self singleUseUUID];
        _appInstallId = [self persistentUUID:kSchemaName];
        _articleTitle = [title wmf_safeSubstringToIndex:WMFEventLoggingMaxStringLength_General];
        _articleId    = [article articleId];
    }
    return self;
}

- (NSDictionary*)preprocessData:(NSDictionary*)eventData {
    if (!eventData) {
        NSAssert(false, @"%@ : %@",
                 kEventDataAssertVerbiage,
                 eventData);
        return nil;
    }
    NSMutableDictionary* dict = [eventData mutableCopy];
    dict[kShareSessionTokenKey] = self.sessionToken;
    dict[kAppInstallIdKey]      = self.appInstallId;
    dict[kPageIdKey]            = @(self.articleId);
    dict[kArticleKey]           = self.articleTitle;
    [dict wmf_maybeSetObject:self.selection forKey:kTextKey];
    [dict wmf_maybeSetObject:self.shareMode forKey:kShareModeKey];

    // TODO: refactor MWKArticle (and ArticleFetcher - the prop would be 'revision')
    dict[kRevIdKey] = @(-1);
    return [dict copy];
}

- (void)logHighlight {
    [self log:@{kActionKey: kActionHighlight}];
}

- (void)logShareButtonTappedResultingInSelection:(NSString*)selection {
    if (!selection) {
        NSAssert(false, kSelectionAssertVerbiage);
        self.selection = @"";
    } else {
        self.selection = [selection wmf_safeSubstringToIndex:WMFEventLoggingMaxStringLength_Snippet];
    }
    [self log:@{kActionKey: kActionShareTap}];
}

- (void)logAbandonedAfterSeeingShareAFact {
    [self log:@{kActionKey: kActionAbandoned}];
}

- (void)logShareAsImageTapped {
    self.shareMode = kShareModeImage;
    [self log:@{kActionKey: kActionShareIntent}];
}

- (void)logShareAsTextTapped {
    self.shareMode = kShareModeText;
    [self log:@{kActionKey: kActionShareIntent}];
}

- (void)logShareFailedWithShareMethod:(NSString*)shareMethod {
    [self log:@{kActionKey: kActionFailure,
                kTargetKey: shareMethod ? shareMethod : kActionSystemShareSheet}];
}

- (void)logShareSucceededWithShareMethod:(NSString*)shareMethod;
{
    [self log:@{kActionKey: kActionShare,
                kTargetKey: shareMethod ? shareMethod : kActionSystemShareSheet}];
}

@end
