//
//  LanguagesSectionHeaderView.h
//  Wikipedia
//
//  Created by Brian Gerstle on 6/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PaddedLabel;

@interface LanguagesSectionHeaderView : UITableViewHeaderFooterView
@property (weak, nonatomic) PaddedLabel* titleLabel;

/// @return The height of the header view using the default styles set during initialization.
+ (CGFloat)defaultHeaderHeight;

@end
