#import "WMFShareFunnel.h"
@import WMF;

static NSString *const kSchemaName = @"MobileWikiAppShareAFact";
static int const kSchemaVersion = 18071215;
static NSString *const kAppInstallIdKey = @"appInstallID";
static NSString *const kActionKey = @"action";
static NSString *const kActionHighlight = @"highlight";
static NSString *const kActionShareTap = @"sharetap";
static NSString *const kActionAbandoned = @"abandoned";
static NSString *const kActionShareIntent = @"shareintent";
static NSString *const kShareModeKey = @"sharemode";
static NSString *const kShareModeImage = @"image";
static NSString *const kShareModeText = @"text";
static NSString *const kActionFailure = @"failure";
static NSString *const kActionSystemShareSheet = @"systemsharesheet";
static NSString *const kActionShare = @"share";
static NSString *const kTargetKey = @"target";

static NSString *const kShareSessionTokenKey = @"sessionToken";
static NSString *const kTextKey = @"text"; // same as kShareModeImage by design
static NSString *const kArticleKey = @"article";
static NSString *const kPageIdKey = @"pageID"; // ID uppercase
static NSString *const kRevIdKey = @"revID";   // ID uppercase
static NSString *const kTimestampKey = @"ts";

static NSString *const kInitWithArticleAssertVerbiage = @"Article title invalid";
static NSString *const kEventDataAssertVerbiage = @"Event data not present";
static NSString *const kSelectionAssertVerbiage = @"No selection provided";

@interface WMFShareFunnel ()
@property NSString *sessionToken;
@property NSString *articleTitle;
@property NSNumber *articleId;
@property NSString *selection;
@property NSString *shareMode;
@end

@implementation WMFShareFunnel

- (id)initWithArticle:(WMFArticle *)article {
    NSParameterAssert(article.URL.wmf_title);
    NSString *title = [[article URL] wmf_title];
    NSNumber *pageID = [article pageID];
    // ...implicitly, the articleId is okay if the title is okay.
    // But in case the title is broken (and, implicitly, articleId is, too)
    if (!title || !pageID) {
        NSAssert(false, @"%@ : %@",
                 kInitWithArticleAssertVerbiage,
                 [article URL]);
        return nil;
    }
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppShareAFact
    self = [super initWithSchema:kSchemaName version:kSchemaVersion];
    if (self) {
        _sessionToken = [self singleUseUUID];
        _articleTitle = [title wmf_safeSubstringToIndex:WMFEventLoggingMaxStringLength_General];
        _articleId = pageID;
    }
    return self;
}

- (NSDictionary *)preprocessData:(NSDictionary *)eventData {
    if (!eventData) {
        NSAssert(false, @"%@ : %@",
                 kEventDataAssertVerbiage,
                 eventData);
        return nil;
    }
    NSMutableDictionary *dict = [eventData mutableCopy];
    dict[kAppInstallIdKey] = self.appInstallID;
    dict[kShareSessionTokenKey] = self.sessionToken;
    dict[kPageIdKey] = self.articleId;
    dict[kArticleKey] = self.articleTitle;
    [dict setValue:self.selection forKey:kTextKey];
    [dict setValue:self.shareMode forKey:kShareModeKey];
    dict[kTimestampKey] = [self timestamp];
    
    // TODO: refactor MWKArticle (and ArticleFetcher - the prop would be 'revision')
    dict[kRevIdKey] = @(-1);
    return [dict copy];
}

- (void)logHighlight {
    [self log:@{kActionKey: kActionHighlight}];
}

- (void)logShareButtonTappedResultingInSelection:(NSString *)selection {
    if (!selection) {
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

- (void)logShareFailedWithShareMethod:(NSString *)shareMethod {
    [self log:@{kActionKey: kActionFailure,
                kTargetKey: shareMethod ? shareMethod : kActionSystemShareSheet}];
}

- (void)logShareSucceededWithShareMethod:(NSString *)shareMethod;
{
    [self log:@{kActionKey: kActionShare,
                kTargetKey: shareMethod ? shareMethod : kActionSystemShareSheet}];
}

@end
