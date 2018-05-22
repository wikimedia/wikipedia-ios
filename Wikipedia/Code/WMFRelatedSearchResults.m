#import <WMF/WMFRelatedSearchResults.h>
#import <WMF/MWKSearchResult.h>
#import <WMF/NSURL+WMFLinkParsing.h>

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
    return [result articleURLForSiteURL:self.siteURL];
}

@end
