#import "SavedPagesFunnel.h"
#import "NSURL+WMFLinkParsing.h"

static NSString *const kEventDataAssertVerbiage = @"Event data not present";
static NSString *const kAppInstallIdKey = @"appInstallID";

@implementation SavedPagesFunnel

- (instancetype)init {
    // http://meta.wikimedia.org/wiki/Schema:MobileWikiAppSavedPages
    self = [super initWithSchema:@"MobileWikiAppSavedPages" version:10375480];
    return self;
}

+ (void)logStateChange:(BOOL)didSave articleURL:(NSURL *)articleURL {
    SavedPagesFunnel *funnel = [self new];
    if (didSave) {
        [funnel logSaveNewWithArticleURL:articleURL];
    } else {
        [funnel logDeleteWithArticleURL:articleURL];
    }
}

- (NSDictionary *)preprocessData:(NSDictionary *)eventData {
    NSMutableDictionary *dict = [eventData mutableCopy];
    dict[kAppInstallIdKey] = self.appInstallID;
    return [NSDictionary dictionaryWithDictionary:dict];
}

- (void)logSaveNewWithArticleURL:(NSURL *)articleURL {
    [self log:@{@"action": @"savenew"} language:articleURL.wmf_language];
}

// TODO: Unused
- (void)logUpdate {
    [self log:@{@"action": @"update"}];
}

// TODO: Unused
- (void)logImportOnSubdomain:(NSString *)subdomain {
    [self log:@{@"action": @"import"}
         wiki:[subdomain stringByAppendingString:@"wiki"]];
}

- (void)logDeleteWithArticleURL:(NSURL *)articleURL {
    [self log:@{@"action": @"delete"} language:articleURL.wmf_language];
}

- (void)logEditAttemptWithArticleURL:(NSURL *)articleURL {
    [self log:@{@"action": @"editattempt"} language:articleURL.wmf_language];
}

// TODO: Unused
// Doesn't seem to be relevant to iOS version?
- (void)logEditRefresh {
    [self log:@{@"action": @"editrefresh"}];
}

// TODO: Unused
// Doesn't seem to be relevant to iOS version?
- (void)logEditAfterRefresh {
    [self log:@{@"action": @"editafterrefresh"}];
}

@end
