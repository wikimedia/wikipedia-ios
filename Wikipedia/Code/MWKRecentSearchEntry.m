#import <WMF/MWKRecentSearchEntry.h>
#import <WMF/WMFComparison.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/WMFHashing.h>

@interface MWKRecentSearchEntry ()

@property (readwrite, copy, nonatomic) NSString *searchTerm;

@end

@implementation MWKRecentSearchEntry

- (instancetype)initWithURL:(NSURL *)url searchTerm:(NSString *)searchTerm {
    url = [NSURL wmf_desktopURLForURL:url];
    NSParameterAssert(url);
    NSParameterAssert(searchTerm);
    self = [self initWithURL:url];
    if (self) {
        self.searchTerm = searchTerm;
    }
    return self;
}

- (instancetype)initWithDict:(NSDictionary *)dict {
    NSString *urlString = dict[@"url"];
    NSString *domain = dict[@"domain"];
    NSString *language = dict[@"language"];

    NSURL *url;

    if ([urlString length]) {
        url = [NSURL URLWithString:urlString];
    } else if (domain && language) {
        url = [NSURL wmf_URLWithDomain:domain language:language];
    } else {
        return nil;
    }

    NSString *searchTerm = dict[@"searchTerm"];
    self = [self initWithURL:url searchTerm:searchTerm];
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@", [super description], self.searchTerm];
}

WMF_SYNTHESIZE_IS_EQUAL(MWKRecentSearchEntry, isEqualToRecentSearch:)

- (BOOL)isEqualToRecentSearch:(MWKRecentSearchEntry *)rhs {
    return WMF_RHS_PROP_EQUAL(url, isEqual:) && WMF_RHS_PROP_EQUAL(searchTerm, isEqualToString:);
}

- (NSUInteger)hash {
    return self.searchTerm.hash ^ flipBitsWithAdditionalRotation(self.url.hash, 1);
}

#pragma mark - MWKListObject

- (id<NSCopying>)listIndex {
    return self.searchTerm;
}

- (id)dataExport {
    return @{
        @"url": [self.url absoluteString],
        @"searchTerm": self.searchTerm
    };
}

@end
