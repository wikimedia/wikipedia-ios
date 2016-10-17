#import "WMFArticlePreview.h"

@implementation WMFArticlePreview

- (NSArray<NSNumber *> *)pageViewsSortedByDate {
    NSArray<NSDate *> *keys = self.pageViews.allKeys;
    keys = [keys sortedArrayUsingComparator:^NSComparisonResult(NSDate *_Nonnull obj1, NSDate *_Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    NSArray *numbers = [keys bk_map:^id(NSDate *obj) {
        return self.pageViews[obj];
    }];
    return numbers;
}

@end
