//  Created by Monte Hurd on 4/21/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class PaddedLabel;

@interface PreviewChoicesMenuView : UIView

@property (weak, nonatomic) IBOutlet PaddedLabel *signInTitleLabel;
@property (weak, nonatomic) IBOutlet PaddedLabel *signInSubTitleLabel;

@property (weak, nonatomic) IBOutlet PaddedLabel *saveAnonTitleLabel;
@property (weak, nonatomic) IBOutlet PaddedLabel *saveAnonSubTitleLabel;

@property (weak, nonatomic) IBOutlet UIView *signInView;
@property (weak, nonatomic) IBOutlet UIView *saveAnonView;

@end
