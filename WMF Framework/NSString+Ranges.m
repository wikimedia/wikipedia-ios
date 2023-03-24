#import "NSString+Ranges.h"

@implementation NSString (Ranges)

- (NSArray<NSValue *> *)allRangesOfSubstring: (NSString *)substring {
    NSError *error = NULL;
        
    NSString *regex = [NSString stringWithFormat:@"%@", substring];
    NSRegularExpression *regExpression = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSMutableArray *ranges = [NSMutableArray array];
    
    NSArray *matches = [regExpression matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    
    for (NSTextCheckingResult *match in matches) {
        [ranges addObject:[NSValue valueWithRange:match.range]];
    }
    return ranges;
}
@end
