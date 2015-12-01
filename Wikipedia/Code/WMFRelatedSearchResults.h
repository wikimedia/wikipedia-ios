
#import <Foundation/Foundation.h>
@class MWKTitle, MWKSearchResult;

@interface WMFRelatedSearchResults : NSObject

@property (nonatomic, strong, readonly) MWKTitle* title;
@property (nonatomic, strong, readonly) NSArray<MWKSearchResult*>* results;

- (instancetype)initWithTitle:(MWKTitle*)title results:(NSArray*)results;

@end
