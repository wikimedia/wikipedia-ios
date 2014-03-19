//  Created by Monte Hurd on 3/19/14.

#import "TitleSubtitleView.h"
#import "TopActionSheetLabel.h"
#import "UIView+RemoveConstraints.h"

@interface TitleSubtitleView()

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *subTitle;
@property (strong, nonatomic) UIColor *titleTextColor;
@property (strong, nonatomic) UIColor *subTitleTextColor;

@property (strong, nonatomic) TopActionSheetLabel *titleLabel;
@property (strong, nonatomic) TopActionSheetLabel *subTitleLabel;
@property (strong, nonatomic) UIView *bottomSpacerView;

@end

@implementation TitleSubtitleView

- (id)initWithTitle: (NSString *)title
           subTitle: (NSString *)subTitle
     titleTextColor: (UIColor *)titleTextColor
  subTitleTextColor: (UIColor *)subTitleTextColor
    backgroundColor: (UIColor *)backgroundColor
{
    self = [super init];
    if (self) {
        
        self.title = title;
        self.subTitle = subTitle;
        self.titleTextColor = titleTextColor;
        self.subTitleTextColor = subTitleTextColor;
        self.backgroundColor = backgroundColor;

        [self setUpSubviews];
    }
    return self;
}

-(void)setUpSubviews
{
    NSMutableAttributedString *(^getAttributedText)(NSString *, UIColor *, UIFont *) = ^NSMutableAttributedString *(NSString *title, UIColor *textColor, UIFont *font) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 3.0f;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentLeft;
        
        NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:title attributes:nil];
        NSRange wholeRange = NSMakeRange(0, title.length);
        [attStr beginEditing];
        [attStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:wholeRange];
        [attStr addAttribute:NSForegroundColorAttributeName value:textColor range:wholeRange];
        [attStr addAttribute:NSFontAttributeName value:font range:wholeRange];
        [attStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:wholeRange];
        //[attStr addAttribute:NSKernAttributeName value:@1.0f range:wholeRange];
        [attStr endEditing];
        return attStr;
    };
    
    self.userInteractionEnabled = YES;
    
    self.titleLabel = [[TopActionSheetLabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.titleLabel setAttributedText:getAttributedText(self.title, self.titleTextColor, [UIFont boldSystemFontOfSize:13.0f])];
    [self.titleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self addSubview:self.titleLabel];
    
    self.subTitleLabel = [[TopActionSheetLabel alloc] init];
    self.subTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subTitleLabel.numberOfLines = 0;
    self.subTitleLabel.backgroundColor = [UIColor clearColor];
    [self.subTitleLabel setAttributedText:getAttributedText(self.subTitle, self.subTitleTextColor, [UIFont systemFontOfSize:12.0f])];
    self.subTitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.subTitleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self addSubview:self.subTitleLabel];
    
    self.bottomSpacerView = [[UIView alloc] init];
    self.bottomSpacerView.userInteractionEnabled = YES;
    self.bottomSpacerView.backgroundColor = [UIColor clearColor];
    self.bottomSpacerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.bottomSpacerView];
}

-(void)updateConstraints
{
    [self constrainSubviews];
    [super updateConstraints];
}

-(void)constrainSubviews
{
    // Remove existing constraints.
    [self.titleLabel removeConstraintsOfViewFromView:self];
    [self.subTitleLabel removeConstraintsOfViewFromView:self];
    [self.bottomSpacerView removeConstraintsOfViewFromView:self];

    NSDictionary *metrics = @{
                            @"padding": @(19),
                            @"topPadding": @(28),
                            @"verticalPaddingUnderTitle": @(12)
                            };

    NSDictionary *views = @{
                            @"titleLabel": self.titleLabel,
                            @"subTitleLabel": self.subTitleLabel,
                            @"bottomSpacerView":self.bottomSpacerView
                            };
    
    NSArray *constraints =
    @[
      [NSLayoutConstraint constraintsWithVisualFormat:
       @"V:|-(topPadding)-[titleLabel]-(verticalPaddingUnderTitle)-[subTitleLabel]-[bottomSpacerView]-|"
                                              options: 0
                                              metrics: metrics
                                                views: views]
      ,
      [NSLayoutConstraint constraintsWithVisualFormat:
       @"H:|-(padding)-[titleLabel]-(padding)-|"
                                              options: 0
                                              metrics: metrics
                                                views: views]
      ,
      [NSLayoutConstraint constraintsWithVisualFormat:
       @"H:|-(padding)-[subTitleLabel]-(padding)-|"
                                              options: 0
                                              metrics: metrics
                                                views: views]
      ,
      [NSLayoutConstraint constraintsWithVisualFormat:
       @"H:|-(padding)-[bottomSpacerView]-(padding)-|"
                                              options: 0
                                              metrics: metrics
                                                views: views]
      ];
    
    [self addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
