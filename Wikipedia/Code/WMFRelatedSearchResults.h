#import <Mantle/Mantle.h>
@class MWKSearchResult;

@interface WMFRelatedSearchResults : MTLModel

@property (nonatomic, strong, readonly) NSURL *siteURL;
@property (nonatomic, strong, readonly) NSArray<MWKSearchResult *> *results;

- (instancetype)initWithURL:(NSURL *)URL results:(NSArray *)results;

- (NSURL *)urlForResult:(MWKSearchResult *)result;

@end
