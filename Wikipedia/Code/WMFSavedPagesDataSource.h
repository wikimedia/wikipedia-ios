#import <SSDataSources/SSDataSources.h>
#import "WMFTitleListDataSource.h"

@class MWKSavedPageList;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSavedPagesDataSource : SSArrayDataSource <WMFTitleListDataSource>

@property(nonatomic, strong, readonly) NSArray *articles;
@property(nonatomic, strong, readonly) MWKSavedPageList *savedPageList;

- (nonnull instancetype)initWithSavedPagesList:(MWKSavedPageList *)savedPages;

@end

NS_ASSUME_NONNULL_END