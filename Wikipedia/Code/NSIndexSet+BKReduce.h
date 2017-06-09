@import Foundation;

@interface NSIndexSet (BKReduce)

- (id)wmf_reduce:(id)acc withBlock:(id (^)(id acc, NSUInteger idx))reducer;

@end
