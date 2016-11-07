#import <XCTest/XCTest.h>

@interface WMFNotificationTests : XCTestCase

@property (nonnull, nonatomic, strong) WMFFeedContentSource *feedContentSource;
@property (nonnull, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;
@property (nonnull, nonatomic, strong) WMFContentGroupDataStore *contentStore;


@end

@implementation WMFNotificationTests

- (void)setUp {
    [super setUp];
    NSURL *siteURL = [NSURL URLWithString:@"https://en.wikipedia.org"];
    self.previewStore = [[WMFArticlePreviewDataStore alloc] initWithDatabase:[YapDatabase sharedInstance]];
    self.contentStore = [[WMFContentGroupDataStore alloc] initWithDatabase:[YapDatabase sharedInstance]];
    self.feedContentSource = [[WMFFeedContentSource alloc] initWithSiteURL:siteURL contentGroupDataStore:self.contentStore articlePreviewDataStore:self.previewStore userDataStore:[SessionSingleton sharedInstance].dataStore notificationsController:[WMFNotificationsController sharedNotificationsController]];
}
@end
