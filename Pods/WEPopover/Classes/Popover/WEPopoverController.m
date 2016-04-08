//
//  WEPopoverController.m
//  WEPopover
//
//  Created by Werner Altewischer on 02/09/10.
//  Copyright 2010 Werner IT Consultancy. All rights reserved.
//

#import "WEPopoverController.h"
#import "WEPopoverParentView.h"
#import "UIBarButtonItem+WEPopover.h"
#import "WEPopoverContainerView.h"
#import "WEWeakReference.h"

static const NSTimeInterval kDefaultPrimaryAnimationDuration = 0.3;
static const NSTimeInterval kDefaultSecundaryAnimationDuration = 0.15;

@interface WEPopoverController()<WETouchableViewDelegate, WEPopoverContainerViewDelegate>

@property (nonatomic, strong) WEPopoverContainerView *containerView;
@property (nonatomic, strong) WETouchableView *backgroundView;
@property (nonatomic, assign, getter=isPresenting) BOOL presenting;
@property (nonatomic, assign, getter=isDismissing) BOOL dismissing;
@property (nonatomic, assign, getter=isPopoverVisible) BOOL popoverVisible;
@property (nonatomic, assign) CGSize effectivePopoverContentSize;

@end

@interface WEPopoverController(Private)

- (UIView *)keyViewForView:(UIView *)theView;
- (void)updateBackgroundPassthroughViews;
- (CGRect)displayAreaForView:(UIView *)theView;
- (void)dismissPopoverAnimated:(BOOL)animated userInitiated:(BOOL)userInitiated completion:(WEPopoverCompletionBlock)completion;
- (void)determineContentSize;
- (void)removeView;
- (void)repositionContainerViewForFrameChange;
- (CGRect)collapsedFrameFromFrame:(CGRect)frame forArrowDirection:(UIPopoverArrowDirection)arrowDirection;
- (UIView *)fillBackgroundViewWithDefault:(UIView *)defaultView;

@end

NSString * const WEPopoverControllerWillShowNotification = @"WEPopoverWillShowNotification";
NSString * const WEPopoverControllerDidDismissNotification = @"WEPopoverDidDismissNotification";

@implementation WEPopoverController {
}

static WEPopoverContainerViewProperties *defaultProperties = nil;
static NSUInteger popoverVisibleCount = 0;

static BOOL OSVersionIsAtLeast(float version) {
    return version <= ([[[UIDevice currentDevice] systemVersion] floatValue] + 0.0001);
}

static void animate(NSTimeInterval duration, void (^animationBlock)(void), void (^completionBlock)(BOOL finished)) {
    [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState animations:animationBlock completion:completionBlock];
}

#pragma - Class Methods

+ (NSMutableArray *)activePopoverReferences {
    static NSMutableArray *activePopovers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        activePopovers = [NSMutableArray new];
    });
    return activePopovers;
}

+ (NSUInteger)indexForActivePopover:(WEPopoverController *)controller {
    @synchronized([WEPopoverController class]) {
        NSMutableArray *array = [self activePopoverReferences];
        for (NSUInteger i = 0; i < array.count; ++i) {
            WEWeakReference *value = [array objectAtIndex:i];
            if (value.object == controller) {
                return i;
            }
        }
        return NSNotFound;
    }
}

+ (void)pushActivePopover:(WEPopoverController *)controller {
    @synchronized([WEPopoverController class]) {
        id value = [WEWeakReference weakReferenceWithObject:controller];
        [[self activePopoverReferences] addObject:value];
    }
}

+ (void)popActivePopover:(WEPopoverController *)controller {
    @synchronized([WEPopoverController class]) {
        NSUInteger index = [self indexForActivePopover:controller];
        if (index != NSNotFound) {
            [[self activePopoverReferences] removeObjectAtIndex:index];
        }
    }
}

+ (NSArray *)visiblePopovers {
    @synchronized([WEPopoverController class]) {
        NSArray *popoverReferences = [self activePopoverReferences];
        NSMutableArray *ret = [NSMutableArray arrayWithCapacity:popoverReferences.count];
        for (WEWeakReference *ref in popoverReferences) {
            if (ref.object != nil) {
                [ret addObject:ref.object];
            }
        }
        return ret;
    }
}

