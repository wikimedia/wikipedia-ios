

#import "WMFRelatedSectionBlackList.h"

static NSString* const WMFRelatedSectionBlackListFileName      = @"WMFRelatedSectionBlackList";
static NSString* const WMFRelatedSectionBlackListFileExtension = @"plist";

@interface WMFRelatedSectionBlackList ()

@property (nonatomic, strong) NSMutableArray<MWKTitle*>* mutableBlackListTitles;

@end

@implementation WMFRelatedSectionBlackList

+ (instancetype)sharedBlackList {
    static WMFRelatedSectionBlackList* blackList = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        blackList = [self loadFromDisk];
        if (!blackList) {
            blackList = [[WMFRelatedSectionBlackList alloc] init];
        }
    });

    return blackList;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableBlackListTitles = [NSMutableArray array];
    }
    return self;
}

+ (NSURL*)fileURL {
    return [NSURL fileURLWithPath:[[documentsDirectory() stringByAppendingPathComponent:WMFRelatedSectionBlackListFileName] stringByAppendingPathExtension:WMFRelatedSectionBlackListFileExtension]];
}

+ (void)saveToDisk:(WMFRelatedSectionBlackList*)blackList {
    if (![NSKeyedArchiver archiveRootObject:blackList toFile:[[self fileURL] path]]) {
        //TODO: not sure what to do with an error here
        DDLogError(@"Failed to save sections to disk!");
    }
}

+ (instancetype)loadFromDisk {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[[self fileURL] path]];
}

- (void)addBlackListTitle:(MWKTitle*)title {
    @synchronized(self) {
        [self.mutableBlackListTitles addObject:title];
        [[self class] saveToDisk:self];
    }
}

- (void)removeBlackListTitle:(MWKTitle*)title {
    @synchronized(self) {
        [self.mutableBlackListTitles removeObject:title];
        [[self class] saveToDisk:self];
    }
}

- (BOOL)titleIsBlackListed:(MWKTitle*)title {
    @synchronized(self) {
        return [self.mutableBlackListTitles containsObject:title];
        [[self class] saveToDisk:self];
    }
}

- (void)removeAllTitles {
    @synchronized(self) {
        [self.mutableBlackListTitles removeAllObjects];
        [[self class] saveToDisk:self];
    }
}

- (NSArray<MWKTitle*>*)blackListTitles {
    return _mutableBlackListTitles;
}

- (NSMutableArray*)mutableBlackListTitles {
    return [self mutableArrayValueForKey:WMF_SAFE_KEYPATH(self, blackListTitles)];
}

- (NSUInteger)countOfBlackListTitles {
    return [_mutableBlackListTitles count];
}

- (id)objectInBlackListTitlesAtIndex:(NSUInteger)idx {
    return [_mutableBlackListTitles objectAtIndex:idx];
}

- (void)insertObject:(id)anObject inBlackListTitlesAtIndex:(NSUInteger)idx {
    [_mutableBlackListTitles insertObject:anObject atIndex:idx];
}

- (void)insertBlackListTitles:(NSArray*)entrieArray atIndexes:(NSIndexSet*)indexes {
    [_mutableBlackListTitles insertObjects:entrieArray atIndexes:indexes];
}

- (void)removeObjectFromBlackListTitlesAtIndex:(NSUInteger)idx {
    [_mutableBlackListTitles removeObjectAtIndex:idx];
}

- (void)removeBlackListTitlesAtIndexes:(NSIndexSet*)indexes {
    [_mutableBlackListTitles removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectInBlackListTitlesAtIndex:(NSUInteger)idx withObject:(id)anObject {
    [_mutableBlackListTitles replaceObjectAtIndex:idx withObject:anObject];
}

- (void)replaceBlackListTitlesAtIndexes:(NSIndexSet*)indexes withEntries:(NSArray*)entrieArray {
    [_mutableBlackListTitles replaceObjectsAtIndexes:indexes withObjects:entrieArray];
}

@end
