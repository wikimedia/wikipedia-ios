//
//  SuggestedPagesFunnel.m
//  Wikipedia
//
//  Created by Adam Baso on 2/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFSuggestedPagesFunnel.h"

static NSString* const kSchemaName = @"MobileWikiAppArticleSuggestions";
static const int kSchemaVersion    = 10590869;

static NSString* const kActionKey             = @"action";
static NSString* const kActionShown           = @"shown";
static NSString* const kActionClicked         = @"clicked";
static NSString* const kAppInstallIdKey       = @"appInstallID";
static NSString* const kPageTitleKey          = @"pageTitle";
static NSString* const kReadMoreListKey       = @"readMoreList";
static NSString* const kReadMoreListDelimeter = @"|";
static NSString* const kReadMoreIndexKey      = @"readMoreIndex";

static NSString* const kInitWithArticleAssertVerbiage  = @"Article title must be well formed and suggested titles non-empty";
static NSString* const kInitMustUseSpecificInitializer = @"Wrong initializer. Use - (id)initWithArticle:(MWKArticle*)article suggestedTitles:(NSArray*)suggestedTitles";

@interface WMFSuggestedPagesFunnel ()
@property NSString* appInstallId;
@property NSString* pageTitle;
@property NSString* readMoreList;
@end

@implementation WMFSuggestedPagesFunnel

- (id)initWithArticle:(MWKArticle*)article
      suggestedTitles:(NSArray*)suggestedTitles {
    NSString* title = [[article title] prefixedText];
    if (!title || ![suggestedTitles count]) {
        NSAssert(false, @"%@...ARTICLE TITLE: %@ SUGGESTED: %@",
                 kInitWithArticleAssertVerbiage,
                 [article title],
                 suggestedTitles);
        return nil;
    }
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppArticleSuggestions
    self = [super initWithSchema:kSchemaName version:kSchemaVersion];
    if (self) {
        _appInstallId = [self persistentUUID:kSchemaName];
        _pageTitle    = title;
        _readMoreList = [suggestedTitles componentsJoinedByString:kReadMoreListDelimeter];
    }
    return self;
}

- (id)init {
    NSAssert(false, kInitMustUseSpecificInitializer);
    return nil;
}

- (id)initWithSchema:(NSString*)schema version:(int)revision {
    return [self init];
}

- (NSDictionary*)preprocessData:(NSDictionary*)eventData {
    NSMutableDictionary* dict = [eventData mutableCopy];
    dict[kAppInstallIdKey] = self.appInstallId;
    dict[kPageTitleKey]    = self.pageTitle;
    dict[kReadMoreListKey] = self.readMoreList;
    return [dict copy];
}

- (void)logShown {
    [self log:@{kActionKey: kActionShown}];
}

- (void)logClickedAtIndex:(NSUInteger)index {
    [self log:@{kActionKey: kActionClicked, kReadMoreIndexKey: @(index)}];
}

@end
