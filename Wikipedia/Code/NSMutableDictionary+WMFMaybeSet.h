@import Foundation;

@interface NSMutableDictionary (WMFMaybeSet)

- (BOOL)wmf_maybeSetObject:(id)obj forKey:(id<NSCopying>)key;

@end
