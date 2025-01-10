//
//  NYTPhotoCaptionView.m
//  NYTPhotoViewer
//
//  Created by Brian Capps on 2/18/15.
//
//

#import "NYTPhotoCaptionView.h"

static const CGFloat NYTPhotoCaptionViewHorizontalMargin = 8.0;
static const CGFloat NYTPhotoCaptionViewVerticalMargin = 7.0;

@interface NYTPhotoCaptionView ()

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) NSAttributedString *attributedTitle;
@property (nonatomic, readonly) NSAttributedString *attributedSummary;
@property (nonatomic, readonly) NSAttributedString *attributedCredit;

@property (nonatomic) UITextView *textView;
@property (nonatomic) CAGradientLayer *gradientLayer;

@end

@implementation NYTPhotoCaptionView

@synthesize preferredMaxLayoutWidth = _preferredMaxLayoutWidth;

#pragma mark - UIView

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithAttributedTitle:nil attributedSummary:nil attributedCredit:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self commonInit];
    }

    return self;
}

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];

    NSLayoutConstraint *maxHeightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.superview attribute:NSLayoutAttributeHeight multiplier:0.3f constant:0.0f];
    [self.superview addConstraint:maxHeightConstraint];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    void (^updateGradientFrame)(void) = ^{
        self.gradientLayer.frame = self.layer.bounds;
    };

    updateGradientFrame();

    // On iOS 8.x, when this view is height-constrained, neither `self.bounds` nor `self.layer.bounds` reflects the new layout height immediately after `[super layoutSubviews]`. Both of those properties appear correct in the next runloop.
    // This problem doesn't affect iOS 9 and there may be a better solution; PRs welcome.
    dispatch_async(dispatch_get_main_queue(), updateGradientFrame);
}

- (CGSize)intrinsicContentSize {
    CGSize contentSize = [self.textView sizeThatFits:CGSizeMake(self.preferredMaxLayoutWidth, CGFLOAT_MAX)];
    CGFloat width = (CGFloat)self.preferredMaxLayoutWidth;
    CGFloat height = (CGFloat)ceil(contentSize.height);

    return CGSizeMake(width, height);
}

- (void)setPreferredMaxLayoutWidth:(CGFloat)preferredMaxLayoutWidth {
    preferredMaxLayoutWidth = (CGFloat)ceil(preferredMaxLayoutWidth);

    if (ABS(_preferredMaxLayoutWidth - preferredMaxLayoutWidth) > 0.1) {
        _preferredMaxLayoutWidth = preferredMaxLayoutWidth;
        [self invalidateIntrinsicContentSize];
    }
}

#pragma mark - NYTPhotoCaptionView

- (instancetype)initWithAttributedTitle:(NSAttributedString *)attributedTitle attributedSummary:(NSAttributedString *)attributedSummary attributedCredit:(NSAttributedString *)attributedCredit {
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _attributedTitle = [attributedTitle copy];
        _attributedSummary = [attributedSummary copy];
        _attributedCredit = [attributedCredit copy];

        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
    self.translatesAutoresizingMaskIntoConstraints = NO;

    [self setupTextView];
    [self updateTextViewAttributedText];
    [self setupGradient];
}

- (void)setupTextView {
    self.textView = [[UITextView alloc] initWithFrame:CGRectZero textContainer:nil];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.editable = NO;
    self.textView.dataDetectorTypes = UIDataDetectorTypeNone;
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.textContainerInset = UIEdgeInsetsMake(NYTPhotoCaptionViewVerticalMargin, NYTPhotoCaptionViewHorizontalMargin, NYTPhotoCaptionViewVerticalMargin, NYTPhotoCaptionViewHorizontalMargin);

    [self addSubview:self.textView];
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
    NSLayoutConstraint *horizontalPositionConstraint = [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    
    [self addConstraints:@[topConstraint, bottomConstraint, widthConstraint, horizontalPositionConstraint]];
}

- (void)setupGradient {
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.frame = self.layer.bounds;
    self.gradientLayer.colors = [NSArray arrayWithObjects:(id)[UIColor clearColor].CGColor, (id)[[UIColor blackColor] colorWithAlphaComponent:0.85].CGColor, nil];
    [self.layer insertSublayer:self.gradientLayer atIndex:0];
}

- (void)updateTextViewAttributedText {
    NSMutableAttributedString *attributedLabelText = [[NSMutableAttributedString alloc] init];
    
    if (self.attributedTitle) {
        [attributedLabelText appendAttributedString:self.attributedTitle];
    }
    
    if (self.attributedSummary) {
        if (self.attributedTitle) {
            [attributedLabelText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:nil]];
        }
        
        [attributedLabelText appendAttributedString:self.attributedSummary];
    }
    
    if (self.attributedCredit) {
        if (self.attributedTitle || self.attributedSummary) {
            [attributedLabelText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:nil]];
        }
        
        [attributedLabelText appendAttributedString:self.attributedCredit];
    }
    
    self.textView.attributedText = attributedLabelText;
}

@end
