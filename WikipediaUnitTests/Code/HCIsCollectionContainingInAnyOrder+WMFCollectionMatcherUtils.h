#import <OCHamcrest/HCIsCollectionContainingInAnyOrder.h>

@interface HCIsCollectionContainingInAnyOrder (WMFCollectionMatcherUtils)

+ (instancetype)wmf_isCollectionContainingItemsInAnyOrder:(NSArray *)itemsOrMatchers;

@end

extern id HC_containsItemsInCollectionInAnyOrder(id itemsOrMatchers);

#if HC_SHORTHAND
#define containsItemsInCollectionInAnyOrder HC_containsItemsInCollectionInAnyOrder
#endif