#import "WMFContentGroup+DetailViewControllers.h"
#import "WMFFirstRandomViewController.h"
#import "Wikipedia-Swift.h"

@implementation WMFContentGroup (DetailViewControllers)

- (nullable NSArray<NSURL *> *)contentURLs {
    NSArray<NSCoding> *content = (NSArray<NSCoding> *)self.fullContent.object;
    if ([self contentType] == WMFContentTypeTopReadPreview) {
        content = [content wmf_map:^id(WMFFeedTopReadArticlePreview *obj) {
            return [obj articleURL];
        }];
    } else if ([self contentType] == WMFContentTypeStory) {
        content = [content wmf_map:^id(WMFFeedNewsStory *obj) {
            return [[obj featuredArticlePreview] articleURL] ?: [[[obj articlePreviews] firstObject] articleURL];
        }];
    } else if ([self contentType] != WMFContentTypeURL) {
        content = nil;
    }
    return content;
}

- (nullable UIViewController *)detailViewControllerWithDataStore:(MWKDataStore *)dataStore siteURL:(NSURL *)siteURL theme:(WMFTheme *)theme {
    WMFFeedMoreType moreType = [self moreType];
    UIViewController *vc = nil;
    switch (moreType) {
        case WMFFeedMoreTypePageList:
        case WMFFeedMoreTypePageListWithLocation: {
            NSArray<NSURL *> *URLs = (NSArray<NSURL *> *)[self contentURLs];
            if (![[URLs firstObject] isKindOfClass:[NSURL class]]) {
                NSAssert(false, @"Invalid Content");
                return nil;
            }
            if (moreType == WMFFeedMoreTypePageListWithLocation) {
                vc = [[WMFArticleLocationCollectionViewController alloc] initWithArticleURLs:URLs dataStore:dataStore];
            } else {
                vc = [[WMFArticleURLListViewController alloc] initWithArticleURLs:URLs dataStore:dataStore];
                vc.title = [self moreTitle];
            }
        } break;
        case WMFFeedMoreTypeNews: {
            NSArray<WMFFeedNewsStory *> *stories = (NSArray<WMFFeedNewsStory *> *)self.fullContent.object;
            if (![[stories firstObject] isKindOfClass:[WMFFeedNewsStory class]]) {
                NSAssert(false, @"Invalid Content");
                return nil;
            }
            vc = [[WMFNewsViewController alloc] initWithStories:stories dataStore:dataStore];
        } break;
        case WMFFeedMoreTypeOnThisDay: {
            NSArray<WMFFeedOnThisDayEvent *> *events = (NSArray<WMFFeedOnThisDayEvent *> *)self.fullContent.object;
            if (![[events firstObject] isKindOfClass:[WMFFeedOnThisDayEvent class]]) {
                NSAssert(false, @"Invalid Content");
                return nil;
            }
            vc = [[WMFOnThisDayViewController alloc] initWithEvents:events dataStore:dataStore midnightUTCDate:self.midnightUTCDate];
        } break;
        case WMFFeedMoreTypePageWithRandomButton: {
            vc = [[WMFFirstRandomViewController alloc] initWithSiteURL:siteURL dataStore:dataStore theme:theme];
        } break;
        default:
            NSAssert(false, @"Unknown More Type");
            return nil;
    }
    if ([vc conformsToProtocol:@protocol(WMFThemeable)]) {
        [(id<WMFThemeable>)vc applyTheme:theme];
    }
    return vc;
}

@end