+ (BOOL)isAnyPopoverVisible {
    @synchronized([WEPopoverController class]) {
        return popoverVisibleCount > 0;
    }
}

+ (void)setDefaultContainerViewProperties:(WEPopoverContainerViewProperties *)properties {
    @synchronized([WEPopoverController class]) {
        if (properties != defaultProperties) {
            defaultProperties = properties;
        }
    }
}

//Enable to use the simple popover style
+ (WEPopoverContainerViewProperties *)defaultContainerViewProperties {
    @synchronized([WEPopoverController class]) {
        if (defaultProperties) {
            return defaultProperties;
        }
    }
    
    WEPopoverContainerViewProperties *props = [[WEPopoverContainerViewProperties alloc] init];
    
    NSString *bgImageName = nil;
    CGFloat bgMargin = 0.0;
    CGFloat bgCapSize = 0.0;
    CGFloat contentMargin = 0.0;
    
    if (OSVersionIsAtLeast(7.0)) {
        
        bgImageName = @"popoverBg-white.png";
        
        contentMargin = 4.0;
        
        bgMargin = 12;
        bgCapSize = 31;
        
        props.arrowMargin = 4.0;
        
        props.upArrowImageName = @"popoverArrowUp-white.png";
        props.downArrowImageName = @"popoverArrowDown-white.png";
        props.leftArrowImageName = @"popoverArrowLeft-white.png";
        props.rightArrowImageName = @"popoverArrowRight-white.png";
        
    } else {
        bgImageName = @"popoverBg.png";
        
        // These constants are determined by the popoverBg.png image file and are image dependent
        bgMargin = 13; // margin width of 13 pixels on all sides popoverBg.png (62 pixels wide - 36 pixel background) / 2 == 26 / 2 == 13
        bgCapSize = 31; // ImageSize/2  == 62 / 2 == 31 pixels
        
        contentMargin = 4.0;
        
        props.arrowMargin = 4.0;
        
        props.upArrowImageName = @"popoverArrowUp.png";
        props.downArrowImageName = @"popoverArrowDown.png";
        props.leftArrowImageName = @"popoverArrowLeft.png";
        props.rightArrowImageName = @"popoverArrowRight.png";
    }
    
    props.backgroundMargins = UIEdgeInsetsMake(bgMargin, bgMargin, bgMargin, bgMargin);
    
    props.leftBgCapSize = bgCapSize;
    props.topBgCapSize = bgCapSize;
    props.bgImageName = bgImageName;
    
    props.contentMargins = UIEdgeInsetsMake(contentMargin, contentMargin, contentMargin, contentMargin - 1);
    
    return props;
}

#pragma mark - Initialization and deallocation

- (id)init {
	if ((self = [super init])) {
        self.backgroundColor = [UIColor clearColor];
        self.popoverLayoutMargins = UIEdgeInsetsMake(10, 10, 10, 10);
        self.animationType = WEPopoverAnimationTypeCrossFade;
        self.primaryAnimationDuration = kDefaultPrimaryAnimationDuration;
        self.secundaryAnimationDuration = kDefaultSecundaryAnimationDuration;
        self.gestureBlockingEnabled = YES;
	}
	return self;
}

- (id)initWithContentViewController:(UIViewController *)viewController {
	if ((self = [self init])) {
		self.contentViewController = viewController;
	}
	return self;
}

- (void)dealloc {
	[self dismissPopoverAnimated:NO];
}

#pragma mark - Getters/setters

- (void)setContentViewController:(UIViewController *)vc {
    [self setContentViewController:vc animated:NO];
}

- (void)setContentViewController:(UIViewController *)contentViewController animated:(BOOL)animated {
    if (contentViewController != _contentViewController) {
        [self updateContentViewController:contentViewController withOldContentViewController:_contentViewController animated:animated];
        _contentViewController = contentViewController;
    }
}

