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
 *  is also removed.  There might be times when the two are temporarily out of sync (such as when a nearby section is
 *  removed due to restricted permissions, and the explore view controller delays fetching of its preceding section,
 *  which temporarily retains it), but seeing too many of these inconsistencies in the should point to a controller
 *  being retained somewhere it shoudln't be.
 *
 *  @param sectionOrController
 */
#define WMFVerifyCacheConsistency(sectionOrController) [self verifyCacheConsistency : (sectionOrController)]
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
        self.reverseLookup                          =
            [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory | NSMapTableObjectPointerPersonality
                                  valueOptions:NSMapTableWeakMemory];
    }
    return self;
}

- (void)verifyCacheConsistency:(id)sectionOrController {
    if ([sectionOrController isKindOfClass:[WMFExploreSection class]]) {
        [self verifyCacheConsistencyForSection:sectionOrController];
    } else {
        [self verifyCacheConsistencyForController:sectionOrController];
    }
}

- (void)verifyCacheConsistencyForController:(id<WMFExploreSectionController>)controller {
    WMFExploreSection* section = [self.reverseLookup objectForKey:controller];
    if (!section) {
        // can't check controller consistency w/o a key since NSCache doesn't tell you all the objects it contains
        return;
    }
    id<WMFExploreSectionController> cacheController = [self.sectionControllersBySection objectForKey:section];
    if (!cacheController) {
        DDLogWarn(@"Reverse map contains section for controller which is no longer cached: %@", section);
    }
}

- (void)verifyCacheConsistencyForSection:(WMFExploreSection*)section {
    id<WMFExploreSectionController> reverseMapController =
        [[[self.reverseLookup keyEnumerator] allObjects] bk_match:^BOOL (id obj) {
        return [[self.reverseLookup objectForKey:obj] isEqual:section];
    }];
    id<WMFExploreSectionController> cacheController = [self.sectionControllersBySection objectForKey:section];
    if (reverseMapController != cacheController) {
        DDLogWarn(@"Mismatch between cached controllers & reverse map! Reverse map: %@ cache: %@",
                  reverseMapController, cacheController);
    }
}

- (nullable id<WMFExploreSectionController>)controllerForSection:(WMFExploreSection*)section {
    WMFVerifyCacheConsistency(section);
    return [self.sectionControllersBySection objectForKey:section];
}

- (nullable WMFExploreSection*)sectionForController:(id<WMFExploreSectionController>)controller {
    WMFVerifyCacheConsistency(controller);
    return [self.reverseLookup objectForKey:controller];
}

- (id<WMFExploreSectionController>)getOrCreateControllerForSection:(WMFExploreSection*)section
                                                     creationBlock:(nullable void (^)(id<WMFExploreSectionController> _Nonnull))creationBlock {
    id<WMFExploreSectionController> controller = [self controllerForSection:section];
    if (controller) {
        return controller;
    }
    controller = [self newControllerForSection:section];
    if (creationBlock) {
        creationBlock(controller);
    }
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
    [self.reverseLookup setObject:section forKey:controller];

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

#pragma mark - removeAllObjects

- (void)removeAllObjects {
    [self.sectionControllersBySection removeAllObjects];
}

@end

NS_ASSUME_NONNULL_END

