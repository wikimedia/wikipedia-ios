#import <Foundation/Foundation.h>
#import <WMF/WMFContentSource.h>

@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSuggestedEditsContentSource : NSObject <WMFContentSource>
@property (readonly, nonatomic, strong) NSURL *siteURL;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
