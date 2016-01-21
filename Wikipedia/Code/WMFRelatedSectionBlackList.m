

#import "WMFRelatedSectionBlackList.h"
#import "MWKList+Subclass.h"

static NSString* const WMFRelatedSectionBlackListFileName      = @"WMFRelatedSectionBlackList";
static NSString* const WMFRelatedSectionBlackListFileExtension = @"plist";

@implementation MWKTitle (MWKListObject)

- (id <NSCopying, NSObject>)listIndex {
    return self;
}
@end

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

+ (NSURL*)fileURL {
    return [NSURL fileURLWithPath:[[documentsDirectory() stringByAppendingPathComponent:WMFRelatedSectionBlackListFileName] stringByAppendingPathExtension:WMFRelatedSectionBlackListFileExtension]];
}

- (void)performSaveWithCompletion:(dispatch_block_t)completion error:(WMFErrorHandler)errorHandler {
    @synchronized(self) {
        if (![NSKeyedArchiver archiveRootObject:self toFile:[[[self class] fileURL] path]]) {
            //TODO: not sure what to do with an error here
            DDLogError(@"Failed to save sections to disk!");
            if (errorHandler) {
                errorHandler([NSError wmf_unableToSaveErrorWithReason:@"NSKeyedArchiver failed to save blacklist to disk"]);
            }
        } else {
            if (completion) {
                completion();
            }
        }
    }
}

+ (instancetype)loadFromDisk {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[[self fileURL] path]];
}

- (void)addBlackListTitle:(MWKTitle*)title {
    @synchronized(self) {
        [self addEntry:title];
    }
}

- (void)removeBlackListTitle:(MWKTitle*)title {
    @synchronized(self) {
        [self removeEntry:title];
    }
}

- (BOOL)titleIsBlackListed:(MWKTitle*)title {
    @synchronized(self) {
        return [self containsEntryForListIndex:title];
    }
}

@end
