
#import "WMFRelatedSearchResults.h"

@interface WMFRelatedSearchResults ()

@property (nonatomic, strong, readwrite) NSURL* domainURL;
@property (nonatomic, strong, readwrite) NSArray* results;

@end

@implementation WMFRelatedSearchResults

- (instancetype)initWithURL:(NSURL*)URL results:(NSArray*)results {
    self = [super init];
    if (self) {
        self.domainURL = URL.wmf_domainURL;
        self.results   = results;
    }
    return self;
}

@end