- (void)updateContentViewController:(UIViewController *)contentViewController withOldContentViewController:(UIViewController *)oldContentViewController animated:(BOOL)animated {
    UIView *newContentView = [contentViewController view];
    UIViewController *__weak parentViewController = _parentViewController;
    if (self.containerView != nil && newContentView != self.containerView.contentView) {
        BOOL shouldManuallyForwardAppearanceMethods = YES;

        if ([parentViewController respondsToSelector:@selector(shouldAutomaticallyForwardAppearanceMethods)]) {
            shouldManuallyForwardAppearanceMethods = ![parentViewController shouldAutomaticallyForwardAppearanceMethods];
        } else if ([parentViewController respondsToSelector:@selector(automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers)]) {
            shouldManuallyForwardAppearanceMethods = ![parentViewController automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers];
        }

        if (parentViewController) {
            [oldContentViewController willMoveToParentViewController:nil];
            if (contentViewController) {
                [parentViewController addChildViewController:contentViewController];
            }
            if (shouldManuallyForwardAppearanceMethods) {
                [oldContentViewController beginAppearanceTransition:NO animated:animated];
                [contentViewController beginAppearanceTransition:YES animated:animated];
            }
        }
        [self.containerView setContentView:newContentView withAnimationDuration:(animated ? self.primaryAnimationDuration : 0.0)
                                completion:^ {
                                    if (parentViewController) {
                                        [contentViewController didMoveToParentViewController:parentViewController];
                                        [oldContentViewController removeFromParentViewController];
                                        if (shouldManuallyForwardAppearanceMethods) {
                                            [oldContentViewController endAppearanceTransition];
                                            [contentViewController endAppearanceTransition];
                                        }
                                    }
                                }];
    }
}

//Overridden setter to copy the passthroughViews to the background view if it exists already
- (void)setPassthroughViews:(NSArray *)array {
	_passthroughViews = nil;
	if (array) {
		_passthroughViews = [[NSArray alloc] initWithArray:array];
	}
	[self updateBackgroundPassthroughViews];
}

- (void)setPopoverVisible:(BOOL)popoverVisible {
    if (_popoverVisible != popoverVisible) {
        _popoverVisible = popoverVisible;
        @synchronized([WEPopoverController class]) {
            if (popoverVisible) {
                popoverVisibleCount++;
                [self.class pushActivePopover:self];
            } else {
                popoverVisibleCount--;
                [self.class popActivePopover:self];
            }
        }
    }
}

#pragma mark - Dismiss

- (void)dismissPopoverAnimated:(BOOL)animated {
    [self dismissPopoverAnimated:animated completion:nil];
}

- (void)dismissPopoverAnimated:(BOOL)animated completion:(WEPopoverCompletionBlock)completion {
    [self dismissPopoverAnimated:animated userInitiated:NO completion:completion];
}

#pragma mark - Present

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item
			   permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
							   animated:(BOOL)animated {
	
    [self presentPopoverFromBarButtonItem:item permittedArrowDirections:arrowDirections animated:animated completion:nil];
}

- (void)presentPopoverFromRect:(CGRect)rect
                        inView:(UIView *)theView
      permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                      animated:(BOOL)animated {
    [self presentPopoverFromRect:rect inView:theView permittedArrowDirections:arrowDirections animated:animated completion:nil];
}

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item
               permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                               animated:(BOOL)animated
                             completion:(WEPopoverCompletionBlock)completion {
    
    UIView *v = [self keyViewForView:nil];
    CGRect rect = [item weFrameInView:v];
    return [self presentPopoverFromRect:rect inView:v permittedArrowDirections:arrowDirections animated:animated completion:completion];
}

