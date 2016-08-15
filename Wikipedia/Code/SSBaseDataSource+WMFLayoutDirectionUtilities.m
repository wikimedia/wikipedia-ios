#import "SSBaseDataSource+WMFLayoutDirectionUtilities.h"

@implementation SSBaseDataSource (WMFLayoutDirectionUtilities)

- (NSUInteger)wmf_startingIndexForApplicationLayoutDirection {
    return [self wmf_startingIndexForLayoutDirection:
                     [[UIApplication sharedApplication] userInterfaceLayoutDirection]];
}

- (NSUInteger)wmf_startingIndexForLayoutDirection:(UIUserInterfaceLayoutDirection)layoutDirection {
    return layoutDirection == UIUserInterfaceLayoutDirectionRightToLeft ? self.numberOfItems - 1 : 0;
}

@end
