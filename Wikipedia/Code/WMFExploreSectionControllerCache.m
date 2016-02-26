//
//  WMFExploreSectionCache.m
//  Wikipedia
//
//  Created by Corey Floyd on 1/25/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFExploreSectionControllerCache_Testing.h"
#import "MWKSite.h"
#import "MWKDataStore.h"
#import "MWKUserDataStore.h"
#import "WMFExploreSection.h"

#import "WMFRelatedSectionBlackList.h"

#import "WMFMainPageSectionController.h"
#import "WMFNearbySectionController.h"
#import "WMFRelatedSectionController.h"
#import "WMFContinueReadingSectionController.h"
#import "WMFRandomSectionController.h"
#import "WMFFeaturedArticleSectionController.h"
#import "WMFPictureOfTheDaySectionController.h"
#import "WMFMostReadSectionController.h"

NS_ASSUME_NONNULL_BEGIN

#if DEBUG
/**
 *  @function WMFVerifyCacheConsistency
 *
 *  Verify consistency between internal `NSCache` and reverse-section-lookup `NSMapTable`.
 *
 *  Need to be sure that when the `NSCache` evicts a controller, that its corresponding entry in the reverse lookup table
 *  is also removed.  If this invariant ever fails, this macro will raise an assertion (in debug mode).
 *
 *  @param sectionOrController
 */
#define WMFVerifyCacheConsistency(sectionOrController) [self verifyCacheConsistency:(sectionOrController)]
#else
#define WMFVerifyCacheConsistency(sectionOrController)
#endif

@implementation WMFExploreSectionControllerCache

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.dataStore                              = dataStore;
        self.sectionControllersBySection            = [[NSCache alloc] init];
        self.sectionControllersBySection.countLimit = [WMFExploreSection totalMaxNumberOfSections];

        /*
         Controllers (keys in the map) are retained by the NSCache and can be evicted at any time. On the other hand,
         sections (values in the map) are "value types" which should be owned by the receiver.  In other words, sections
         are created as needed, and not retained for any particular reason, and it would be unintentional for a value in
         this map to disappear because it was dereferenced externally.
         */
        self.sectionsBySectionController            =
            [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory | NSMapTableObjectPointerPersonality
                                  valueOptions:NSMapTableStrongMemory];
    }
    return self;
}

#if DEBUG
- (void)verifyCacheConsistency:(id)sectionOrController {
    if ([sectionOrController isKindOfClass:[WMFExploreSection class]]) {
        [self verifyCacheConsistencyForSection:sectionOrController];
    } else {
        [self verifyCacheConsistencyForController:sectionOrController];
    }
}

- (void)verifyCacheConsistencyForController:(id<WMFExploreSectionController>)controller {
    WMFExploreSection* section = [self.sectionsBySectionController objectForKey:controller];
    if (!section) {
        // can't check controller consistency w/o a key since NSCache doesn't tell you all the objects it contains
        return;
    }
    id<WMFExploreSectionController> cacheController = [self.sectionControllersBySection objectForKey:section];
    NSAssert(cacheController, @"Reverse map contains section for controller which is no longer cached: %@", section);
}

- (void)verifyCacheConsistencyForSection:(WMFExploreSection*)section {
    id<WMFExploreSectionController> reverseMapController =
    [[[self.sectionsBySectionController keyEnumerator] allObjects] bk_match:^BOOL(id obj) {
        return [[self.sectionsBySectionController objectForKey:obj] isEqual:section];
    }];
    id<WMFExploreSectionController> cacheController = [self.sectionControllersBySection objectForKey:section];
    NSAssert(reverseMapController == cacheController,
             @"Mismatch between cached controllers & reverse map! Got %@ expected %@",
             cacheController, reverseMapController);

}
#endif

- (nullable id<WMFExploreSectionController>)controllerForSection:(WMFExploreSection*)section {
    WMFVerifyCacheConsistency(section);
    return [self.sectionControllersBySection objectForKey:section];
}

- (nullable WMFExploreSection*)sectionForController:(id<WMFExploreSectionController>)controller {
    WMFVerifyCacheConsistency(controller);
    return [self.sectionsBySectionController objectForKey:controller];
}