- (void)presentPopoverFromRect:(CGRect)rect
                        inView:(UIView *)theView
      permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                      animated:(BOOL)animated
                    completion:(WEPopoverCompletionBlock)completion {
    
    if (!self.isPresenting && !self.isDismissing && ![self isPopoverVisible]) {
        self.presenting = YES;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WEPopoverControllerWillShowNotification object:self];
        
        self.popoverVisible = YES;
        
        //First force a load view for the contentViewController so the popoverContentSize is properly initialized
        [_contentViewController view];
        
        [self determineContentSize];
        
        CGRect displayArea = [self displayAreaForView:theView];
        
        UIView *keyView = [self keyViewForView:theView];
        
        _backgroundView = [[WETouchableView alloc] initWithFrame:keyView.bounds];
        _backgroundView.fillView = [self fillBackgroundViewWithDefault:_backgroundView.fillView];
        _backgroundView.contentMode = UIViewContentModeScaleToFill;
        _backgroundView.autoresizingMask = ( UIViewAutoresizingFlexibleWidth |
                                            UIViewAutoresizingFlexibleHeight);
        _backgroundView.fillColor = self.backgroundColor;
        _backgroundView.delegate = self;
        _backgroundView.gestureBlockingEnabled = self.gestureBlockingEnabled;

        if (self.parentViewController != nil) {
            [self.parentViewController addChildViewController:_contentViewController];
        }
        
        [keyView addSubview:_backgroundView];
        
        WEPopoverContainerViewProperties *props = self.containerViewProperties ? self.containerViewProperties : [[self class] defaultContainerViewProperties];
        WEPopoverContainerView *containerView = [[WEPopoverContainerView alloc] initWithSize:self.effectivePopoverContentSize anchorRect:rect displayArea:displayArea permittedArrowDirections:arrowDirections properties:props];
        containerView.delegate = self;
        _popoverArrowDirection = containerView.arrowDirection;
        
        [_backgroundView addSubview:containerView];
        
        [containerView setFrame:[theView convertRect:containerView.calculatedFrame toView:containerView.superview] sendNotification:NO];
        containerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        self.containerView = containerView;

        [self updateContentViewController:_contentViewController withOldContentViewController:nil animated:NO];

        [self updateBackgroundPassthroughViews];
        
        [self.containerView becomeFirstResponder];
        
        _presentedFromRect = rect;
        _presentedFromView = theView;
        
        void (^animationCompletionBlock)(BOOL finished) = ^(BOOL finished) {
            self.containerView.userInteractionEnabled = YES;
            self.presenting = NO;
            if (completion) {
                completion();
            }
        };
        
        if (animated) {
            self.backgroundView.fillView.alpha = 0.0;
            
            if (self.animationType == WEPopoverAnimationTypeSlide) {
                
                CGRect finalFrame = self.containerView.frame;
                
                CGRect initialFrame = [self collapsedFrameFromFrame:finalFrame forArrowDirection:_popoverArrowDirection];
                
                [self.containerView setFrame:initialFrame sendNotification:NO];
                self.containerView.alpha = 1.0;
                self.containerView.arrowCollapsed = YES;
                
                NSTimeInterval firstAnimationDuration = self.primaryAnimationDuration;
                NSTimeInterval secondAnimationDuration = self.secundaryAnimationDuration;
                
                animate(firstAnimationDuration, ^{
                    
                    [self.containerView setFrame:finalFrame sendNotification:NO];
                    self.backgroundView.fillView.alpha = 1.0;
                    
                    if (self.transitionBlock) {
                        self.transitionBlock(WEPopoverTransitionTypePresent, animated);
                    }
                    
                }, ^(BOOL finished) {
                    
                    animate(secondAnimationDuration, ^{
                        self.containerView.arrowCollapsed = NO;
                    }, animationCompletionBlock);
                    
                });
                
            } else {
                self.containerView.alpha = 0.0;
                self.containerView.arrowCollapsed = NO;
                
                animate(self.primaryAnimationDuration, ^{
                    
                    self.containerView.alpha = 1.0;
                    self.backgroundView.fillView.alpha = 1.0;
                    
                    if (self.transitionBlock) {
                        self.transitionBlock(WEPopoverTransitionTypePresent, animated);
                    }
                    
                }, animationCompletionBlock);
            }
            
        } else {
            self.containerView.alpha = 1.0;
            self.containerView.arrowCollapsed = NO;
            self.backgroundView.fillView.alpha = 1.0;
            if (self.transitionBlock) {
                self.transitionBlock(WEPopoverTransitionTypePresent, animated);
            }
            animationCompletionBlock(YES);
        }
    }
}

- (void)setGestureBlockingEnabled:(BOOL)gestureBlockingEnabled {
    _gestureBlockingEnabled = gestureBlockingEnabled;
    _backgroundView.gestureBlockingEnabled = gestureBlockingEnabled;
}

