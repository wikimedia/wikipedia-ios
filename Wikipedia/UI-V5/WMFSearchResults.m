
#import "WMFSearchResults.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchResults ()

@property (nonatomic, copy, readwrite) NSString* searchTerm;
@property (nonatomic, strong, nullable, readwrite) NSArray* resultArticles;
@property (nonatomic, copy, nullable, readwrite) NSString* searchSuggestion;

@end

@implementation WMFSearchResults

- (instancetype)initWithSearchTerm:(NSString*)searchTerm articles:(nullable NSArray*)articles searchSuggestion:(nullable NSString*)suggestion{

    self = [super init];
    if (self) {
        self.searchTerm = searchTerm;
        self.resultArticles = articles;
        self.searchSuggestion = suggestion;
    }
    return self;
}

- (nullable NSString*)displayTitle{
    return self.searchTerm;
}

- (NSUInteger)articleCount{
    return [self.resultArticles count];
}

- (MWKArticle*)articleForIndexPath:(NSIndexPath*)indexPath {
    return self.resultArticles[indexPath.row];
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath{
    return NO;
}


- (BOOL)noResults{
    
    if(self.searchTerm && [self.resultArticles count] == 0){
        return YES;
    }
    return NO;
}


@end

NS_ASSUME_NONNULL_END
