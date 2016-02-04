//  Created by Monte Hurd on 3/17/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TabularScrollView.h"
#import "UIView+RemoveConstraints.h"

@interface TabularScrollView ()

@property (strong, nonatomic) UIView* containerView;

@end

@implementation TabularScrollView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.minSubviewHeight                          = 55.0f;
    self.orientation                               = TABULAR_SCROLLVIEW_LAYOUT_HORIZONTAL;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.clipsToBounds                             = YES;

    [self setupViews];
}

- (void)setupViews {
    self.containerView                                           = [[UIView alloc] init];
    self.containerView.backgroundColor                           = [UIColor clearColor];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:self.containerView];
}

- (void)constrainContainerView {
    [self.containerView removeConstraintsOfViewFromView:self];

    NSDictionary* views = @{@"view": self.containerView};

    NSArray* constraints =
        @[
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:views],

        [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:views],

        @[[NSLayoutConstraint constraintWithItem:self.containerView
                                       attribute:NSLayoutAttributeWidth
                                       relatedBy:NSLayoutRelationEqual
                                          toItem:self
                                       attribute:NSLayoutAttributeWidth
                                      multiplier:1.0
                                        constant:0]]

    ];

    [self addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];
}

- (void)setTabularSubviews:(NSArray*)tabularSubviews {
    // Reminder: iOS 6 can crash (tap "Login" then tap "X" to go back to left menu) for
    // some reason if we don't delay execution of this stuff to next run loop iteration.
    // Probably has to do with calling this method from a view controller's
    // viewWillAppear method - crash doesn't seem to happend from viewDidLoad.
    [[NSRunLoop currentRunLoop] performSelector:@selector(actuallySetTabularSubviews:)
                                         target:self
                                       argument:tabularSubviews
                                          order:0
                                          modes:[NSArray arrayWithObject:@"NSDefaultRunLoopMode"]];
}

- (void)actuallySetTabularSubviews:(NSArray*)tabularSubviews {
    if (self.containerView.subviews) {
        [self.containerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }

    for (UIView* view in [tabularSubviews reverseObjectEnumerator]) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.containerView addSubview:view];

        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
        [view addGestureRecognizer:tap];
        view.userInteractionEnabled = YES;
    }

    [self setNeedsUpdateConstraints];
}

- (void)viewTapped:(id)sender {
    UIView* tappedView      = nil;
    UIView* tappedChildView = nil;

    if ([sender isKindOfClass:[UIGestureRecognizer class]]) {
        UIGestureRecognizer* recognizer = (UIGestureRecognizer*)sender;
        if (recognizer.state != UIGestureRecognizerStateEnded) {
            return;
        }
        tappedView = recognizer.view;
        CGPoint loc = [recognizer locationInView:tappedView];
        tappedChildView = [tappedView hitTest:loc withEvent:nil];
    } else {
        tappedView = sender;
    }

    if (!tappedView) {
        return;
    }

    NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithObject:tappedView forKey:@"tappedItem"];
    if (tappedChildView) {
        [userInfo setObject:tappedChildView forKey:@"tappedChild"];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"TabularScrollViewItemTapped" object:self userInfo:userInfo];
}

- (void)setOrientation:(TabularScrollViewOrientation)orientation {
    if (_orientation != orientation) {
        _orientation = orientation;
        [self setNeedsUpdateConstraints];
    }
}

- (void)updateConstraints {
    [self constrainContainerView];
    [self constrainContainerViewSubviews];
    [super updateConstraints];
}

- (void)constrainContainerViewSubviews {
    // Remove existing constraints so orientation can be changed on the fly.
    for (UIView* view in self.containerView.subviews) {
        [view removeConstraintsOfViewFromView:self];
    }

    switch (self.orientation) {
        case TABULAR_SCROLLVIEW_LAYOUT_HORIZONTAL:
            [self constrainContainerViewSubviewsHorizontally];
            break;
        case TABULAR_SCROLLVIEW_LAYOUT_VERTICAL:
            [self constrainContainerViewSubviewsVertically];
            break;
        default:
            break;
    }
}

- (void)constrainContainerViewSubviewsVertically {
    NSMutableArray* constraints = @[].mutableCopy;

    id prevView = nil;
    for (UIView* view in self.containerView.subviews) {
        if (prevView) {
            [constraints addObject:@[[NSLayoutConstraint constraintWithItem:view
                                                                  attribute:NSLayoutAttributeLeft
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:prevView
                                                                  attribute:NSLayoutAttributeRight
                                                                 multiplier:1.0
                                                                   constant:0]]];

            [constraints addObject:@[[NSLayoutConstraint constraintWithItem:view
                                                                  attribute:NSLayoutAttributeWidth
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:prevView
                                                                  attribute:NSLayoutAttributeWidth
                                                                 multiplier:1.0
                                                                   constant:0]]];
        } else {
            [constraints addObject:@[[NSLayoutConstraint constraintWithItem:view
                                                                  attribute:NSLayoutAttributeLeft
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.containerView
                                                                  attribute:NSLayoutAttributeLeft
                                                                 multiplier:1.0
                                                                   constant:0]]];
        }
        [constraints addObject:@[[NSLayoutConstraint constraintWithItem:view
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.containerView
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:0]]];

        [constraints addObject:@[[NSLayoutConstraint constraintWithItem:view
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.containerView
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0]]];

        if (view == self.containerView.subviews.lastObject) {
            [constraints addObject:@[[NSLayoutConstraint constraintWithItem:view
                                                                  attribute:NSLayoutAttributeRight
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.containerView
                                                                  attribute:NSLayoutAttributeRight
                                                                 multiplier:1.0
                                                                   constant:0]]];
        }

        prevView = view;
    }

    [self addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];
}

- (void)constrainContainerViewSubviewsHorizontally {
    NSMutableArray* constraints = @[].mutableCopy;

    id prevView = nil;
    for (UIView* view in self.containerView.subviews) {
        if (prevView) {
            [constraints addObject:@[[NSLayoutConstraint constraintWithItem:view
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:prevView
                                                                  attribute:NSLayoutAttributeTop
                                                                 multiplier:1.0
                                                                   constant:0]]];
        } else {
            [constraints addObject:@[[NSLayoutConstraint constraintWithItem:view
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.containerView
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1.0
                                                                   constant:0]]];
        }

        if (view == self.containerView.subviews.lastObject) {
            [constraints addObject:@[[NSLayoutConstraint constraintWithItem:view
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.containerView
                                                                  attribute:NSLayoutAttributeTop
                                                                 multiplier:1.0
                                                                   constant:0]]];
        }

        [constraints addObject:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                       options:0
                                                                       metrics:0
                                                                         views:NSDictionaryOfVariableBindings(view)]];

        [constraints addObject:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[view(>=height)]"
                                                                       options:0
                                                                       metrics:@{@"height": @(self.minSubviewHeight)}
                                                                         views:NSDictionaryOfVariableBindings(view)]];
        prevView = view;
    }

    [self addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];
}

@end
