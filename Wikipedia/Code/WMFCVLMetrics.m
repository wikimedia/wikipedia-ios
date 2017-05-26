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
    copy.boundsSize = self.boundsSize;
    copy.numberOfColumns = self.numberOfColumns;
    copy.contentInsets = self.contentInsets;
    copy.sectionInsets = self.sectionInsets;
    copy.interColumnSpacing = self.interColumnSpacing;
    copy.interSectionSpacing = self.interSectionSpacing;
    copy.interItemSpacing = self.interItemSpacing;
    copy.columnWeights = self.columnWeights;
    copy.shouldMatchColumnHeights = self.shouldMatchColumnHeights;
    return copy;
}

+ (nonnull WMFCVLMetrics *)metricsWithBoundsSize:(CGSize)boundsSize {
    return [self metricsWithBoundsSize:boundsSize firstColumnRatio:1.179 secondColumnRatio:0.821 collapseSectionSpacing:NO];
}

+ (nonnull WMFCVLMetrics *)metricsWithBoundsSize:(CGSize)boundsSize firstColumnRatio:(CGFloat)firstColumnRatio secondColumnRatio:(CGFloat)secondColumnRatio collapseSectionSpacing:(BOOL)collapseSectionSpacing {
    WMFCVLMetrics *metrics = [[WMFCVLMetrics alloc] init];
    metrics.boundsSize = boundsSize;
    BOOL isRTL = [[UIApplication sharedApplication] userInterfaceLayoutDirection] == UIUserInterfaceLayoutDirectionRightToLeft;
    BOOL isPad = boundsSize.width >= 600;
    BOOL useTwoColumns = isPad || boundsSize.width > boundsSize.height;
    BOOL isWide = boundsSize.width >= 1000;
    metrics.numberOfColumns = useTwoColumns ? 2 : 1;
    metrics.columnWeights = useTwoColumns ? isRTL ? @[@(secondColumnRatio), @(firstColumnRatio)] : @[@(firstColumnRatio), @(secondColumnRatio)] : @[@1];
    metrics.interColumnSpacing = useTwoColumns ? 20 : 0;
    metrics.interItemSpacing = 0;
    metrics.interSectionSpacing = collapseSectionSpacing ? 0 : useTwoColumns ? 20 : 50;
    metrics.contentInsets = useTwoColumns ? isWide ? UIEdgeInsetsMake(20, 90, 20, 90) : UIEdgeInsetsMake(20, 22, 20, 22) : UIEdgeInsetsMake(0, 0, collapseSectionSpacing ? 0 : 50, 0);
    metrics.sectionInsets = UIEdgeInsetsZero;
    metrics.shouldMatchColumnHeights = YES;
    return metrics;
}

@end
