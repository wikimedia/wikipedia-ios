//  Created by Monte Hurd on 4/21/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PreviewChoicesMenuView.h"
#import "PaddedLabel.h"
#import "WikipediaAppUtils.h"
#import "NSString+FormattedAttributedString.h"

#define PREVIEW_BLUE_COLOR [UIColor colorWithRed:0.13 green:0.42 blue:0.68 alpha:1.0]

//#import "UIView+Debugging.h"

@interface PreviewChoicesMenuView(){

}

@end

@implementation PreviewChoicesMenuView

// Load PreviewChoicesMenuView.xib
- (id) awakeAfterUsingCoder:(NSCoder*)aDecoder {

    BOOL isPlaceholder = ([[self subviews] count] == 0); // From: https://blog.compeople.eu/apps/?p=142
    if (!isPlaceholder) return self;
    
    UINib *previewChoicesMenuViewNib = [UINib nibWithNibName:@"PreviewChoicesMenuView" bundle:nil];
    
    PreviewChoicesMenuView *previewChoicesMenuView =
        [[previewChoicesMenuViewNib instantiateWithOwner:nil options:nil] firstObject];
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    previewChoicesMenuView.translatesAutoresizingMaskIntoConstraints = NO;
    
    return previewChoicesMenuView;
}

-(void)didMoveToSuperview
{
    UIEdgeInsets padding = UIEdgeInsetsZero;
    self.signInTitleLabel.padding = padding;
    self.signInSubTitleLabel.padding = padding;
    self.saveAnonTitleLabel.padding = padding;
    self.saveAnonSubTitleLabel.padding = padding;
    self.licenseTitleLabel.padding = padding;

    self.saveAnonTitleLabel.text = MWLocalizedString(@"wikitext-upload-save-anonymously", nil);
    self.saveAnonSubTitleLabel.text = MWLocalizedString(@"wikitext-upload-save-anonymously-warning", nil);
    self.signInTitleLabel.text = MWLocalizedString(@"wikitext-upload-save-sign-in", nil);
    self.signInSubTitleLabel.text = MWLocalizedString(@"wikitext-upload-save-sign-in-benefits", nil);
    self.licenseTitleLabel.text = MWLocalizedString(@"wikitext-upload-save-license", nil);
    
    self.signInView.tag = PREVIEW_CHOICE_LOGIN_THEN_SAVE;
    self.saveAnonView.tag = PREVIEW_CHOICE_SAVE;
    self.licenseView.tag = PREVIEW_CHOICE_SHOW_LICENSE;
    
    self.signInView.backgroundColor = PREVIEW_BLUE_COLOR;
    
    self.topDividerHeight.constant = 1.0f / [UIScreen mainScreen].scale;
    self.bottomDividerHeight.constant = 1.0f / [UIScreen mainScreen].scale;
    //[self randomlyColorSubviews];
    
    [self underlineLabelText: self.signInTitleLabel];
    [self underlineLabelText: self.saveAnonTitleLabel];
    [self underlineLicenseName:self.licenseTitleLabel];
}

-(void)underlineLabelText:(UILabel *)label
{
    NSMutableAttributedString *aString =
        [[NSMutableAttributedString alloc] initWithString:label.text attributes:nil];
    
    NSRange wholeRange = NSMakeRange(0, label.text.length);
    
    [aString beginEditing];
    [aString addAttribute:NSForegroundColorAttributeName value:label.textColor range:wholeRange];
    [aString addAttribute:NSFontAttributeName value:label.font range:wholeRange];
    [aString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:wholeRange];
    [aString endEditing];
    
    label.attributedText = aString;
}

-(void)underlineLicenseName:(UILabel *)licenseLabel
{
    NSDictionary *baseAttributes =
        @{
            NSForegroundColorAttributeName: licenseLabel.textColor,
            NSFontAttributeName: licenseLabel.font
        };
    
    licenseLabel.attributedText =
    [licenseLabel.text attributedStringWithAttributes: baseAttributes
                                  substitutionStrings: @[MWLocalizedString(@"wikitext-upload-save-license-name", nil)]
                               substitutionAttributes: @[
                                                         @{
                                                             NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                                             NSForegroundColorAttributeName: PREVIEW_BLUE_COLOR
                                                             }]
     ];
}

@end
