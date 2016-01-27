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

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreSectionControllerCache ()

@property (nonatomic, strong, readwrite) MWKSite* site;
@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;
@property (nonatomic, strong) NSMutableDictionary* sectionControllersBySection;

@end

@implementation WMFExploreSectionControllerCache

- (instancetype)initWithSite:(MWKSite*)site
                   dataStore:(MWKDataStore*)dataStore {
    self = [super init];
    if (self) {
        self.site                        = site;
        self.dataStore                   = dataStore;
        self.sectionControllersBySection = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id<WMFExploreSectionController>)controllerForSection:(WMFExploreSection*)section {
    id<WMFExploreSectionController> controller = self.sectionControllersBySection[section];
    if (!controller) {
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
                controller = [self picOfTheDaySectionController];
                break;
                /*
                   !!!: do not add a default case, it is intentionally omitted so an error/warning is triggered when
                   a new case is added to the enum, enforcing that all sections are handled here.
                 */
        }
        self.sectionControllersBySection[section] = controller;
    }
    return controller;
}

- (nullable WMFExploreSection*)sectionForController:(id<WMFExploreSectionController>)controller {
    __block WMFExploreSection* section = nil;
    [self.sectionControllersBySection enumerateKeysAndObjectsUsingBlock:^(WMFExploreSection* _Nonnull key, id < WMFExploreSectionController > _Nonnull obj, BOOL* _Nonnull stop) {
        if ([[controller sectionIdentifier] isEqualToString:[obj sectionIdentifier]]) {
            section = key;
            *stop = YES;
        }
    }];
    
    return section;
}

#pragma mark - Section Controller Creation

- (WMFRelatedSectionController*)relatedSectionControllerForSectionSchemaItem:(WMFExploreSection*)item {
    return [[WMFRelatedSectionController alloc] initWithArticleTitle:item.title blackList:[WMFRelatedSectionBlackList sharedBlackList] dataStore:self.dataStore];
}

- (WMFContinueReadingSectionController*)continueReadingSectionControllerForSchemaItem:(WMFExploreSection*)item {
    return [[WMFContinueReadingSectionController alloc] initWithArticleTitle:item.title dataStore:self.dataStore];
}

- (WMFNearbySectionController*)nearbySectionControllerForSchemaItem:(WMFExploreSection*)item {
    return [[WMFNearbySectionController alloc] initWithLocation:item.location site:self.site dataStore:self.dataStore];
}

- (WMFRandomSectionController*)randomSectionControllerForSchemaItem:(WMFExploreSection*)item {
    return [[WMFRandomSectionController alloc] initWithSite:self.site savedPageList:self.dataStore.userDataStore.savedPageList];
}

- (WMFMainPageSectionController*)mainPageSectionControllerForSchemaItem:(WMFExploreSection*)item {
    return [[WMFMainPageSectionController alloc] initWithSite:self.site savedPageList:self.dataStore.userDataStore.savedPageList];
}

- (WMFPictureOfTheDaySectionController*)picOfTheDaySectionController {
    return [[WMFPictureOfTheDaySectionController alloc] init];
}

- (WMFFeaturedArticleSectionController*)featuredArticleSectionControllerForSchemaItem:(WMFExploreSection*)item {
    return [[WMFFeaturedArticleSectionController alloc] initWithSite:item.site date:item.dateCreated savedPageList:self.dataStore.userDataStore.savedPageList];
}

@end

NS_ASSUME_NONNULL_END

