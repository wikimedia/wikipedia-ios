#import <WMF/WMFContinueReadingContentSource.h>
#import <WMF/MWKDataStore.h>
#import <WMF/WMF-Swift.h>
@import WMFData;

NS_ASSUME_NONNULL_BEGIN

@interface WMFContinueReadingContentSource ()

@property (readwrite, nonatomic, weak) MWKDataStore *userDataStore;

@end

@implementation WMFContinueReadingContentSource

- (instancetype)initWithUserDataStore:(MWKDataStore *)userDataStore {
    NSParameterAssert(userDataStore);
    self = [super init];
    if (self) {
        self.userDataStore = userDataStore;
    }
    return self;
}

#pragma mark - WMFContentSource

- (void)startUpdating {
}

- (void)stopUpdating {
}

// The Home tab replaces the Explore feed's Continue Reading card (it lives in For You),
// so this source only clears any Continue Reading groups left over from earlier versions.
- (void)loadNewContentInManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {

    [moc performBlock:^{
        NSArray<WMFContentGroup *> *existingGroups = [moc contentGroupsOfKind:WMFContentGroupKindContinueReading];
        for (WMFContentGroup *group in existingGroups) {
            [moc removeContentGroup:group];
        }
        if (completion) {
            completion();
        }
    }];
}

- (void)removeAllContentInManagedObjectContext:(NSManagedObjectContext *)moc {
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindContinueReading];
}

@end

NS_ASSUME_NONNULL_END
