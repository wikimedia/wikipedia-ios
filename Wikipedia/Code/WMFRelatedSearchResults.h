
#import <Foundation/Foundation.h>
@class MWKSearchResult;

@interface WMFRelatedSearchResults : NSObject

@property (nonatomic, strong, readonly) NSURL* siteURL;
@property (nonatomic, strong, readonly) NSArray<MWKSearchResult*>* results;

- (instancetype)initWithURL:(NSURL*)URL results:(NSArray*)results;

@end
