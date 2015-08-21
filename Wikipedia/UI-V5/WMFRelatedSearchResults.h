
#import <Foundation/Foundation.h>
@class MWKTitle;

@interface WMFRelatedSearchResults : NSObject

@property (nonatomic, strong, readonly) MWKTitle* title;
@property (nonatomic, strong, readonly) NSArray* results;

- (instancetype)initWithTitle:(MWKTitle*)title results:(NSArray*)results;

@end
