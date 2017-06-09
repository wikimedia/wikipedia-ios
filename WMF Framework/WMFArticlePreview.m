#import "WMFArticlePreview.h"
#import "NSDictionary+WMFPageViewsSortedByDate.h"

@implementation WMFArticlePreview

- (NSArray<NSNumber *> *)pageViewsSortedByDate {
    return self.pageViews.wmf_pageViewsSortedByDate;
}

@end
