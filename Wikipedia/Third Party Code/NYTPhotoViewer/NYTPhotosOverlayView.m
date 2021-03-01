//
//  NYTPhotosOverlayView.m
//  NYTPhotoViewer
//
//  Created by Brian Capps on 2/17/15.
//
//

#import "NYTPhotosOverlayView.h"
#import "NYTPhotoCaptionViewLayoutWidthHinting.h"

@interface NYTPhotosOverlayView ()

@property (nonatomic) UINavigationItem *navigationItem;
@property (nonatomic) UINavigationBar *navigationBar;

@property (nonatomic) UIView *topCoverView;
@property (nonatomic) UIView *bottomCoverView;

@end

@implementation NYTPhotosOverlayView

#pragma mark - UIView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.topCoverBackgroundColor = [UIColor clearColor];
        self.bottomCoverBackgroundColor = [UIColor colorWithWhite:0 alpha:0.85];;
        [self setupNavigationBar];
    }
    
    return self;
}

// Pass the touches down to other views: http://stackoverflow.com/a/8104378
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    
    if (hitView == self) {
        return nil;
    }
    
    return hitView;
}

- (void)layoutSubviews {
    // The navigation bar has a different intrinsic content size upon rotation, so we must update to that new size.
    // Do it without animation to more closely match the behavior in `UINavigationController`
    [UIView performWithoutAnimation:^{
        [self.navigationBar invalidateIntrinsicContentSize];
        [self.navigationBar layoutIfNeeded];
    }];
    
    [super layoutSubviews];

    if ([self.captionView conformsToProtocol:@protocol(NYTPhotoCaptionViewLayoutWidthHinting)]) {
        [(id<NYTPhotoCaptionViewLayoutWidthHinting>) self.captionView setPreferredMaxLayoutWidth:self.bounds.size.width];
    }
}

#pragma mark - NYTPhotosOverlayView

- (void)setupNavigationBar {
    self.navigationBar = [[UINavigationBar alloc] init];
    self.navigationBar.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Make navigation bar background fully transparent.
    self.navigationBar.backgroundColor = self.topCoverBackgroundColor;
    self.navigationBar.barTintColor = nil;
    self.navigationBar.translucent = YES;
    self.navigationBar.shadowImage = [[UIImage alloc] init];
    [self.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    
    self.navigationItem = [[UINavigationItem alloc] initWithTitle:@""];
    self.navigationBar.items = @[self.navigationItem];
    
    [self addSubview:self.navigationBar];
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.navigationBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.layoutMarginsGuide attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.navigationBar attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
    NSLayoutConstraint *horizontalPositionConstraint = [NSLayoutConstraint constraintWithItem:self.navigationBar attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    [self addConstraints:@[topConstraint, widthConstraint, horizontalPositionConstraint]];
    
    self.topCoverView = [[UIView alloc] init];
    self.topCoverView.backgroundColor = self.topCoverBackgroundColor;
    self.topCoverView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.topCoverView];
    
    topConstraint = [NSLayoutConstraint constraintWithItem:self.topCoverView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    widthConstraint = [NSLayoutConstraint constraintWithItem:self.topCoverView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
    horizontalPositionConstraint = [NSLayoutConstraint constraintWithItem:self.topCoverView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
     NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.topCoverView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.navigationBar attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    [self addConstraints:@[topConstraint, bottomConstraint, widthConstraint, horizontalPositionConstraint]];
}

- (void)setCaptionView:(UIView *)captionView {
    if (self.captionView == captionView) {
        return;
    }
    
    [self.bottomCoverView removeFromSuperview];
    self.bottomCoverView = nil;
    [self.captionView removeFromSuperview];
    
    _captionView = captionView;
    
    self.captionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.captionView];
    
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.captionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.layoutMarginsGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.captionView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
    NSLayoutConstraint *horizontalPositionConstraint = [NSLayoutConstraint constraintWithItem:self.captionView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    [self addConstraints:@[bottomConstraint, widthConstraint, horizontalPositionConstraint]];
    
    
    self.bottomCoverView = [[UIView alloc] init];
    self.bottomCoverView.backgroundColor = self.bottomCoverBackgroundColor;
    self.bottomCoverView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.bottomCoverView];
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.bottomCoverView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.captionView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    widthConstraint = [NSLayoutConstraint constraintWithItem:self.bottomCoverView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
    horizontalPositionConstraint = [NSLayoutConstraint constraintWithItem:self.bottomCoverView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    bottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomCoverView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    [self addConstraints:@[topConstraint, bottomConstraint, widthConstraint, horizontalPositionConstraint]];
}

- (void)setTopCoverBackgroundColor:(UIColor *)topCoverBackgroundColor {
    if (_topCoverBackgroundColor == topCoverBackgroundColor) {
        return;
    }
    _topCoverBackgroundColor = topCoverBackgroundColor;
    self.topCoverView.backgroundColor = topCoverBackgroundColor;
    self.navigationBar.backgroundColor = topCoverBackgroundColor;
}

- (void)setBottomCoverBackgroundColor:(UIColor *)bottomCoverBackgroundColor {
    if (_bottomCoverBackgroundColor == bottomCoverBackgroundColor) {
        return;
    }
    _bottomCoverBackgroundColor = bottomCoverBackgroundColor;
    self.bottomCoverView.backgroundColor = bottomCoverBackgroundColor;
}

- (UIBarButtonItem *)leftBarButtonItem {
    return self.navigationItem.leftBarButtonItem;
}

- (void)setLeftBarButtonItem:(UIBarButtonItem *)leftBarButtonItem {
    [self.navigationItem setLeftBarButtonItem:leftBarButtonItem animated:NO];
}

- (NSArray *)leftBarButtonItems {
    return self.navigationItem.leftBarButtonItems;
}

- (void)setLeftBarButtonItems:(NSArray *)leftBarButtonItems {
    [self.navigationItem setLeftBarButtonItems:leftBarButtonItems animated:NO];
}

- (UIBarButtonItem *)rightBarButtonItem {
    return self.navigationItem.rightBarButtonItem;
}

- (void)setRightBarButtonItem:(UIBarButtonItem *)rightBarButtonItem {
    [self.navigationItem setRightBarButtonItem:rightBarButtonItem animated:NO];
}

- (NSArray *)rightBarButtonItems {
    return self.navigationItem.rightBarButtonItems;
}

- (void)setRightBarButtonItems:(NSArray *)rightBarButtonItems {
    [self.navigationItem setRightBarButtonItems:rightBarButtonItems animated:NO];
}

- (NSString *)title {
    return self.navigationItem.title;
}

- (void)setTitle:(NSString *)title {
    self.navigationItem.title = title;
}

- (NSDictionary *)titleTextAttributes {
    return self.navigationBar.titleTextAttributes;
}

- (void)setTitleTextAttributes:(NSDictionary *)titleTextAttributes {
    self.navigationBar.titleTextAttributes = titleTextAttributes;
}

@end
