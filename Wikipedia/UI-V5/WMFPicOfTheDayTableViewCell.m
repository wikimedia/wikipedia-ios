//
//  WMFPicOfTheDayTableViewCell.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/23/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFPicOfTheDayTableViewCell.h"
#import "UIImageView+WMFPlaceholder.h"
#import "UIImageView+WMFImageFetching.h"

@interface WMFPicOfTheDayTableViewCell ()

@property (nonatomic, strong) IBOutlet UILabel* displayTitleLabel;

@property (nonatomic, strong) IBOutlet UIImageView* potdImageView;

@end

@implementation WMFPicOfTheDayTableViewCell

- (void)setDisplayTitle:(NSString*)displayTitle {
    self.displayTitleLabel.text = displayTitle;
}

- (void)setImageURL:(NSURL*)imageURL {
    [self.potdImageView wmf_setImageWithURL:imageURL detectFaces:YES];
}

#pragma mark - UITableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.potdImageView wmf_configureWithDefaultPlaceholder];
}

- (void)prepareForReuse {
    [super awakeFromNib];
    self.displayTitleLabel.text = @"";
    [self.potdImageView wmf_configureWithDefaultPlaceholder];
}

@end
