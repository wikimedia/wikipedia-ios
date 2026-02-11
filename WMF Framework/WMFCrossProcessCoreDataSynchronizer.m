#import <WMF/WMFCrossProcessCoreDataSynchronizer.h>
#include <notify.h>
#import <WMF/WMF-Swift.h>
#import <CoreData/CoreData.h>

@interface WMFCrossProcessCoreDataSynchronizer () {
    dispatch_semaphore_t _semaphore;
    int _token;
}

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSURL *containerURL;

@end

static uint64_t bundleHash(void) {
    static dispatch_once_t onceToken;
    static uint64_t bundleHash;
    dispatch_once(&onceToken, ^{
        bundleHash = (uint64_t)[[[NSBundle mainBundle] bundleIdentifier] hash];
    });
    return bundleHash;
}

@implementation WMFCrossProcessCoreDataSynchronizer

- (instancetype)initWithIdentifier:(NSString *)identifier storageDirectory:(NSURL *)directoryURL {
    self = [super init];
    if (self) {
        _semaphore = dispatch_semaphore_create(1);
        self.containerURL = directoryURL;
        self.identifier = identifier;
    }
    return self;
}

- (void)dealloc {
    [self stop];
}

- (void)startSynchronizingContexts:(NSArray<NSManagedObjectContext *> *)contexts {
    if (!self.identifier) {
        DDLogError(@"missing channel name");
        return;
    }
    const char *name = [self.identifier UTF8String];
    for (NSManagedObjectContext *context in contexts) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSave:) name:NSManagedObjectContextDidSaveNotification object:context];
    }
    @weakify(self)
    notify_register_dispatch(name, &_token, dispatch_get_main_queue(), ^(int token) {
        @strongify(self)
        uint64_t state;
        notify_get_state(token, &state);
        BOOL isExternal = state != bundleHash();
        if (isExternal) {
            [self readCrossProcessCoreDataNotificationWithState:state intoContexts:contexts];
        }
    });
}

- (void)stop {
    if (_token != 0) {
        notify_cancel(_token);
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Writing Changes from this Process

- (void)contextDidSave:(NSNotification *)note {
    [self writeCrossProcessCoreDataNotification:note];
}

- (void)writeCrossProcessCoreDataNotification:(NSNotification *)note {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    NSDictionary *userInfo = note.userInfo;
    if (!userInfo) {
        return;
    }

    uint64_t state = bundleHash();

    NSDictionary *archiveableUserInfo = [self archivableNotificationUserInfoForUserInfo:userInfo];
    
    NSError *archiveError = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:archiveableUserInfo requiringSecureCoding:NO error:&archiveError];
    if (archiveError) {
        DDLogError(@"Error archiving cross process changes: %@", archiveError);
        return;
    }
    
    NSURL *fileURL = [self archivedChangesFileURLWithState:state];
    [data writeToURL:fileURL atomically:YES];

    const char *name = [self.identifier UTF8String];
    notify_set_state(_token, state);
    notify_post(name);
    dispatch_semaphore_signal(_semaphore);
}

#pragma mark - Reading changes from other processes

- (void)readCrossProcessCoreDataNotificationWithState:(uint64_t)state intoContexts:(NSArray<NSManagedObjectContext *> *)contexts {
    NSURL *fileURL = [self archivedChangesFileURLWithState:state];
    NSError *unarchiveError = nil;
    NSDictionary *userInfo = [self unarchivedDictionaryFromFileURL:fileURL error:&unarchiveError];
    if (unarchiveError) {
        DDLogError(@"Error unarchiving cross process core data notification: %@", unarchiveError);
        return;
    }
    [NSManagedObjectContext mergeChangesFromRemoteContextSave:userInfo intoContexts:contexts];
}

#pragma mark - Notification Archive Utitlities

- (NSDictionary *)unarchivedDictionaryFromFileURL:(NSURL *)fileURL error:(NSError **)error {
    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    NSSet *allowedClasses = [NSSet setWithArray:[NSSecureUnarchiveFromDataTransformer allowedTopLevelClasses]];
    return [NSKeyedUnarchiver unarchivedObjectOfClasses:allowedClasses fromData:data error:error];
}

- (NSURL *)archivedChangesFileURLWithState:(uint64_t)state {
    NSString *fileName = [NSString stringWithFormat:@"%llu.%@.changes", state, self.identifier];
    return [self.containerURL URLByAppendingPathComponent:fileName isDirectory:NO];
}

- (nullable id)archiveableNotificationValueForValue:(id)value {
    if ([value isKindOfClass:[NSManagedObject class]]) {
        return [[value objectID] URIRepresentation];
    } else if ([value isKindOfClass:[NSManagedObjectID class]]) {
        return [value URIRepresentation];
    } else if ([value isKindOfClass:[NSSet class]] || [value isKindOfClass:[NSArray class]]) {
        return [value wmf_map:^id(id obj) {
            return [self archiveableNotificationValueForValue:obj];
        }];
    } else if ([value conformsToProtocol:@protocol(NSCoding)]) {
        return value;
    } else {
        return nil;
    }
}

- (NSDictionary *)archivableNotificationUserInfoForUserInfo:(NSDictionary *)userInfo {
    NSMutableDictionary *archiveableUserInfo = [NSMutableDictionary dictionaryWithCapacity:userInfo.count];
    NSArray *allKeys = userInfo.allKeys;
    for (NSString *key in allKeys) {
        id value = userInfo[key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            value = [self archivableNotificationUserInfoForUserInfo:value];
        } else {
            value = [self archiveableNotificationValueForValue:value];
        }
        if (value) {
            archiveableUserInfo[key] = value;
        }
    }
    return archiveableUserInfo;
}


@end
