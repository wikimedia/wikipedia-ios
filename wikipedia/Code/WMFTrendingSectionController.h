//
//  WMFTrendingSectionController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 1/19/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WMFExploreSectionController.h"

@class MWKDataStore, MWKSite;

@interface WMFTrendingSectionController : NSObject
<WMFArticleExploreSectionController, WMFFetchingExploreSectionController>

- (instancetype)initWithDate:(NSDate*)date site:(MWKSite*)site dataStore:(MWKDataStore*)dataStore;

@end
