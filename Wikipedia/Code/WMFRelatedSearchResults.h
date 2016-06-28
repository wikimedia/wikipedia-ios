
#import <Foundation/Foundation.h>
@class MWKTitle, MWKSearchResult;

@interface WMFRelatedSearchResults : NSObject

@property (nonatomic, strong, readonly) NSURL* domainURL;
@property (nonatomic, strong, readonly) NSArray<MWKSearchResult*>* results;

- (instancetype)initWithURL:(NSURL*)URL results:(NSArray*)results;

@end
