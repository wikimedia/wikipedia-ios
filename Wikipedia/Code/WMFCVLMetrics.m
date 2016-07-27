#import "WMFCVLMetrics.h"

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
    return copy;
}

@end
