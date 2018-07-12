#import "WMFEmptyView.h"
#import <WMF/UIView+WMFDefaultNib.h>
#import "Wikipedia-Swift.h"

@interface WMFEmptyView ()

@property (nonatomic, strong) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) IBOutlet UIStackView *labelStackView;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UILabel *actionLabel;
@property (strong, nonatomic) IBOutlet UIView *actionLine;
@property (strong, nonatomic) CAShapeLayer *actionLineLayer;
@property (nonatomic, strong) WMFTheme *theme;

@end

@implementation WMFEmptyView

- (void)awakeFromNib {
    [super awakeFromNib];
    if (!self.theme) {
        self.theme = [WMFTheme standard];
    }
    [self wmf_configureSubviewsForDynamicType];
    [self applyTheme:self.theme];
}

+ (instancetype)emptyView {
    return [self wmf_viewFromClassNib];
}

+ (instancetype)blankEmptyView {
    WMFEmptyView *view = [[self class] emptyView];
    [view.imageView removeFromSuperview];
    [view.messageLabel removeFromSuperview];
    [view.titleLabel removeFromSuperview];
    [view.actionLabel removeFromSuperview];
    [view.actionLine removeFromSuperview];
    return view;
}

+ (instancetype)noFeedEmptyView {
    WMFEmptyView *view = [[self class] emptyView];
    view.imageView.image = [UIImage imageNamed:@"no-internet"];
    view.titleLabel.text = WMFLocalizedStringWithDefaultValue(@"empty-no-feed-title", nil, nil, @"No Internet Connection", @"Title of messsage shown in place of feed when no content could be loaded. Indicates there is no internet available");
    view.messageLabel.text = WMFLocalizedStringWithDefaultValue(@"empty-no-feed-message", nil, nil, @"You can see your recommended articles when you have internet", @"Body of messsage shown in place of content when no feed could be loaded. Tells users they can see the articles when the interent is restored");
    view.actionLabel.text = WMFLocalizedStringWithDefaultValue(@"empty-no-feed-action-message", nil, nil, @"You can still read saved pages", @"Footer messsage shown in place of content when no feed could be loaded. Tells users they can read saved pages offline");

    return view;
}

+ (instancetype)noArticleEmptyView {
    WMFEmptyView *view = [[self class] emptyView];
    view.imageView.image = [UIImage imageNamed:@"no-article"];
    view.messageLabel.text = WMFLocalizedStringWithDefaultValue(@"empty-no-article-message", nil, nil, @"Sorry, could not load the article", @"Shown when an article cant be loaded in place of an article");

    [view.titleLabel removeFromSuperview];
    [view.actionLabel removeFromSuperview];
    [view.actionLine removeFromSuperview];
    return view;
}

+ (instancetype)noSearchResultsEmptyView {
    WMFEmptyView *view = [[self class] emptyView];
    view.messageLabel.text = WMFLocalizedStringWithDefaultValue(@"empty-no-search-results-message", nil, nil, @"No results found", @"Shown when there are no search results");

    [view.imageView removeFromSuperview];
    [view.titleLabel removeFromSuperview];
    [view.actionLabel removeFromSuperview];
    [view.actionLine removeFromSuperview];
    return view;
}

+ (instancetype)noSavedPagesEmptyView {
    WMFEmptyView *view = [[self class] emptyView];
    view.imageView.image = [UIImage imageNamed:@"saved-blank"];
    view.titleLabel.text = WMFLocalizedStringWithDefaultValue(@"empty-no-saved-pages-title", nil, nil, @"No saved pages yet", @"Title of a blank screen shown when a user has no saved pages");
    view.messageLabel.text = WMFLocalizedStringWithDefaultValue(@"empty-no-saved-pages-message", nil, nil, @"Save pages to view them later, even offline", @"Message of a blank screen shown when a user has no saved pages");

    [view.actionLabel removeFromSuperview];
    [view.actionLine removeFromSuperview];
    return view;
}

