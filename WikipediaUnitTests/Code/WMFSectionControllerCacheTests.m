@import Quick;
@import Nimble;

#import "WMFExploreSectionControllerCache_Testing.h"
#import "WMFExploreSection.h"
#import "MWKDataStore+TempDataStoreForEach.h"

QuickSpecBegin(WMFExploreSectionControllerCacheTests)

    __block WMFExploreSectionControllerCache *controllerCache;

configureTempDataStoreForEach(tempDataStore, ^{
  controllerCache = [[WMFExploreSectionControllerCache alloc] initWithDataStore:tempDataStore];
});

describe(@"cache invalidation", ^{
  __block WMFExploreSection *cachedSection = [WMFExploreSection pictureOfTheDaySectionWithDate:[NSDate date]];
  __block __weak id<WMFExploreSectionController> weakCachedController;

  beforeEach(^{
    id<WMFExploreSectionController> controller = [controllerCache getOrCreateControllerForSection:cachedSection
                                                                                    creationBlock:nil];
    weakCachedController = controller;
  });

  it(@"it should not have a section for that controller when the controller is removed from cache", ^{
    // when internal cache is purged
    [controllerCache.sectionControllersBySection removeAllObjects];
    expect([controllerCache controllerForSection:cachedSection]).to(beNil());

    expect(weakCachedController)
        .toEventuallyWithDescription(beNil(), @"Purged controller should have been deallocated!");

    expect([controllerCache.reverseLookup objectForKey:cachedSection])
        .toEventuallyWithDescription(beNil(), @"Internal reverse map of sections to controllers should also be empty!");
  });
});

QuickSpecEnd
