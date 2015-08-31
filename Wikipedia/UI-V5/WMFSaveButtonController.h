//  Created by Monte Hurd on 8/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@class MWKSavedPageList, MWKTitle;

@interface WMFSaveButtonController : NSObject

@property (weak, nonatomic) MWKTitle* title;

- (instancetype)initWithButton:(UIButton*)button
                 savedPageList:(MWKSavedPageList*)savedPageList
                         title:(MWKTitle*)title;

@end
