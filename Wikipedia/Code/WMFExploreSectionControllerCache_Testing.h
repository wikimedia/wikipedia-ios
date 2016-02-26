//
//  WMFExploreSectionControllerCache_Testing.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/26/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFExploreSectionControllerCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreSectionControllerCache ()

@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;
@property (nonatomic, strong) NSCache* sectionControllersBySection;
@property (nonatomic, strong) NSMapTable* sectionsBySectionController;

@end

NS_ASSUME_NONNULL_END
