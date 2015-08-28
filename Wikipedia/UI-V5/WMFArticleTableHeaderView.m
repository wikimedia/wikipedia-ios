//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFArticleTableHeaderView.h"

@interface WMFArticleTableHeaderView ()

@property (weak, nonatomic) IBOutlet UILabel* titleLabel;
@property (weak, nonatomic) IBOutlet UILabel* descriptionLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* descriptionTopConstraint;
@property (nonatomic) CGFloat initialDescriptionTopConstraintConstant;

@end

@implementation WMFArticleTableHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.initialDescriptionTopConstraintConstant = self.descriptionTopConstraint.constant;
    self.titleLabel.layer.shadowRadius           = 5.0;
    self.descriptionLabel.layer.shadowRadius     = 5.0;
}

- (void)setTitle:(NSString*)title description:(NSString*)description {
    self.titleLabel.text                   = title;
    self.descriptionTopConstraint.constant = description.length == 0 ? 0 : self.initialDescriptionTopConstraintConstant;
    self.descriptionLabel.text             = description;
}

@end
