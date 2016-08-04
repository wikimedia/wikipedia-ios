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
    BOOL isPad = boundsSize.width >= 600;
    metrics.numberOfColumns = isPad ? 2 : 1;
    metrics.columnWeights = isPad ? @[@1, @1] : @[@1];
    metrics.interColumnSpacing = isPad ? 22 : 0;
    metrics.interItemSpacing = 1;
    metrics.interSectionSpacing = isPad ? 22 : 50;
    metrics.contentInsets = isPad ? UIEdgeInsetsMake(22, 22, 22, 22) : UIEdgeInsetsMake(0, 0, 50, 0);
    metrics.sectionInsets = UIEdgeInsetsMake(1, 0, 1, 0);
    return metrics;
}

@end


