
#import <Mantle/Mantle.h>
#import "WMFArticleListDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSavedPagesDataSource : MTLModel<WMFArticleListDataSource>

/**
 *  Observable
 */
@property (nonatomic, strong, readonly) NSArray* articles;

@property (nonatomic, strong, readonly) MWKSavedPageList* savedPages;

- (nonnull instancetype)initWithSavedPagesList:(MWKSavedPageList*)savedPages;

@end

NS_ASSUME_NONNULL_END