#pragma mark - Reposition

- (void)repositionForContentViewController:(UIViewController *)vc animated:(BOOL)animated {
    [self setContentViewController:vc animated:animated];
    [self repositionPopoverFromRect:_presentedFromRect inView:_presentedFromView permittedArrowDirections:_popoverArrowDirection animated:animated];
}

- (void)repositionPopoverFromRect:(CGRect)rect
						   inView:(UIView *)theView
		 permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
{
    
    [self repositionPopoverFromRect:rect
                             inView:theView
           permittedArrowDirections:arrowDirections
                           animated:NO];
}

- (void)repositionPopoverFromRect:(CGRect)rect
						   inView:(UIView *)theView
		 permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                         animated:(BOOL)animated {
    
    [self repositionPopoverFromRect:rect inView:theView permittedArrowDirections:arrowDirections animated:animated completion:nil];
}

- (void)repositionPopoverFromRect:(CGRect)rect
                           inView:(UIView *)theView
         permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                         animated:(BOOL)animated
                       completion:(WEPopoverCompletionBlock)completion {
    
    if ([self isPopoverVisible] && !self.isDismissing) {
        _presentedFromRect = CGRectZero;
        _presentedFromView = nil;
        
        [self determineContentSize];
        
        CGRect displayArea = [self displayAreaForView:theView];
        WEPopoverContainerView *containerView = self.containerView;
        
        void (^animationBlock)(void) = ^(void) {
            [containerView updatePositionWithSize:self.effectivePopoverContentSize
                                       anchorRect:rect
                                      displayArea:displayArea
                         permittedArrowDirections:arrowDirections];
            _popoverArrowDirection = containerView.arrowDirection;
            [containerView setFrame:[theView convertRect:containerView.calculatedFrame toView:containerView.superview] sendNotification:NO];
            _presentedFromView = theView;
            _presentedFromRect = rect;
            
            if (self.transitionBlock) {
                self.transitionBlock(WEPopoverTransitionTypeReposition, animated);
            }
        };
        
        void (^animationCompletionBlock)(BOOL finished) = ^(BOOL finished) {
            if (completion) {
                completion();
            }
        };
        
        if (animated) {
            animate(self.primaryAnimationDuration, animationBlock, animationCompletionBlock);
        } else {
            animationBlock();
            animationCompletionBlock(YES);
        }
    }
}

#pragma mark - 
#pragma mark WEPopoverContainerViewDelegate

- (CGRect)popoverContainerView:(WEPopoverContainerView *)containerView willChangeFrame:(CGRect)newFrame {
    CGRect rect = newFrame;
    if (_presentedFromView != nil && containerView == self.containerView) {
        rect = containerView.frame;
        //Call async because all views will need their frames to be adjusted before we can recalculate
        [self performSelector:@selector(repositionContainerViewForFrameChange) withObject:nil afterDelay:0];
    }
    return rect;
}

#pragma mark -
#pragma mark WETouchableViewDelegate implementation

- (void)viewWasTouched:(WETouchableView *)view {
	if (self.isPopoverVisible && !self.isPresenting && !self.isDismissing) {
		if (!_delegate || ![_delegate respondsToSelector:@selector(popoverControllerShouldDismissPopover:)] || [_delegate popoverControllerShouldDismissPopover:self]) {
			[self dismissPopoverAnimated:YES userInitiated:YES completion:nil];
		}
	}
}

- (CGRect)fillRectForView:(WETouchableView *)view {
    CGRect rect = view.bounds;
    if ([self.delegate respondsToSelector:@selector(backgroundAreaForPopoverController:relativeToView:)]) {
        rect = [self.delegate backgroundAreaForPopoverController:self relativeToView:view];
    }
    return rect;
}

- (UIView *)parentView {
    UIView *ret = _parentView;
    if (ret == nil && _parentViewController != nil) {
        ret = _parentViewController.view;
    }
    return ret;
}

@end


@implementation WEPopoverController(Private)

- (UIView *)topMostAncestorForView:(UIView *)view {
    UIView *v = view;
    while (v.superview != nil) {
        v = v.superview;
    }
    return v;
}

