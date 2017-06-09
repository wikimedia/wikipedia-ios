@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

@class MWKLocationSearchResult;

@interface WMFLocationSearchResults : NSObject

@property (nonatomic, strong, readonly) NSURL *searchSiteURL;
@property (nonatomic, copy, readonly) CLCircularRegion *region;
@property (nullable, nonatomic, copy, readonly) NSString *searchTerm;
@property (nonatomic, strong, readonly) NSArray<MWKLocationSearchResult *> *results;

- (instancetype)initWithSearchSiteURL:(NSURL *)url region:(CLCircularRegion *)region searchTerm:(nullable NSString *)searchTerm results:(NSArray<MWKLocationSearchResult *> *)results;

- (NSURL *)urlForResult:(MWKLocationSearchResult *)result;

- (NSURL *)urlForResultAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
