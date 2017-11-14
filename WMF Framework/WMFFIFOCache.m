#import <WMF/WMFFIFOCache.h>

@interface WMFFIFOCache () {
    NSInteger _countLimit;
    dispatch_semaphore_t _semaphore;
}

@property (nonatomic, strong) NSMutableDictionary *objectsByKey;
@property (nonatomic, strong) NSMutableOrderedSet *keys;

@end

@implementation WMFFIFOCache

- (instancetype)init {
    return [self initWithCountLimit:10];
}

- (instancetype)initWithCountLimit:(NSUInteger)countLimit {
    self = [super init];
    if (self) {
        _semaphore = dispatch_semaphore_create(1);
        self.countLimit = countLimit;
        self.objectsByKey = [NSMutableDictionary dictionaryWithCapacity:countLimit];
        self.keys = [NSMutableOrderedSet orderedSetWithCapacity:countLimit];
    }
    return self;
}

- (nullable id)objectForKey:(id)key {
    if (!key) {
        return nil;
    }
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    id object = self.objectsByKey[key];
    dispatch_semaphore_signal(_semaphore);
    return object;
}

- (void)setObject:(id)obj forKey:(id)key {
    if (!key) {
        return;
    }
    if (!obj) {
        [self removeObjectForKey:key];
        return;
    }
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    self.objectsByKey[key] = obj;
    if ([self.keys containsObject:key]) { // NSOrderedSet will no-op when adding an object that is already in the set. This ensures the most recently requested path goes to the end of the ordered set.
        [self.keys removeObject:key];
    }
    [self.keys addObject:key];
    if (self.keys.count > self.countLimit) {
        id keyToRemove = self.keys[0];
        [self.objectsByKey removeObjectForKey:keyToRemove];
        [self.keys removeObjectAtIndex:0];
    }
    dispatch_semaphore_signal(_semaphore);
}

- (void)removeObjectForKey:(id)key {
    if (!key) {
        return;
    }
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    [self.objectsByKey removeObjectForKey:key];
    dispatch_semaphore_signal(_semaphore);
}

- (void)removeAllObjects {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    [self.objectsByKey removeAllObjects];
    dispatch_semaphore_signal(_semaphore);
}

- (void)setCountLimit:(NSUInteger)countLimit {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    _countLimit = countLimit;
    dispatch_semaphore_signal(_semaphore);
}

- (NSUInteger)countLimit {
    return _countLimit;
}

@end
