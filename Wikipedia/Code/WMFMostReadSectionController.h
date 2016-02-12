//
//  WMFMostReadSectionController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/10/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFBaseExploreSectionController.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFMostReadSectionController : WMFBaseExploreSectionController
    <WMFExploreSectionController, WMFTitleProviding>

@property (nonatomic, copy, readonly) MWKSite* site;
@property (nonatomic, strong, readonly) NSDate* date;

- (instancetype)initWithDate:(NSDate*)date site:(MWKSite*)site dataStore:(MWKDataStore*)dataStore;

@end

NS_ASSUME_NONNULL_END
