
#import <Foundation/Foundation.h>
#import "WMFExploreSectionController.h"

@class WMFExploreSection, MWKSite, MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreSectionControllerCache : NSObject

@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

- (nullable id<WMFExploreSectionController>)controllerForSection:(WMFExploreSection*)section;

- (nullable WMFExploreSection*)sectionForController:(id<WMFExploreSectionController>)controller;

- (id<WMFExploreSectionController>)newControllerForSection:(WMFExploreSection*)section;

@end

NS_ASSUME_NONNULL_END