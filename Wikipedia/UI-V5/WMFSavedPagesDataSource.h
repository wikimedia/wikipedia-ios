
#import <Foundation/Foundation.h>
#import "WMFArticleListCollectionViewController.h"

@interface WMFSavedPagesDataSource : NSObject<WMFArticleListDataSource>

@property (nonatomic, strong, readonly) MWKUserDataStore* userDataStore;

- (instancetype)initWithUserDataStore:(MWKUserDataStore*)store;

@end
