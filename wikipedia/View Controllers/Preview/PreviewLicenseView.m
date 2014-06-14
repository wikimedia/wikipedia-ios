//  Created by Monte Hurd on 4/25/14.

#import "PreviewLicenseView.h"
#import "PaddedLabel.h"
#import "WikipediaAppUtils.h"
#import "NSString+FormattedAttributedString.h"

#define PREVIEW_BLUE_COLOR [UIColor colorWithRed:0.13 green:0.42 blue:0.68 alpha:1.0]

//#import "NSString+Extras.h"

@interface PreviewLicenseView(){
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topDividerHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomDividerHeight;

@property (nonatomic) BOOL hideTopDivider;
@property (nonatomic) BOOL hideBottomDivider;

@end

@implementation PreviewLicenseView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.hideTopDivider = YES;
        self.hideBottomDivider = YES;
    }
    return self;
}

-(void)didMoveToSuperview
{
    UIEdgeInsets padding = UIEdgeInsetsZero;
    self.licenseTitleLabel.padding = padding;

    self.licenseTitleLabel.text = MWLocalizedString(@"wikitext-upload-save-license", nil);
    
    self.bottomDividerHeight.constant = self.hideBottomDivider ? 0.0 : 1.0f / [UIScreen mainScreen].scale;

    self.topDividerHeight.constant = self.hideTopDivider ? 0.0 : 1.0f / [UIScreen mainScreen].scale;

    [self underlineLicenseName:self.licenseTitleLabel];

    //self.licenseTitleLabel.text = [@" abc " randomlyRepeatMaxTimes:100];
}

- (id) awakeAfterUsingCoder:(NSCoder*)aDecoder {

    BOOL isPlaceholder = ([[self subviews] count] == 0); // From: https://blog.compeople.eu/apps/?p=142
    if (!isPlaceholder) return self;
    
    UINib *previewLicenseViewNib = [UINib nibWithNibName:@"PreviewLicenseView" bundle:nil];
    
    PreviewLicenseView *previewLicenseView =
        [[previewLicenseViewNib instantiateWithOwner:nil options:nil] firstObject];
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    previewLicenseView.translatesAutoresizingMaskIntoConstraints = NO;
    
    return previewLicenseView;
}

-(void)underlineLicenseName:(UILabel *)licenseLabel
{
    NSDictionary *baseAttributes =
        @{
            NSForegroundColorAttributeName: licenseLabel.textColor,
            NSFontAttributeName: licenseLabel.font
        };

    NSDictionary *substitutionAttributes =
        @{
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
            NSForegroundColorAttributeName: PREVIEW_BLUE_COLOR
        };
    
    licenseLabel.attributedText =
    [licenseLabel.text attributedStringWithAttributes: baseAttributes
                                  substitutionStrings: @[MWLocalizedString(@"wikitext-upload-save-license-name", nil)]
                               substitutionAttributes: @[substitutionAttributes]
     ];
}

@end
