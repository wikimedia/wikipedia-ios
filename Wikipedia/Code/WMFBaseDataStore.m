
#import "WMFBaseDataStore.h"
#import "YapDatabase+WMFExtensions.h"
#import "YapDatabase+WMFViews.h"
#import "YapDatabaseConnection+WMFExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFBaseDataStore ()

@property (readwrite, strong, nonatomic) YapDatabase *database;

@property (readwrite, strong, nonatomic) YapDatabaseConnection *readConnection;
@property (readwrite, strong, nonatomic) YapDatabaseConnection *writeConnection;

@property (readwrite, nonatomic, strong) NSPointerArray *changeHandlers;

@end

@implementation WMFBaseDataStore

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [self initWithDatabase:[YapDatabase sharedInstance]];
    if (self) {
    }
    return self;
}

- (instancetype)initWithDatabase:(YapDatabase *)database {
    NSParameterAssert(database);
    self = [super init];
    if (self) {
        self.database = database;
        self.changeHandlers = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsWeakMemory];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(yapDatabaseModified:)
                                                     name:YapDatabaseModifiedNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - ChangeHandlers

- (void)registerChangeHandler:(id<WMFDatabaseChangeHandler>)handler {
    [self.changeHandlers addPointer:(__bridge void *_Nullable)(handler)];
}


#pragma mark - Read/Write

- (void)readWithBlock:(void (^)(YapDatabaseReadTransaction* _Nonnull transaction))block{
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        block(transaction);
    }];
}

- (nullable id)readAndReturnResultsWithBlock:(id (^)(YapDatabaseReadTransaction* _Nonnull transaction))block{
    return [self.readConnection wmf_readAndReturnResultsWithBlock:block];
}

- (void)readViewNamed:(NSString*)viewName withWithBlock:(void (^)(YapDatabaseReadTransaction* _Nonnull transaction, YapDatabaseViewTransaction* _Nonnull view))block{
    [self.readConnection wmf_readInViewWithName:viewName withBlock:block];
}

- (nullable id)readAndReturnResultsWithViewNamed:(NSString*)viewName withWithBlock:(id (^)(YapDatabaseReadTransaction* _Nonnull transaction, YapDatabaseViewTransaction* _Nonnull view))block{
    return [self.readConnection wmf_readAndReturnResultsInViewWithName:viewName withBlock:block];
}


- (void)readWriteWithBlock:(void (^)(YapDatabaseReadWriteTransaction* _Nonnull transaction))block{
    [self.writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        block(transaction);
    }];
}


#pragma mark - YapDatabaseModified Notification

- (void)yapDatabaseModified:(NSNotification *)notification {
    
    // Jump to the most recent commit.
    // End & Re-Begin the long-lived transaction atomically.
    // Also grab all the notifications for all the commits that I jump.
    // If the UI is a bit backed up, I may jump multiple commits.
    NSArray *notifications = [self.readConnection beginLongLivedReadTransaction];
    if ([notifications count] == 0) {
        return;
    }
    
    [self.changeHandlers compact];
    for (id<WMFDatabaseChangeHandler> obj in self.changeHandlers) {
        [obj processChanges:notifications onConnection:self.readConnection];
    }
    
    [self dataStoreWasUpdatedWithNotification:notification];
}

- (void)dataStoreWasUpdatedWithNotification:(NSNotification*)notification{

}


@end

NS_ASSUME_NONNULL_END
