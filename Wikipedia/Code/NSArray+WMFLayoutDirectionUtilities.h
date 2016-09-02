#import <Foundation/Foundation.h>

@interface NSArray (WMFLayoutDirectionUtilities)

- (NSUInteger)wmf_startingIndexForApplicationLayoutDirection;

- (NSUInteger)wmf_startingIndexForLayoutDirection:(UIUserInterfaceLayoutDirection)layoutDirection;

- (instancetype)wmf_reverseArrayIfApplicationIsRTL;

- (instancetype)wmf_reverseArrayIfRTL:(UIUserInterfaceLayoutDirection)layoutDirection;

@end
