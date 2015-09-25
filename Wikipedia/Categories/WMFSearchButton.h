//
//  WMFSearchButton.h
//  Wikipedia
//
//  Created by Brian Gerstle on 9/25/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WMFSearchPresenter <NSObject>



@end

@interface WMFSearchButton : UINavigationItem

+ (instancetype)wmf_searchButtonWithPresenter:(void(^)(WMFSearchViewController*))present;

@end

NS_ASSUME_NONNULL_END
