#import <Foundation/Foundation.h>

@interface NSMutableDictionary (WMFMaybeSet)

- (BOOL)wmf_maybeSetObject:(id)obj forKey:(id<NSCopying>)key;

@end
