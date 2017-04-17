#import "WMFCVLMetrics.h"

@interface WMFCVLMetrics ()
@property (nonatomic) CGSize boundsSize;
@property (nonatomic) NSInteger numberOfColumns;
@property (nonatomic) UIEdgeInsets contentInsets;
@property (nonatomic) UIEdgeInsets sectionInsets;
@property (nonatomic) CGFloat interColumnSpacing;
@property (nonatomic) CGFloat interSectionSpacing;
@property (nonatomic) CGFloat interItemSpacing;
@property (nonatomic, copy) NSArray *columnWeights;
@end
@implementation WMFCVLMetrics

- (id)copyWithZone:(NSZone *)zone {
    WMFCVLMetrics *copy = [[WMFCVLMetrics allocWithZone:zone] init];
    copy.interColumnSpacing = self.interColumnSpacing;
    copy.interSectionSpacing = self.interSectionSpacing;
    copy.interItemSpacing = self.interItemSpacing;
    copy.sectionInsets = self.sectionInsets;
    copy.contentInsets = self.contentInsets;
    copy.numberOfColumns = self.numberOfColumns;
    copy.columnWeights = self.columnWeights;
    copy.boundsSize = self.boundsSize;
    return copy;
}

+ (nonnull WMFCVLMetrics *)metricsWithBoundsSize:(CGSize)boundsSize {
    WMFCVLMetrics *metrics = [[WMFCVLMetrics alloc] init];
    metrics.boundsSize = boundsSize;
    BOOL isRTL = [[UIApplication sharedApplication] userInterfaceLayoutDirection] == UIUserInterfaceLayoutDirectionRightToLeft;
    BOOL isPad = boundsSize.width >= 600;
    BOOL useTwoColumns = isPad || boundsSize.width > boundsSize.height;
    BOOL isWide = boundsSize.width >= 1000;
    metrics.numberOfColumns = useTwoColumns ? 2 : 1;
    metrics.columnWeights = useTwoColumns ? isRTL ? @[@0.821, @1.179] : @[@1.179, @0.821] : @[@1];
    metrics.interColumnSpacing = useTwoColumns ? 20 : 0;
    metrics.interItemSpacing = 1;
    metrics.interSectionSpacing = useTwoColumns ? 20 : 50;
    metrics.contentInsets = useTwoColumns ? isWide ? UIEdgeInsetsMake(20, 90, 20, 90) : UIEdgeInsetsMake(20, 22, 20, 22) : UIEdgeInsetsMake(0, 0, 50, 0);
    metrics.sectionInsets = UIEdgeInsetsMake(1, 0, 1, 0);
    metrics.shouldMatchColumnHeights = YES;
    return metrics;
}

@end
