#import "WMFSearchResults.h"

@interface WMFSearchResults (WMFInternal)

@property (nonatomic, copy, readwrite) NSString *searchTerm;
@property (nonatomic, copy, nullable, readwrite) NSString *prefixSearchID;
@property (nonatomic, copy, nullable, readwrite) NSString *fullTextSearchID;

@end
