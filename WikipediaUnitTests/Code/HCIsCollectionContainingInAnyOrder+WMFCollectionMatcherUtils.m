//
//  HCIsCollectionContainingInAnyOrder+WMFCollectionMatcherUtils.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/30/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "HCIsCollectionContainingInAnyOrder+WMFCollectionMatcherUtils.h"
#import <BlocksKit/BlocksKit.h>
#import <OCHamcrest/HCIsEqual.h>

id HC_containsItemsInCollectionInAnyOrder(id itemsOrMatchers) {
    return [HCIsCollectionContainingInAnyOrder wmf_isCollectionContainingItemsInAnyOrder:itemsOrMatchers];
}

@implementation HCIsCollectionContainingInAnyOrder (WMFCollectionMatcherUtils)

+ (instancetype)wmf_isCollectionContainingItemsInAnyOrder:(NSArray *)itemsOrMatchers {
    return [self isCollectionContainingInAnyOrder:[itemsOrMatchers bk_map:^id(id obj) {
                   return [obj conformsToProtocol:@protocol(HCMatcher)] ? obj : HC_equalTo(obj);
                 }]];
}

@end
