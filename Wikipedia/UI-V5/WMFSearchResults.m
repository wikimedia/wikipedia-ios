
#import "WMFSearchResults.h"
#import "WMFSearchResultCell.h"
#import "MWKArticle.h"
#import "MWKTitle.h"
#import "UIView+WMFDefaultNib.h"
#import "MWKSearchResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchResults ()

@property (nonatomic, copy, readwrite) NSString* searchTerm;
@property (nonatomic, copy, nullable, readwrite) NSString* searchSuggestion;
@property (nonatomic, strong, readwrite) NSArray* results;

@end

@implementation WMFSearchResults

- (instancetype)initWithSearchTerm:(NSString*)searchTerm
                           results:(nullable NSArray*)results
                  searchSuggestion:(nullable NSString*)suggestion {
    self = [super init];
    if (self) {
        self.searchTerm       = searchTerm;
        self.results          = results;
        self.searchSuggestion = suggestion;
    }
    return self;
}

+ (NSValueTransformer*)resultsJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSDictionary* value, BOOL* success, NSError* __autoreleasing* error) {
        NSArray* pages = [value allValues];
        NSValueTransformer* transformer = [MTLJSONAdapter arrayTransformerWithModelClass:[MWKSearchResult class]];
        return [transformer transformedValue:pages];
    }];
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    return @{
               WMF_SAFE_KEYPATH(WMFSearchResults.new, results): @"pages",
               WMF_SAFE_KEYPATH(WMFSearchResults.new, searchSuggestion): @"searchinfo.suggestion",
    };
}

@end

NS_ASSUME_NONNULL_END
