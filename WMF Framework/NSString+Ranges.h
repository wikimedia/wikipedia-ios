#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Ranges)
- (NSArray<NSValue *> *)allRangesOfSubstring: (NSString *)string;
@end

NS_ASSUME_NONNULL_END
