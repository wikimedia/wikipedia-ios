
#import "WMFLocationSearchResults.h"

@interface WMFLocationSearchResults ()

@property (nonatomic, strong, readwrite) CLLocation* location;
@property (nonatomic, strong, readwrite) NSArray* results;

@end

@implementation WMFLocationSearchResults

- (instancetype)initWithLocation:(CLLocation*)location results:(NSArray*)results
{
    self = [super init];
    if (self) {
        self.location = location;
        self.results = results;
    }
    return self;
}

@end
