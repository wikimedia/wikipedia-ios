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

@end

@implementation NYTPhotosOverlayView

#pragma mark - UIView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
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
    self.navigationBar.backgroundColor = [UIColor clearColor];
    self.navigationBar.barTintColor = nil;
    self.navigationBar.translucent = YES;
    self.navigationBar.shadowImage = [[UIImage alloc] init];
    [self.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    
    self.navigationItem = [[UINavigationItem alloc] initWithTitle:@""];
    self.navigationBar.items = @[self.navigationItem];
    
    [self addSubview:self.navigationBar];
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.navigationBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.navigationBar attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
    NSLayoutConstraint *horizontalPositionConstraint = [NSLayoutConstraint constraintWithItem:self.navigationBar attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    [self addConstraints:@[topConstraint, widthConstraint, horizontalPositionConstraint]];
}

- (void)setCaptionView:(UIView *)captionView {
    if (self.captionView == captionView) {
        return;
    }
    
    [self.captionView removeFromSuperview];
    
    _captionView = captionView;
    
    self.captionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.captionView];
    
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.captionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.captionView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
    NSLayoutConstraint *horizontalPositionConstraint = [NSLayoutConstraint constraintWithItem:self.captionView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    [self addConstraints:@[bottomConstraint, widthConstraint, horizontalPositionConstraint]];
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
