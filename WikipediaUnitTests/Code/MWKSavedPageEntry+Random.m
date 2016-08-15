#import "MWKSavedPageEntry+Random.h"
#import "MWKSite+Random.h"

@implementation MWKSavedPageEntry (Random)

+ (instancetype)random {
    MWKSavedPageEntry *entry = [[MWKSavedPageEntry alloc] initWithURL:[NSURL wmf_randomArticleURL]];
    return entry;
}

@end
