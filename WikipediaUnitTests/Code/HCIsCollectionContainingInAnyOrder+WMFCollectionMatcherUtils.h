//
//  HCIsCollectionContainingInAnyOrder+WMFCollectionMatcherUtils.h
//  Wikipedia
//
//  Created by Brian Gerstle on 3/30/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <OCHamcrest/HCIsCollectionContainingInAnyOrder.h>

@interface HCIsCollectionContainingInAnyOrder (WMFCollectionMatcherUtils)

+ (instancetype)wmf_isCollectionContainingItemsInAnyOrder:(NSArray *)itemsOrMatchers;

@end

extern id HC_containsItemsInCollectionInAnyOrder(id itemsOrMatchers);

#if HC_SHORTHAND
#define containsItemsInCollectionInAnyOrder HC_containsItemsInCollectionInAnyOrder
#endif