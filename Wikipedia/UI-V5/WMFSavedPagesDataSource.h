
#import <Mantle/Mantle.h>
#import "WMFArticleListDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSavedPagesDataSource : MTLModel<WMFArticleListDataSource>

@property (nonatomic, strong, readonly) MWKUserDataStore* userDataStore;

- (nonnull instancetype)initWithUserDataStore:(MWKUserDataStore*)store;

@end

NS_ASSUME_NONNULL_END