- (BOOL)isView:(UIView *)v1 inSameHierarchyAsView:(UIView *)v2 {
    return ([self topMostAncestorForView:v1] == [self topMostAncestorForView:v2]) || (v1.window == v2.window);
}

- (UIView *)keyViewForView:(UIView *)theView {
    if (self.parentView) {
        return self.parentView;
    } else {
        UIWindow *w = nil;
        if (theView.window) {
            w = theView.window;
        } else {
            w = [[UIApplication sharedApplication] keyWindow];
        }
        if (w.subviews.count > 0 && (theView == nil || [self isView:theView inSameHierarchyAsView:[w.subviews objectAtIndex:0]])) {
            return [w.subviews objectAtIndex:0];
        } else {
            return w;
        }
    }
}

- (void)updateBackgroundPassthroughViews {
	self.backgroundView.passthroughViews = self.passthroughViews;
}

- (void)determineContentSize {
    if (CGSizeEqualToSize(self.popoverContentSize, CGSizeZero)) {
        if ([_contentViewController respondsToSelector:@selector(preferredContentSize)]) {
            self.effectivePopoverContentSize = _contentViewController.preferredContentSize;
        } else {
            self.effectivePopoverContentSize = _contentViewController.contentSizeForViewInPopover;
        }
	} else {
        self.effectivePopoverContentSize = self.popoverContentSize;
    }
}

- (void)dismissPopoverAnimated:(BOOL)animated userInitiated:(BOOL)userInitiated completion:(WEPopoverCompletionBlock)completion {
	if (self.containerView && !self.isDismissing && !self.isPresenting) {
        self.dismissing = YES;
		[self.containerView resignFirstResponder];
        
        void (^animationCompletionBlock)(BOOL finished) = ^(BOOL finished) {
            self.popoverVisible = NO;
            
            [self removeView];
            
            self.dismissing = NO;
            
            if (userInitiated) {
                //Only send message to delegate in case the user initiated this event, which is if he touched outside the view
                if ([_delegate respondsToSelector:@selector(popoverControllerDidDismissPopover:)]) {
                    [_delegate popoverControllerDidDismissPopover:self];
                }
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:WEPopoverControllerDidDismissNotification object:self];
            
            if (self.afterDismissBlock) {
                self.afterDismissBlock();
            }
            
            if (completion) {
                completion();
            }
        };
        
        //To avoid repositions happening during frame change
        self.containerView.delegate = nil;
		if (animated) {
			self.containerView.userInteractionEnabled = NO;
            
            if (self.animationType == WEPopoverAnimationTypeSlide) {
                
                CGRect collapsedFrame = [self collapsedFrameFromFrame:self.containerView.frame forArrowDirection:_popoverArrowDirection];
                
                NSTimeInterval firstAnimationDuration = self.secundaryAnimationDuration;
                NSTimeInterval secondAnimationDuration = self.primaryAnimationDuration;
                
                animate(firstAnimationDuration, ^{
                    
                    [self.containerView setArrowCollapsed:YES];
                    
                }, ^(BOOL finished) {
                    
                    animate(secondAnimationDuration, ^{
                        [self.containerView setFrame:collapsedFrame sendNotification:NO];
                        _backgroundView.fillView.alpha = 0.0f;
                        
                        if (self.transitionBlock) {
                            self.transitionBlock(WEPopoverTransitionTypeDismiss, animated);
                        }
                        
                    }, animationCompletionBlock);
                    
                });
            } else {
                animate(self.primaryAnimationDuration, ^{
                    
                    self.containerView.alpha = 0.0;
                    self.backgroundView.fillView.alpha = 0.0f;
                    
                    if (self.transitionBlock) {
                        self.transitionBlock(WEPopoverTransitionTypeDismiss, animated);
                    }
                    
                }, animationCompletionBlock);
            }
            
		} else {
            if (self.transitionBlock) {
                self.transitionBlock(WEPopoverTransitionTypeDismiss, animated);
            }
            animationCompletionBlock(YES);
		}
	}
}

