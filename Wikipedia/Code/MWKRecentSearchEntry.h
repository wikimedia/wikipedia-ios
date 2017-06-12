#import <WMF/MWKSiteDataObject.h>
#import <WMF/MWKList.h>

@interface MWKRecentSearchEntry : MWKSiteDataObject <MWKListObject>

@property (readonly, copy, nonatomic) NSString *searchTerm;

- (instancetype)initWithURL:(NSURL *)url searchTerm:(NSString *)searchTerm;
- (instancetype)initWithDict:(NSDictionary *)dict;

@end
