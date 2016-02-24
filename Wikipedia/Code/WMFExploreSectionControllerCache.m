//
//  WMFExploreSectionCache.m
//  Wikipedia
//
//  Created by Corey Floyd on 1/25/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFExploreSectionControllerCache.h"
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


@interface WMFExploreSectionControllerCache ()

@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;
@property (nonatomic, strong) NSCache* sectionControllersBySection;
@property (nonatomic, strong) NSMapTable* sectionsBySectionController;

@end

@implementation WMFExploreSectionControllerCache

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.dataStore                              = dataStore;
        self.sectionControllersBySection            = [[NSCache alloc] init];
        self.sectionControllersBySection.countLimit = [WMFExploreSection totalMaxNumberOfSections];
        self.sectionsBySectionController            = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory | NSMapTableObjectPointerPersonality
                                                                            valueOptions:NSMapTableWeakMemory];
    }
    return self;
}

- (nullable id<WMFExploreSectionController>)controllerForSection:(WMFExploreSection*)section {
    id<WMFExploreSectionController> controller = [self.sectionControllersBySection objectForKey:section];
    return controller;
}

- (nullable WMFExploreSection*)sectionForController:(id<WMFExploreSectionController>)controller {
    return [self.sectionsBySectionController objectForKey:controller];
}

- (id<WMFExploreSectionController>)newControllerForSection:(WMFExploreSection*)section {
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
    return [[WMFMostReadSectionController alloc] initWithDate:section.dateCreated
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
    return [[WMFNearbySectionController alloc] initWithLocation:item.location placemark:item.placemark site:item.site dataStore:self.dataStore];
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