+ (instancetype)noSavedPagesInReadingListEmptyView {
    WMFEmptyView *view = [[self class] emptyView];
    view.imageView.image = [UIImage imageNamed:@"saved-blank"];
    view.titleLabel.text = WMFLocalizedStringWithDefaultValue(@"empty-no-saved-pages-in-reading-list-title", nil, nil, @"No pages saved to this list", @"Title of a blank screen shown when a user has no saved pages in a reading list");
    view.messageLabel.text = WMFLocalizedStringWithDefaultValue(@"empty-no-saved-pages-in-reading-list-message", nil, nil, @"Save pages to this list to see them appear here", @"Message of a blank screen shown when a user has no saved pages in a reading list");

    [view.actionLabel removeFromSuperview];
    [view.actionLine removeFromSuperview];
    return view;
}

+ (instancetype)noReadingListsEmptyView {
    WMFEmptyView *view = [[self class] emptyView];
    view.imageView.image = [UIImage imageNamed:@"reading-lists-empty-state"];
    view.titleLabel.text = WMFLocalizedStringWithDefaultValue(@"empty-no-reading-lists-title", nil, nil, @"Organize saved articles with reading lists", @"Title of a blank screen shown when a user has no reading lists");
    view.messageLabel.text = WMFLocalizedStringWithDefaultValue(@"empty-no-reading-lists-message", nil, nil, @"Tap on the blue ‘+’ to create reading lists for places to travel to, favorite topics and much more", @"Message of a blank screen shown when a user has no reading lists");

    [view.actionLabel removeFromSuperview];
    [view.actionLine removeFromSuperview];
    return view;
}

+ (instancetype)noHistoryEmptyView {
    WMFEmptyView *view = [[self class] emptyView];
    view.imageView.image = [UIImage imageNamed:@"history-blank"];
    view.titleLabel.text = WMFLocalizedStringWithDefaultValue(@"empty-no-history-title", nil, nil, @"No history to show", @"Title of a blank screen shown when a user has no history");
    view.messageLabel.text = WMFLocalizedStringWithDefaultValue(@"empty-no-history-message", nil, nil, @"Keep track of what you've been reading here", @"Message of a blank screen shown when a user has no history");

    [view.actionLabel removeFromSuperview];
    [view.actionLine removeFromSuperview];
    return view;
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    if (![self.imageView superview]) {
        return;
    }
    BOOL isCompactVertical = (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact);
    self.imageView.alpha = isCompactVertical ? 0.0 : 1.0;
    self.imageView.hidden = isCompactVertical;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (![self.actionLine superview]) {
        return;
    }

    [self.actionLineLayer removeFromSuperlayer];

    UIBezierPath *path = [UIBezierPath bezierPath];
    //draw a line
    [path moveToPoint:CGPointMake(CGRectGetMidX(self.actionLine.bounds), CGRectGetMinY(self.actionLine.bounds))];
    [path addLineToPoint:CGPointMake(CGRectGetMidX(self.actionLine.bounds), CGRectGetMaxY(self.actionLine.bounds))];
    [path stroke];

    CAShapeLayer *shapelayer = [CAShapeLayer layer];
    shapelayer.frame = self.actionLine.bounds;
    shapelayer.strokeColor = self.theme.colors.tertiaryText.CGColor;
    shapelayer.lineWidth = 1.0;
    shapelayer.lineJoin = kCALineJoinMiter;
    shapelayer.lineDashPattern = [NSArray arrayWithObjects:[NSNumber numberWithInt:5], [NSNumber numberWithInt:2], nil];
    shapelayer.path = path.CGPath;
    [self.actionLine.layer addSublayer:shapelayer];
    self.actionLineLayer = shapelayer;
}

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    self.imageView.tintColor = theme.colors.tertiaryText;
    self.titleLabel.textColor = theme.colors.primaryText;
    self.messageLabel.textColor = theme.colors.secondaryText;
    self.actionLabel.textColor = theme.colors.secondaryText;
    self.backgroundColor = theme.colors.paperBackground;
    [self setNeedsLayout];
}

@end
