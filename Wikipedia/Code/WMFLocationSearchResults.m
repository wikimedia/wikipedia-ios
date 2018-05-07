#import <WMF/WMFLocationSearchResults.h>
#import <WMF/MWKLocationSearchResult.h>
#import <WMF/WMFComparison.h>
#import <WMF/NSURL+WMFLinkParsing.h>

@interface WMFLocationSearchResults ()

@property (nonatomic, strong, readwrite) NSURL *searchSiteURL;
@property (nonatomic, copy, readwrite) CLCircularRegion *region;
@property (nullable, nonatomic, copy, readwrite) NSString *searchTerm;
@property (nonatomic, strong, readwrite) NSArray<MWKLocationSearchResult *> *results;

@end

@implementation WMFLocationSearchResults

- (instancetype)initWithSearchSiteURL:(NSURL *)url region:(CLCircularRegion *)region searchTerm:(nullable NSString *)searchTerm results:(NSArray<MWKLocationSearchResult *> *)results {
    self = [super init];
    if (self) {
        self.searchSiteURL = url;
        self.region = region;
        self.searchTerm = searchTerm;
        self.results = [results sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:WMF_SAFE_KEYPATH([MWKLocationSearchResult new], distanceFromQueryCoordinates) ascending:YES]]];
        ;
    }
    return self;
}

- (NSURL *)urlForResultAtIndex:(NSUInteger)index {
    return [self urlForResult:self.results[index]];
}

- (NSURL *)urlForResult:(MWKLocationSearchResult *)result {
    return [result articleURLForSiteURL:self.searchSiteURL];
}

@end
