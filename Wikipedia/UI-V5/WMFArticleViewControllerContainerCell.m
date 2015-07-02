
#import "WMFArticleViewControllerContainerCell.h"
#import "WMFArticleViewController.h"
#import <Masonry/Masonry.h>

@interface WMFForwardingTouchesView : UIView

@property (nonatomic, strong) NSArray* viewsToSendTouches;

@end

@implementation WMFForwardingTouchesView

- (UIView*)touchedViewWithPoint:(CGPoint)point {
    return [self.viewsToSendTouches bk_match:^BOOL (UIView* obj) {
        CGRect rect = [self convertRect:obj.frame fromView:obj.superview];

        if (CGRectContainsPoint(rect, point)) {
            return YES;
        }

        return NO;
    }];
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
    UIView* touchedView = [self touchedViewWithPoint:point];
    if (touchedView) {
        return touchedView;
    }

    return [super hitTest:point withEvent:event];
}

@end


@interface WMFArticleViewControllerContainerCell ()<UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet WMFForwardingTouchesView* touchView;
@property(nonatomic, strong) UITapGestureRecognizer* tapGesture;
@property(nonatomic, strong, readwrite) WMFArticleViewController* viewController;

@end

@implementation WMFArticleViewControllerContainerCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.viewController.article = nil;
}

- (void)setViewControllerAndAddViewToContentView:(WMFArticleViewController*)viewController {
    self.viewController = viewController;

    [self.contentView insertSubview:viewController.view atIndex:0];

    [viewController.view mas_makeConstraints:^(MASConstraintMaker* make) {
        make.leading.trailing.top.and.bottom.equalTo(self.contentView);
    }];

    self.touchView.viewsToSendTouches = @[[viewController saveButton], [viewController readButton]];
}

@end
