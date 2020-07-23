#import "WMFMTLModel.h"

@implementation WMFMTLModel

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
}

+ (NSMutableDictionary <NSString *, NSDictionary *>*)allowedSecureCodingClassesByPropertyKeyCache {
    static dispatch_once_t onceToken;
    static NSMutableDictionary *cache;
    dispatch_once(&onceToken, ^{
        cache = [NSMutableDictionary new];
    });
    return cache;
}

+ (NSDictionary *)allowedSecureCodingClassesByPropertyKey {
    NSString *className = NSStringFromClass([self class]);
    NSMutableDictionary *cache = [self allowedSecureCodingClassesByPropertyKeyCache];
    NSDictionary *cached = cache[className];
    if (cached) {
        return cached;
    }
    NSMutableDictionary *superAllowed = [[super allowedSecureCodingClassesByPropertyKey] mutableCopy];
    NSArray *keys = [superAllowed allKeys];
    for (NSString *key in keys) {
        NSMutableArray *superArray = [superAllowed[key] mutableCopy];
        [superArray addObject:[WMFMTLModel class]];
        superAllowed[key] = superArray;
    }
    NSDictionary *allowed = [superAllowed copy];
    [cache setValue:allowed forKey:className];
    return allowed;
}

@end
