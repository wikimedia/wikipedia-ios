//  Created by Monte Hurd on 4/21/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

typedef enum {
    PREVIEW_CHOICE_LOGIN_THEN_SAVE = 0,
    PREVIEW_CHOICE_SAVE = 1,
    PREVIEW_CHOICE_SHOW_LICENSE = 2
} PreviewChoices;

@class PaddedLabel;

@interface PreviewChoicesMenuView : UIView

@property (weak, nonatomic) IBOutlet PaddedLabel *signInTitleLabel;
@property (weak, nonatomic) IBOutlet PaddedLabel *signInSubTitleLabel;

@property (weak, nonatomic) IBOutlet PaddedLabel *saveAnonTitleLabel;
@property (weak, nonatomic) IBOutlet PaddedLabel *saveAnonSubTitleLabel;

@property (weak, nonatomic) IBOutlet PaddedLabel *licenseTitleLabel;

@property (weak, nonatomic) IBOutlet UIView *signInView;
@property (weak, nonatomic) IBOutlet UIView *saveAnonView;
@property (weak, nonatomic) IBOutlet UIView *licenseView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topDividerHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomDividerHeight;

@end
