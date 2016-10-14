#import "WMFRelatedSearchResults.h"
#import "MWKSearchResult.h"

@interface WMFRelatedSearchResults ()

@property (nonatomic, strong, readwrite) NSURL *siteURL;
@property (nonatomic, strong, readwrite) NSArray *results;

@end

@implementation WMFRelatedSearchResults

- (instancetype)initWithURL:(NSURL *)URL results:(NSArray *)results {
    self = [super init];
    if (self) {
        self.siteURL = URL.wmf_siteURL;
        self.results = results;
    }
    return self;
}

- (NSURL *)urlForResult:(MWKSearchResult *)result {
    return [self.siteURL wmf_URLWithTitle:result.displayTitle];
}

@end
