#import <SSDataSources/SSDataSources.h>
#import "WMFArticleListDataSource.h"

@class MWKSavedPageList;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSavedPagesDataSource : SSArrayDataSource<WMFArticleListDataSource>

@property (nonatomic, strong, readonly) NSArray* articles;
@property (nonatomic, strong, readonly) MWKSavedPageList* savedPageList;

- (nonnull instancetype)initWithSavedPagesList:(MWKSavedPageList*)savedPages;

@end

NS_ASSUME_NONNULL_END