#import "WMFCVLMetrics.h"
@import UIKit;

@interface WMFCVLMetrics ()
@property (nonatomic) CGSize boundsSize;
@property (nonatomic) UIEdgeInsets adjustedContentInsets;
@property (nonatomic) NSInteger numberOfColumns;
@property (nonatomic) UIEdgeInsets margins;
@property (nonatomic) UIEdgeInsets sectionInsets;
@property (nonatomic) CGFloat interColumnSpacing;
@property (nonatomic) CGFloat interSectionSpacing;
@property (nonatomic) CGFloat interItemSpacing;
@property (nonatomic, copy) NSArray<NSNumber *> *columnWeights;
@end

@implementation WMFCVLMetrics

- (id)copyWithZone:(NSZone *)zone {
    WMFCVLMetrics *copy = [[WMFCVLMetrics allocWithZone:zone] init];
    copy.boundsSize = self.boundsSize;
    copy.adjustedContentInsets = self.adjustedContentInsets;
    copy.numberOfColumns = self.numberOfColumns;
    copy.margins = self.margins;
    copy.sectionInsets = self.sectionInsets;
    copy.interColumnSpacing = self.interColumnSpacing;
    copy.interSectionSpacing = self.interSectionSpacing;
    copy.interItemSpacing = self.interItemSpacing;
    copy.columnWeights = self.columnWeights;
    copy.shouldMatchColumnHeights = self.shouldMatchColumnHeights;
    return copy;
}

+ (nonnull WMFCVLMetrics *)metricsWithBoundsSize:(CGSize)boundsSize adjustedContentInsets:(UIEdgeInsets)adjustedContentInsets layoutDirection:(UIUserInterfaceLayoutDirection)layoutDirection {
    return [self metricsWithBoundsSize:boundsSize adjustedContentInsets:adjustedContentInsets firstColumnRatio:1.179 secondColumnRatio:0.821 collapseSectionSpacing:NO layoutDirection:layoutDirection];
}

+ (nonnull WMFCVLMetrics *)metricsWithBoundsSize:(CGSize)boundsSize adjustedContentInsets:(UIEdgeInsets)adjustedContentInsets firstColumnRatio:(CGFloat)firstColumnRatio secondColumnRatio:(CGFloat)secondColumnRatio collapseSectionSpacing:(BOOL)collapseSectionSpacing layoutDirection:(UIUserInterfaceLayoutDirection)layoutDirection {
    WMFCVLMetrics *metrics = [[WMFCVLMetrics alloc] init];
    metrics.boundsSize = boundsSize;
    metrics.adjustedContentInsets = adjustedContentInsets;
    BOOL isRTL = layoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
    BOOL isPad = boundsSize.width >= 600;
    BOOL useTwoColumns = isPad || boundsSize.width > boundsSize.height;
    BOOL isWide = boundsSize.width >= 1000;
    metrics.numberOfColumns = useTwoColumns ? 2 : 1;
    metrics.columnWeights = useTwoColumns ? isRTL ? @[@(secondColumnRatio), @(firstColumnRatio)] : @[@(firstColumnRatio), @(secondColumnRatio)] : @[@1];
    metrics.interColumnSpacing = useTwoColumns ? 20 : 0;
    metrics.interItemSpacing = 0;
    metrics.interSectionSpacing = collapseSectionSpacing ? 0 : useTwoColumns ? 20 : 30;
    metrics.margins = useTwoColumns ? isWide ? UIEdgeInsetsMake(20, 90, 20, 90) : UIEdgeInsetsMake(20, 22, 20, 22) : UIEdgeInsetsMake(0, 0, collapseSectionSpacing ? 0 : 50, 0);
    metrics.sectionInsets = UIEdgeInsetsZero;
    metrics.shouldMatchColumnHeights = YES;
    return metrics;
}

+ (nonnull WMFCVLMetrics *)singleColumnMetricsWithBoundsSize:(CGSize)boundsSize adjustedContentInsets:(UIEdgeInsets)adjustedContentInsets collapseSectionSpacing:(BOOL)collapseSectionSpacing {
    WMFCVLMetrics *metrics = [[WMFCVLMetrics alloc] init];
    metrics.boundsSize = boundsSize;
    metrics.adjustedContentInsets = adjustedContentInsets;
    BOOL hasMargins = boundsSize.width > 600;
    CGFloat fixedWidth = MIN(600, boundsSize.width);
    metrics.numberOfColumns = 1;
    metrics.columnWeights = @[@1];
    metrics.interColumnSpacing = 0;
    metrics.interItemSpacing = 0;
    metrics.interSectionSpacing = collapseSectionSpacing ? 0 : 30;
    CGFloat insetLeftAndRight = MAX(0, floor(0.5 * (boundsSize.width - fixedWidth)));
    CGFloat insetTopAndBottom = hasMargins ? 20 : 0;
    metrics.margins = UIEdgeInsetsMake(insetTopAndBottom, insetLeftAndRight, insetTopAndBottom, insetLeftAndRight);
    metrics.sectionInsets = UIEdgeInsetsZero;
    metrics.shouldMatchColumnHeights = YES;
    return metrics;
}
@end
