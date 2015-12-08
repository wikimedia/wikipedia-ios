//  Created by Monte Hurd on 1/23/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LanguageCell.h"
#import "WikipediaAppUtils.h"
#import "UIView+ConstraintsScale.h"
#import "Defines.h"
#import "UILabel+WMFStyling.h"

@implementation LanguageCell

@synthesize languageLabel;
@synthesize titleLabel;

- (void)awakeFromNib {
    [super awakeFromNib];
    self.languageLabel.textAlignment = NSTextAlignmentNatural;
    self.titleLabel.textAlignment    = NSTextAlignmentNatural;
    [self.languageLabel wmf_applyMenuScaleMultiplier];
    [self.titleLabel wmf_applyMenuScaleMultiplier];
    [self.localizedLanguageLabel wmf_applyMenuScaleMultiplier];
    [self.languageCodeLabel wmf_applyMenuScaleMultiplier];
}

@end
