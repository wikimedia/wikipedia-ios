//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface WMFArticleTableHeaderView : UIView

@property (strong, nonatomic) IBOutlet UIButton* readButton;
@property (strong, nonatomic) IBOutlet UIButton* saveButton;
@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UILabel* descriptionLabel;
@property (strong, nonatomic) IBOutlet UIImageView* image;

@end
