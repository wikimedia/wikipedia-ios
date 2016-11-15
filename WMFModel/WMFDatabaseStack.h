
#import <Foundation/Foundation.h>

@class YapDatabase, MWKDataStore, WMFArticlePreviewDataStore, WMFContentGroupDataStore;

@interface WMFDatabaseStack : NSObject

@property (nonatomic, strong, readonly) YapDatabase *database;

@property (nonatomic, strong, readonly) MWKDataStore *userStore;
@property (nonatomic, strong, readonly) WMFArticlePreviewDataStore *previewStore;
@property (nonatomic, strong, readonly) WMFContentGroupDataStore *contentStore;
@property (nonatomic, strong, readonly) WMFContentGroupDataStore *exploreUIContentStore;

+ (WMFDatabaseStack *)sharedInstance;

- (void)setupStack;
- (void)tearDownStack;

@end
