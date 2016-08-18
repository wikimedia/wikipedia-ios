#import <Foundation/Foundation.h>
#import "MWKDataStore.h"
#import "WMFDataSource.h"

@class YapDatabaseConnection;
@class YapDatabaseViewMappings;

NS_ASSUME_NONNULL_BEGIN

@interface WMFDatabaseDataSource : NSObject <WMFDataSource, WMFDatabaseChangeHandler>

@property (readonly, weak, nonatomic) YapDatabaseConnection* readConnection;
@property (readonly, weak, nonatomic) YapDatabaseConnection* writeConnection;

@property (readonly, strong, nonatomic) YapDatabaseViewMappings* mappings;

- (instancetype)initWithReadConnection:(YapDatabaseConnection*)readConnection writeConnection:(YapDatabaseConnection*)writeConnection mappings:(YapDatabaseViewMappings*)mappings NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;


@end

NS_ASSUME_NONNULL_END