- (void)removeView {
    [self updateContentViewController:nil withOldContentViewController:_contentViewController animated:NO];
    [self.containerView removeFromSuperview];
    self.containerView = nil;
    [_backgroundView removeFromSuperview];
    _backgroundView = nil;
    
    _presentedFromView = nil;
    _presentedFromRect = CGRectZero;
}

- (CGRect)displayAreaForView:(UIView *)theView {
    
    UIView *keyView = [self keyViewForView:theView];

    BOOL inViewHierarchy = [self isView:theView inSameHierarchyAsView:keyView];
    
    if (!inViewHierarchy) {
        NSException *ex = [NSException exceptionWithName:@"WEInvalidViewHierarchyException" reason:@"The supplied view to present the popover from is not in the same view hierarchy as the parent view for the popover" userInfo:nil];
        @throw ex;
    }

	CGRect displayArea = CGRectZero;
    
    UIEdgeInsets insets = self.popoverLayoutMargins;
    
    if ([self.delegate respondsToSelector:@selector(displayAreaForPopoverController:relativeToView:)]) {
        displayArea = [self.delegate displayAreaForPopoverController:self relativeToView:keyView];
        displayArea = [keyView convertRect:displayArea toView:theView];
    } else if ([theView conformsToProtocol:@protocol(WEPopoverParentView)] && [theView respondsToSelector:@selector(displayAreaForPopover)]) {
		displayArea = [(id <WEPopoverParentView>)theView displayAreaForPopover];
	} else {
        displayArea = [keyView convertRect:keyView.bounds toView:theView];
        
        if (self.parentView == nil) {
            //Add status bar height
            insets.top += 20.0f;
        }
	}
    
    displayArea = UIEdgeInsetsInsetRect(displayArea, insets);
	return displayArea;
}

- (void)repositionContainerViewForFrameChange {
    if (_presentedFromView != nil) {
        @try {
            CGRect displayArea = [self displayAreaForView:_presentedFromView];
            WEPopoverContainerView *containerView = self.containerView;

            containerView.delegate = nil;

            [containerView updatePositionWithSize:self.effectivePopoverContentSize
                                       anchorRect:_presentedFromRect
                                      displayArea:displayArea
                         permittedArrowDirections:_popoverArrowDirection];

            UIView *theView = _backgroundView;
            CGRect theRect = [_presentedFromView convertRect:containerView.calculatedFrame toView:theView];

            if ([self.delegate respondsToSelector:@selector(popoverController:willRepositionPopoverToRect:inView:)]) {
                [self.delegate popoverController:self willRepositionPopoverToRect:&theRect inView:&theView];
                theRect = [theView convertRect:theRect toView:containerView.superview];
            }

            [containerView setFrame:theRect sendNotification:NO];
            containerView.delegate = self;
        }
        @catch (NSException *exception) {
            //Ignore: cannot reposition popover
        }
    }
}

- (CGRect)collapsedFrameFromFrame:(CGRect)frame forArrowDirection:(UIPopoverArrowDirection)arrowDirection {
    CGRect ret = frame;
    if (arrowDirection == UIPopoverArrowDirectionUp) {
        ret = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 0);
    } else if (arrowDirection == UIPopoverArrowDirectionDown) {
        ret = CGRectMake(frame.origin.x, frame.origin.y + frame.size.height, frame.size.width, 0);
    } else if (arrowDirection == UIPopoverArrowDirectionLeft) {
        ret = CGRectMake(frame.origin.x, frame.origin.y, 0, frame.size.height);
    } else if (arrowDirection == UIPopoverArrowDirectionRight) {
        ret = CGRectMake(frame.origin.x + frame.size.width, frame.origin.y, 0, frame.size.height);
    }
    return ret;
}

- (UIView *)fillBackgroundViewWithDefault:(UIView *)defaultView {
    UIView *ret = defaultView;
    if ([self.delegate respondsToSelector:@selector(backgroundViewForPopoverController:)]) {
        ret = [self.delegate backgroundViewForPopoverController:self];
    } else if (self.backgroundViewClass != nil && [self.backgroundViewClass isSubclassOfClass:[UIView class]]) {
        ret = [self.backgroundViewClass new];
    }
    return ret;
}

@end

