
#import "WMFRelatedSearchResults.h"

@interface WMFRelatedSearchResults ()

@property (nonatomic, strong, readwrite) MWKTitle* title;
@property (nonatomic, strong, readwrite) NSArray* results;

@end

@implementation WMFRelatedSearchResults

- (instancetype)initWithTitle:(MWKTitle*)title results:(NSArray*)results {
    self = [super init];
    if (self) {
        self.title   = title;
        self.results = results;
    }
    return self;
}

@end
