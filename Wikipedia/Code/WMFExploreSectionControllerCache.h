#import <Foundation/Foundation.h>
#import "WMFExploreSectionController.h"

@class WMFExploreSection, MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreSectionControllerCache : NSObject

@property(nonatomic, strong, readonly) MWKDataStore *dataStore;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;

- (nullable id<WMFExploreSectionController>)controllerForSection:
    (WMFExploreSection *)section;

- (nullable WMFExploreSection *)sectionForController:
    (id<WMFExploreSectionController>)controller;

/**
 *  Get a controller for a particular section, or create one if it doesn't
 * exist.
 *
 *  @param section The section to retrieve or create a controller for.
 *  @param factory A block which is invoked when a new section is created.
 *
 *  @return A section controller for `section`.
 */
- (id<WMFExploreSectionController>)
getOrCreateControllerForSection:(WMFExploreSection *)section
                  creationBlock:
                      (nullable void (^)(id<WMFExploreSectionController>
                                             newController))creationBlock;

- (void)removeSection:(WMFExploreSection *)section;
- (void)removeSections:(NSArray<WMFExploreSection *> *)sections;
- (void)removeAllSectionsExcept:(NSArray<WMFExploreSection *> *)sections;
- (void)removeAllSections;

@end

NS_ASSUME_NONNULL_END