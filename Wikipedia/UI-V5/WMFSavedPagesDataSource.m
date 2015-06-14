
#import "WMFSavedPagesDataSource.h"
#import "MWKUserDataStore.h"
#import "MWKSavedPageList.h"
#import "MWKSavedPageEntry.h"
#import "MWKArticle.h"

@interface WMFSavedPagesDataSource ()

@property (nonatomic, strong, readwrite) MWKUserDataStore* userDataStore;

@end

@implementation WMFSavedPagesDataSource

- (instancetype)initWithUserDataStore:(MWKUserDataStore*)store {
    self = [super init];
    if (self) {
        self.userDataStore = store;
    }
    return self;
}

- (NSString*)displayTitle {
    return MWLocalizedString(@"saved-pages-title", nil);
}

- (NSUInteger)articleCount {
    return [[self savedPages] length];
}

- (MWKSavedPageList*)savedPages {
    return [self.userDataStore savedPageList];
}

- (MWKSavedPageEntry*)savedPageForIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self.savedPages entryAtIndex:indexPath.row];
    return savedEntry;
}

- (MWKArticle*)articleForIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self savedPageForIndexPath:indexPath];
    return [self.userDataStore.dataStore articleWithTitle:savedEntry.title];
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath {
    return YES;
}

- (void)deleteArticleAtIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self savedPageForIndexPath:indexPath];
    if (savedEntry) {
        [self.savedPages removeEntry:savedEntry];
        [self.userDataStore save];
    }
}

@end
