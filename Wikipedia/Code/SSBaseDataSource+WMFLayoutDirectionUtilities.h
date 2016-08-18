#import <SSDataSources/SSDataSources.h>

@interface SSBaseDataSource (WMFLayoutDirectionUtilities)

- (NSUInteger)wmf_startingIndexForApplicationLayoutDirection;

- (NSUInteger)wmf_startingIndexForLayoutDirection:(UIUserInterfaceLayoutDirection)layoutDirection;

@end