- (id<WMFExploreSectionController>)getOrCreateControllerForSection:(WMFExploreSection*)section
                                                     creationBlock:(nonnull void (^)(id<WMFExploreSectionController> _Nonnull))creationBlock {
    id<WMFExploreSectionController> controller = [self controllerForSection:section];
    if (controller) {
        return controller;
    }
    controller = [self newControllerForSection:section];
    creationBlock(controller);
    return controller;
}

- (id<WMFExploreSectionController>)newControllerForSection:(WMFExploreSection*)section {
    NSAssert(![self.sectionControllersBySection objectForKey:section],
             @"Invalid request to create a new section controller for section %@ when one already exists: %@",
             section, [self.sectionControllersBySection objectForKey:section]);

    id<WMFExploreSectionController> controller;
    switch (section.type) {
        case WMFExploreSectionTypeHistory:
        case WMFExploreSectionTypeSaved:
            controller = [self relatedSectionControllerForSectionSchemaItem:section];
            break;
        case WMFExploreSectionTypeNearby:
            controller = [self nearbySectionControllerForSchemaItem:section];
            break;
        case WMFExploreSectionTypeContinueReading:
            controller = [self continueReadingSectionControllerForSchemaItem:section];
            break;
        case WMFExploreSectionTypeRandom:
            controller = [self randomSectionControllerForSchemaItem:section];
            break;
        case WMFExploreSectionTypeMainPage:
            controller = [self mainPageSectionControllerForSchemaItem:section];
            break;
        case WMFExploreSectionTypeFeaturedArticle:
            controller = [self featuredArticleSectionControllerForSchemaItem:section];
            break;
        case WMFExploreSectionTypePictureOfTheDay:
            controller = [self picOfTheDaySectionControllerForSchemaItem:section];
            break;
        case WMFExploreSectionTypeMostRead:
            controller = [self mostReadSectionControllerForSection:section];
            /*
               !!!: do not add a default case, it is intentionally omitted so an error/warning is triggered when
               a new case is added to the enum, enforcing that all sections are handled here.
             */
    }

    [self.sectionControllersBySection setObject:controller forKey:section];
    [self.sectionsBySectionController setObject:section forKey:controller];

    return controller;
}

#pragma mark - Section Controller Creation

- (WMFMostReadSectionController*)mostReadSectionControllerForSection:(WMFExploreSection*)section {
    return [[WMFMostReadSectionController alloc] initWithDate:section.mostReadFetchDate
                                                         site:section.site
                                                    dataStore:self.dataStore];
}

- (WMFRelatedSectionController*)relatedSectionControllerForSectionSchemaItem:(WMFExploreSection*)item {
    return [[WMFRelatedSectionController alloc] initWithArticleTitle:item.title blackList:[WMFRelatedSectionBlackList sharedBlackList] dataStore:self.dataStore];
}

- (WMFContinueReadingSectionController*)continueReadingSectionControllerForSchemaItem:(WMFExploreSection*)item {
    return [[WMFContinueReadingSectionController alloc] initWithArticleTitle:item.title dataStore:self.dataStore];
}

- (WMFNearbySectionController*)nearbySectionControllerForSchemaItem:(WMFExploreSection*)item {
    return [[WMFNearbySectionController alloc] initWithLocation:item.location
                                                      placemark:item.placemark
                                                           site:item.site
                                                      dataStore:self.dataStore];
}

- (WMFRandomSectionController*)randomSectionControllerForSchemaItem:(WMFExploreSection*)item {
    return [[WMFRandomSectionController alloc] initWithSite:item.site dataStore:self.dataStore];
}

- (WMFMainPageSectionController*)mainPageSectionControllerForSchemaItem:(WMFExploreSection*)item {
    return [[WMFMainPageSectionController alloc] initWithSite:item.site dataStore:self.dataStore];
}

- (WMFPictureOfTheDaySectionController*)picOfTheDaySectionControllerForSchemaItem:(WMFExploreSection*)item  {
    return [[WMFPictureOfTheDaySectionController alloc] initWithDataStore:self.dataStore date:item.dateCreated];
}

- (WMFFeaturedArticleSectionController*)featuredArticleSectionControllerForSchemaItem:(WMFExploreSection*)item {
    return [[WMFFeaturedArticleSectionController alloc] initWithSite:item.site date:item.dateCreated dataStore:self.dataStore];
}

@end

NS_ASSUME_NONNULL_END

