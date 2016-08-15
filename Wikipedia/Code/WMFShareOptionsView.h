//
//  ShareOptionsView.h
//  Wikipedia
//
//  Created by Adam Baso on 1/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PaddedLabel;

@interface WMFShareOptionsView : UIView

@property (weak, nonatomic) IBOutlet UIView* cardImageViewContainer;
@property (weak, nonatomic) IBOutlet UIImageView* cardImageView;
@property (weak, nonatomic) IBOutlet PaddedLabel* shareAsCardLabel;
@property (weak, nonatomic) IBOutlet PaddedLabel* shareAsTextLabel;
@property (weak, nonatomic) IBOutlet PaddedLabel* cancelLabel;
@end
