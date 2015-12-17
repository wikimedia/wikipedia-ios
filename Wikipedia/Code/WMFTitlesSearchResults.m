
#import "WMFTitlesSearchResults.h"

@interface WMFTitlesSearchResults ()

@property (nonatomic, strong, readwrite) NSArray<MWKTitle*>* titles;
@property (nonatomic, strong, readwrite) NSArray<MWKSearchResult*>* results;

@end

@implementation WMFTitlesSearchResults

- (instancetype)initWithTitles:(NSArray<MWKTitle*>*)titles results:(NSArray<MWKSearchResult*>*)results {
    self = [super init];
    if (self) {
        self.titles   = titles;
        self.results = results;
    }
    return self;
}

@end
