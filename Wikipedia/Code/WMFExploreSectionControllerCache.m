#import "WMFExploreSectionControllerCache_Testing.h"
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

#define VERIFY_CACHE_CONSISTENCY DEBUG && 0

#if VERIFY_CACHE_CONSISTENCY
/**
 *  @function WMFVerifyCacheConsistency
 *
 *  Verify consistency between forward and reverse lookup.
 *
 *  @param sectionOrController
 */
#define WMFVerifyCacheConsistency(sectionOrController) [self verifyCacheConsistency:(sectionOrController)]
#else
#define WMFVerifyCacheConsistency(sectionOrController)
#endif

@implementation WMFExploreSectionControllerCache

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
        self.sectionControllersBySection = [[NSMutableDictionary alloc] init];
        self.reverseLookup = [[NSMutableDictionary alloc] init];
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
    WMFExploreSection *section = [self.reverseLookup objectForKey:@([controller hash])];
    if (!section) {
        if ([self.sectionControllersBySection.allValues containsObject:controller]) {
            DDLogWarn(@"Reverse map is missing a section for controller: %@", controller);
        }
        return;
    }
    id<WMFExploreSectionController> cacheController = [self.sectionControllersBySection objectForKey:section];
    if (!cacheController) {
        DDLogWarn(@"Reverse map contains section for controller which is no longer cached: %@", section);
    }
}

- (void)verifyCacheConsistencyForSection:(WMFExploreSection *)section {
    id<WMFExploreSectionController> cacheController = [self.sectionControllersBySection objectForKey:section];
    if (!cacheController) {
        if ([self.reverseLookup.allValues containsObject:section]) {
            DDLogWarn(@"Reverse map contains section for controller which is no longer cached: %@", section);
        }
        return;
    }
    WMFExploreSection *reverseSection = [self.reverseLookup objectForKey:@([cacheController hash])];
    if (![reverseSection isEqual:section]) {
        DDLogWarn(@"Mismatch between cached controllers & reverse map! Reverse map: %@ cache: %@",
                  reverseSection, section);
    }
}

- (nullable id<WMFExploreSectionController>)controllerForSection:(WMFExploreSection *)section {
    WMFVerifyCacheConsistency(section);
    return [self.sectionControllersBySection objectForKey:section];
}

- (nullable WMFExploreSection *)sectionForController:(id<WMFExploreSectionController>)controller {
    WMFVerifyCacheConsistency(controller);
    return [self.reverseLookup objectForKey:@([controller hash])];
}

- (id<WMFExploreSectionController>)getOrCreateControllerForSection:(WMFExploreSection *)section
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

- (id<WMFExploreSectionController>)newControllerForSection:(WMFExploreSection *)section {
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
    [self.reverseLookup setObject:section forKey:@([controller hash])];

    return controller;
}

#pragma mark - Section Controller Creation

- (WMFMostReadSectionController *)mostReadSectionControllerForSection:(WMFExploreSection *)section {
    return [[WMFMostReadSectionController alloc] initWithDate:section.mostReadFetchDate
                                                      siteURL:section.siteURL
                                                    dataStore:self.dataStore];
}

- (WMFRelatedSectionController *)relatedSectionControllerForSectionSchemaItem:(WMFExploreSection *)item {
    return [[WMFRelatedSectionController alloc] initWithArticleURL:item.articleURL blackList:self.dataStore.userDataStore.blackList dataStore:self.dataStore];
}

- (WMFContinueReadingSectionController *)continueReadingSectionControllerForSchemaItem:(WMFExploreSection *)item {
    return [[WMFContinueReadingSectionController alloc] initWithArticleURL:item.articleURL dataStore:self.dataStore];
}

- (WMFNearbySectionController *)nearbySectionControllerForSchemaItem:(WMFExploreSection *)item {
    return [[WMFNearbySectionController alloc] initWithLocation:item.location
                                                      placemark:item.placemark
                                                searchSiteURL:item.siteURL
                                                           date:item.dateCreated
                                                      dataStore:self.dataStore];
}

- (WMFRandomSectionController *)randomSectionControllerForSchemaItem:(WMFExploreSection *)item {
    return [[WMFRandomSectionController alloc] initWithSearchSiteURL:item.siteURL dataStore:self.dataStore];
}

- (WMFMainPageSectionController *)mainPageSectionControllerForSchemaItem:(WMFExploreSection *)item {
    return [[WMFMainPageSectionController alloc] initWithSiteURL:item.siteURL dataStore:self.dataStore];
}

- (WMFPictureOfTheDaySectionController *)picOfTheDaySectionControllerForSchemaItem:(WMFExploreSection *)item {
    return [[WMFPictureOfTheDaySectionController alloc] initWithDataStore:self.dataStore date:item.dateCreated];
}

- (WMFFeaturedArticleSectionController *)featuredArticleSectionControllerForSchemaItem:(WMFExploreSection *)item {
    return [[WMFFeaturedArticleSectionController alloc] initWithSiteURL:item.siteURL date:item.dateCreated dataStore:self.dataStore];
}

#pragma mark - Removal

- (void)removeSection:(WMFExploreSection *)section {
    id controller = [self.sectionControllersBySection objectForKey:section];
    if (controller) {
        [self.reverseLookup removeObjectForKey:@([controller hash])];
        [self.sectionControllersBySection removeObjectForKey:section];
    }
}

- (void)removeSections:(NSArray<WMFExploreSection *> *)sections {
    for (WMFExploreSection *section in sections) {
        [self removeSection:section];
    }
}

- (void)removeAllSectionsExcept:(NSArray<WMFExploreSection *> *)sections {
    if (sections == nil) {
        return;
    }

    NSMutableSet *sectionsToRemove = [NSMutableSet setWithArray:self.sectionControllersBySection.allKeys];
    [sectionsToRemove minusSet:[NSSet setWithArray:sections]];

    [self removeSections:[sectionsToRemove allObjects]];
}

- (void)removeAllSections {
    [self.sectionControllersBySection removeAllObjects];
    [self.reverseLookup removeAllObjects];
}

@end

NS_ASSUME_NONNULL_END
