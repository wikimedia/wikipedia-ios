#import "MWKListSharedTests.h"

@interface MWKSavedPageListSharedTests : MWKListSharedTests

@end

@implementation MWKSavedPageListSharedTests

+ (Class)listClass {
  return [MWKSavedPageList class];
}

+ (id)uniqueListEntry {
  return [[MWKSavedPageEntry alloc] initWithURL:[NSURL wmf_randomArticleURL]];
}

@end
