//  Created by Monte Hurd on 3/17/14.

#import "TopActionSheetScrollView.h"
#import "UIView+RemoveConstraints.h"

#define ANIMATION_DURATION 0.23f

@interface TopActionSheetScrollView()

@property (strong, atomic) UIView *containerView;

@end

@implementation TopActionSheetScrollView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.orientation = TOP_ACTION_SHEET_LAYOUT_HORIZONTAL;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.clipsToBounds = YES;

        [self setupViews];
    }
    return self;
}

-(void)setupViews
{
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor clearColor];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:self.containerView];

    [self constrainContainerView];
}

-(void)constrainContainerView
{
    NSDictionary *views = @{@"view": self.containerView};
    
    NSArray *constraints =
    @[
      [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:views],
      
      [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:views],
      
      @[[NSLayoutConstraint constraintWithItem: self.containerView
                                     attribute: NSLayoutAttributeWidth
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: self
                                     attribute: NSLayoutAttributeWidth
                                    multiplier: 1.0
                                      constant: 0]]
      
      ];
    
    [self addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];
}

-(void)setTopActionSheetSubviews:(NSArray *)topActionSheetSubviews
{
    if (self.containerView.subviews) {
        [self.containerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    
    for (UIView *view in [topActionSheetSubviews reverseObjectEnumerator]) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.containerView addSubview:view];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
        [view addGestureRecognizer:tap];
        view.userInteractionEnabled = YES;
    }
    
    [self setNeedsUpdateConstraints];
}

-(void)viewTapped:(id)sender
{
    UIView *tappedView = nil;
    if([sender isKindOfClass:[UIGestureRecognizer class]]){
        tappedView = ((UIGestureRecognizer *)sender).view;
    }else{
        tappedView = sender;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TopActionSheetItemTapped" object:self userInfo:
        @{@"tappedItem": tappedView}
    ];
}

-(void)setOrientation:(TopActionSheetLayoutOrientation)orientation
{
    if (_orientation != orientation) {
        _orientation = orientation;
        
        [self constrainContainerViewSubviews];
        [UIView animateWithDuration:ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self layoutIfNeeded];
        } completion:^(BOOL done){
        }];
    }
}

-(void)updateConstraints
{
    [self constrainContainerViewSubviews];
    [super updateConstraints];
}

-(void)constrainContainerViewSubviews
{
    // Remove existing constraints so orientation can be changed on the fly.
    for (UIView *view in self.containerView.subviews) {
        [view removeConstraintsOfViewFromView:self];
    }

    switch (self.orientation) {
        case TOP_ACTION_SHEET_LAYOUT_HORIZONTAL:
            [self constrainContainerViewSubviewsHorizontally];
            break;
        case TOP_ACTION_SHEET_LAYOUT_VERTICAL:
            [self constrainContainerViewSubviewsVertically];
            break;
        default:
            break;
    }
}

-(void)constrainContainerViewSubviewsVertically
{
    NSMutableArray *constraints = @[].mutableCopy;
    
    id prevView = nil;
    for (UIView *view in self.containerView.subviews) {
        if (prevView) {
            [constraints addObject:@[[NSLayoutConstraint constraintWithItem: view
                                                                  attribute: NSLayoutAttributeLeft
                                                                  relatedBy: NSLayoutRelationEqual
                                                                     toItem: prevView
                                                                  attribute: NSLayoutAttributeRight
                                                                 multiplier: 1.0
                                                                   constant: 0]]];
            
            [constraints addObject:@[[NSLayoutConstraint constraintWithItem: view
                                                                  attribute: NSLayoutAttributeWidth
                                                                  relatedBy: NSLayoutRelationEqual
                                                                     toItem: prevView
                                                                  attribute: NSLayoutAttributeWidth
                                                                 multiplier: 1.0
                                                                   constant: 0]]];
        }else{
            [constraints addObject:@[[NSLayoutConstraint constraintWithItem: view
                                                                  attribute: NSLayoutAttributeLeft
                                                                  relatedBy: NSLayoutRelationEqual
                                                                     toItem: self.containerView
                                                                  attribute: NSLayoutAttributeLeft
                                                                 multiplier: 1.0
                                                                   constant: 0]]];
        }
        [constraints addObject:@[[NSLayoutConstraint constraintWithItem: view
                                                              attribute: NSLayoutAttributeTop
                                                              relatedBy: NSLayoutRelationEqual
                                                                 toItem: self.containerView
                                                              attribute: NSLayoutAttributeTop
                                                             multiplier: 1.0
                                                               constant: 0]]];
        
        [constraints addObject:@[[NSLayoutConstraint constraintWithItem: view
                                                              attribute: NSLayoutAttributeBottom
                                                              relatedBy: NSLayoutRelationEqual
                                                                 toItem: self.containerView
                                                              attribute: NSLayoutAttributeBottom
                                                             multiplier: 1.0
                                                               constant: 0]]];
        
        if (view == self.containerView.subviews.lastObject) {
            [constraints addObject:@[[NSLayoutConstraint constraintWithItem: view
                                                                  attribute: NSLayoutAttributeRight
                                                                  relatedBy: NSLayoutRelationEqual
                                                                     toItem: self.containerView
                                                                  attribute: NSLayoutAttributeRight
                                                                 multiplier: 1.0
                                                                   constant: 0]]];
        }
        
        prevView = view;
    }
    
    [self addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];
}

-(void)constrainContainerViewSubviewsHorizontally
{
    NSMutableArray *constraints = @[].mutableCopy;

    id prevView = nil;
    for (UIView *view in self.containerView.subviews) {
        if (prevView) {
            [constraints addObject:@[[NSLayoutConstraint constraintWithItem: view
                                                                  attribute: NSLayoutAttributeBottom
                                                                  relatedBy: NSLayoutRelationEqual
                                                                     toItem: prevView
                                                                  attribute: NSLayoutAttributeTop
                                                                 multiplier: 1.0
                                                                   constant: 0]]];
        }else{
            [constraints addObject:@[[NSLayoutConstraint constraintWithItem: view
                                                                  attribute: NSLayoutAttributeBottom
                                                                  relatedBy: NSLayoutRelationEqual
                                                                     toItem: self.containerView
                                                                  attribute: NSLayoutAttributeBottom
                                                                 multiplier: 1.0
                                                                   constant: 0]]];
        }
        
        if (view == self.containerView.subviews.lastObject) {
            [constraints addObject:@[[NSLayoutConstraint constraintWithItem: view
                                                                  attribute: NSLayoutAttributeTop
                                                                  relatedBy: NSLayoutRelationEqual
                                                                     toItem: self.containerView
                                                                  attribute: NSLayoutAttributeTop
                                                                 multiplier: 1.0
                                                                   constant: 0]]];
        }
        
        [constraints addObject:[NSLayoutConstraint constraintsWithVisualFormat: @"H:|[view]|"
                                                                       options: 0
                                                                       metrics: 0
                                                                         views: NSDictionaryOfVariableBindings(view)]];
        
        CGFloat minHeight = 55.0f;
        
        [constraints addObject:[NSLayoutConstraint constraintsWithVisualFormat: @"V:[view(>=height)]"
                                                                       options: 0
                                                                       metrics: @{@"height": @(minHeight)}
                                                                         views: NSDictionaryOfVariableBindings(view)]];
        prevView = view;
    }
    
    [self addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];
}

@end
