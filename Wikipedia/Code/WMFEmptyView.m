
#import "WMFEmptyView.h"
#import "UIColor+WMFStyle.h"
#import "UIView+WMFDefaultNib.h"

@interface WMFEmptyView ()

@property (nonatomic, strong) IBOutlet UIStackView* stackView;
@property (nonatomic, strong) IBOutlet UIStackView* labelStackView;
@property (nonatomic, strong) IBOutlet UIImageView* imageView;
@property (nonatomic, strong) IBOutlet UILabel* titleLabel;
@property (nonatomic, strong) IBOutlet UILabel* messageLabel;
@property (strong, nonatomic) IBOutlet UILabel* actionLabel;
@property (strong, nonatomic) IBOutlet UIView* actionLine;
@property (strong, nonatomic) CAShapeLayer* actionLineLayer;

@end

@implementation WMFEmptyView


+ (instancetype)emptyView {
    return [self wmf_viewFromClassNib];
}

+ (instancetype)noFeedEmptyView {
    WMFEmptyView* view = [[self class] emptyView];
    view.imageView.image   = [UIImage imageNamed:@"no-internet"];
    view.titleLabel.text   = MWLocalizedString(@"empty-no-feed-title", nil);
    view.messageLabel.text = MWLocalizedString(@"empty-no-feed-message", nil);
    view.actionLabel.text  = MWLocalizedString(@"empty-no-feed-action-message", nil);

    return view;
}

+ (instancetype)noArticleEmptyView {
    WMFEmptyView* view = [[self class] emptyView];
    view.imageView.image   = [UIImage imageNamed:@"no-article"];
    view.messageLabel.text = MWLocalizedString(@"empty-no-article-message", nil);

    [view.titleLabel removeFromSuperview];
    [view.actionLabel removeFromSuperview];
    [view.actionLine removeFromSuperview];
    return view;
}

+ (instancetype)noSearchResultsEmptyView {
    WMFEmptyView* view = [[self class] emptyView];
    view.messageLabel.text = MWLocalizedString(@"empty-no-search-results-message", nil);

    [view.imageView removeFromSuperview];
    [view.titleLabel removeFromSuperview];
    [view.actionLabel removeFromSuperview];
    [view.actionLine removeFromSuperview];
    return view;
}

+ (instancetype)noSavedPagesEmptyView {
    WMFEmptyView* view = [[self class] emptyView];
    view.imageView.image   = [UIImage imageNamed:@"saved-blank"];
    view.titleLabel.text   = MWLocalizedString(@"empty-no-saved-pages-title", nil);
    view.messageLabel.text = MWLocalizedString(@"empty-no-saved-pages-message", nil);

    [view.actionLabel removeFromSuperview];
    [view.actionLine removeFromSuperview];
    return view;
}

+ (instancetype)noHistoryEmptyView {
    WMFEmptyView* view = [[self class] emptyView];
    view.imageView.image   = [UIImage imageNamed:@"recent-blank"];
    view.titleLabel.text   = MWLocalizedString(@"empty-no-history-title", nil);
    view.messageLabel.text = MWLocalizedString(@"empty-no-history-message", nil);

    [view.actionLabel removeFromSuperview];
    [view.actionLine removeFromSuperview];
    return view;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (![self.actionLine superview]) {
        return;
    }

    [self.actionLineLayer removeFromSuperlayer];

    UIBezierPath* path = [UIBezierPath bezierPath];
    //draw a line
    [path moveToPoint:CGPointMake(CGRectGetMidX(self.actionLine.bounds), CGRectGetMinY(self.actionLine.bounds))];
    [path addLineToPoint:CGPointMake(CGRectGetMidX(self.actionLine.bounds), CGRectGetMaxY(self.actionLine.bounds))];
    [path stroke];

    CAShapeLayer* shapelayer = [CAShapeLayer layer];
    shapelayer.frame           = self.actionLine.bounds;
    shapelayer.strokeColor     = [UIColor wmf_emptyGrayTextColor].CGColor;
    shapelayer.lineWidth       = 1.0;
    shapelayer.lineJoin        = kCALineJoinMiter;
    shapelayer.lineDashPattern = [NSArray arrayWithObjects:[NSNumber numberWithInt:5], [NSNumber numberWithInt:2], nil];
    shapelayer.path            = path.CGPath;
    [self.actionLine.layer addSublayer:shapelayer];
    self.actionLineLayer = shapelayer;
}

@end
