//  Created by Monte Hurd on 12/16/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikipediaAppUtils.h"
#import "NavBarTextField.h"
#import "NavController.h"
#import "Defines.h"
#import "UIView+Debugging.h"
#import "UIView+RemoveConstraints.h"
#import "NavBarContainerView.h"
#import "MainMenuViewController.h"
#import "UIViewController+HideKeyboard.h"
#import "SearchResultsController.h"
#import "UINavigationController+SearchNavStack.h"
#import "UIButton+ColorMask.h"
#import "UINavigationController+Alert.h"
#import "PreviewAndSaveViewController.h"

#import "SessionSingleton.h"
#import "WebViewController.h"
#import "UIView+TemporaryAnimatedXF.h"
#import "SectionEditorViewController.h"

@interface NavController (){

}

// Container.
@property (strong, nonatomic) UIView *navBarContainer;

// Views which go into the container.
@property (strong, nonatomic) NavBarTextField *textField;
@property (strong, nonatomic) UIView *verticalLine1;
@property (strong, nonatomic) UIView *verticalLine2;
@property (strong, nonatomic) UIView *verticalLine3;
@property (strong, nonatomic) UIView *verticalLine4;
@property (strong, nonatomic) UIView *verticalLine5;
@property (strong, nonatomic) UIView *verticalLine6;
@property (strong, nonatomic) UIButton *buttonW;
@property (strong, nonatomic) UIButton *buttonPencil;
@property (strong, nonatomic) UIButton *buttonCheck;
@property (strong, nonatomic) UIButton *buttonX;
@property (strong, nonatomic) UIButton *buttonEye;
@property (strong, nonatomic) UIButton *buttonCC;
@property (strong, nonatomic) UIButton *buttonArrowLeft;
@property (strong, nonatomic) UIButton *buttonArrowRight;
@property (strong, nonatomic) UILabel *label;

// Used for constraining container sub-views.
@property (strong, nonatomic) NSString *navBarSubViewsHorizontalVFLString;
@property (strong, nonatomic) NSDictionary *navBarSubViews;
@property (strong, nonatomic) NSDictionary *navBarSubViewMetrics;

@property (nonatomic) BOOL isTransitioningBetweenViewControllers;

@end

@implementation NavController

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
 
    self.delegate = self;
 
    self.currentSearchResultsOrdered = [@[] mutableCopy];
    self.currentSearchString = @"";

    [self setupNavbarContainer];
    [self setupNavbarContainerSubviews];

    self.navBarStyle = NAVBAR_STYLE_DAY;

    self.navBarMode = NAVBAR_MODE_SEARCH;

    [self.navigationBar addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:nil];
    
    self.navBarSubViews = [self getNavBarSubViews];
    
    self.navBarSubViewMetrics = [self getNavBarSubViewMetrics];
    
    self.isTransitioningBetweenViewControllers = NO;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Listen for nav bar taps.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(navItemTappedNotification:)
                                                 name: @"NavItemTapped"
                                               object: nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"NavItemTapped"
                                                  object: nil];

    [super viewWillDisappear:animated];
}

#pragma mark Constraints

-(void)updateViewConstraints
{
    [super updateViewConstraints];

    [self constrainNavBarContainer];
    [self constrainNavBarContainerSubViews];

    [self.navBarContainer layoutIfNeeded];
    
    // Disabled the animations because they're a little funky with the alpha tweening... can revisit later if needed.
    //[self animateNavConstraintChanges];
}

-(void)animateNavConstraintChanges
{
    CGFloat duration = 0.3f;
    for (UIView *v in self.navBarContainer.subviews) v.alpha = 0.0f;

    [UIView animateWithDuration:(duration / 2.0f) delay:0.0f options:UIViewAnimationOptionTransitionNone animations:^{
        for (UIView *v in self.navBarContainer.subviews) v.alpha = 0.7f;
        [self.navBarContainer layoutIfNeeded];
    } completion:^(BOOL done){
        [UIView animateWithDuration:(duration / 2.0f) delay:0.1f options:UIViewAnimationOptionTransitionNone animations:^{
            for (UIView *v in self.navBarContainer.subviews) v.alpha = 1.0f;
        } completion:^(BOOL done){
        }];
    }];
}

- (void)navigationController: (UINavigationController *)navigationController
      willShowViewController: (UIViewController *)viewController
                    animated: (BOOL)animated
{
    self.isTransitioningBetweenViewControllers = YES;

    [self showAlert:@""];
    [self showHTMLAlert:@"" bannerImage:nil bannerColor:nil];
}

- (void)navigationController: (UINavigationController *)navigationController
       didShowViewController: (UIViewController *)viewController
                    animated: (BOOL)animated
{
    self.isTransitioningBetweenViewControllers = NO;
}

-(void)setIsTransitioningBetweenViewControllers:(BOOL)isTransitioningBetweenViewControllers
{
    _isTransitioningBetweenViewControllers = isTransitioningBetweenViewControllers;
    
    // Disabling userInteractionEnabled when nav stack views are being pushed/popped prevents
    // "nested push animation can result in corrupted navigation bar" and "unbalanced calls
    // to begin/end appearance transitions" errors. If this line is commented out, you can
    // trigger the error by rapidly tapping on the main menu toggle (the "W" icon presently).
    // You can also trigger another error by tapping the edit pencil, then tap the "X" icon
    // then very quickly tap the "W" icon.
    self.view.userInteractionEnabled = !isTransitioningBetweenViewControllers;
}

-(void)constrainNavBarContainer
{
    // Remove existing navBarContainer constraints.
    [self.navBarContainer removeConstraintsOfViewFromView:self.view];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"H:|[navBarContainer]|"
                                                                      options: 0
                                                                      metrics: nil
                                                                        views: @{@"navBarContainer": self.navBarContainer}]];
    NSArray *constraintsArray = @[
                                  [NSLayoutConstraint constraintWithItem: self.navBarContainer
                                                               attribute: NSLayoutAttributeTop
                                                               relatedBy: NSLayoutRelationEqual
                                                                  toItem: self.view
                                                               attribute: NSLayoutAttributeTop
                                                              multiplier: 1.0
                                                                constant: self.navigationBar.frame.origin.y]
                                  ,
                                  [NSLayoutConstraint constraintWithItem: self.navBarContainer
                                                               attribute: NSLayoutAttributeHeight
                                                               relatedBy: NSLayoutRelationEqual
                                                                  toItem: NSLayoutAttributeNotAnAttribute
                                                               attribute: 0
                                                              multiplier: 1.0
                                                                constant: self.navigationBar.bounds.size.height]
                                  ];
    [self.view addConstraints:constraintsArray];
}

-(void)constrainNavBarContainerSubViews
{
    // Remove *all* navBarContainer constraints.
    [self.navBarContainer removeConstraints:self.navBarContainer.constraints];

    // Hide all navBarContainer subviews. Only those affected by navBarSubViewsHorizontalVFLString
    // will be revealed.
    for (UIView *v in [self.navBarContainer.subviews copy]) {
        v.hidden = YES;
    }

    // navBarSubViewsHorizontalVFLString controls which elements are going to be shown.
    [self.navBarContainer addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat: self.navBarSubViewsHorizontalVFLString
                                             options: 0
                                             metrics: self.navBarSubViewMetrics
                                               views: self.navBarSubViews
      ]
     ];
    
    CGFloat verticalLineTopMargin = 0;
    
    // Now take the views which were constrained horizontally (above) and constrain them
    // vertically as well. Also set hidden = NO for just these views.
    for (NSLayoutConstraint *c in [self.navBarContainer.constraints copy]) {
        UIView *view = (c.firstItem != self.navBarContainer) ? c.firstItem: c.secondItem;
        view.hidden = NO;
        [self.navBarContainer addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-(topMargin)-[view]|"
                                                 options: 0
                                                 metrics: @{@"topMargin": @((view.tag == NAVBAR_VERTICAL_LINE) ? verticalLineTopMargin : 0)}
                                                   views: NSDictionaryOfVariableBindings(view)
          ]
         ];
    }
    
    // Return can be uncommented here if we re-enable "animateNavConstraintChanges" in the future...
    return;

    // Constrain the views not being presently shown so when they are shown they'll animate from
    // the constrained position specified below.
    for (UIView *view in [self.navBarContainer.subviews copy]) {
        if (view.hidden) {
            [self.navBarContainer addConstraint:
             [NSLayoutConstraint constraintWithItem: view
                                          attribute: NSLayoutAttributeRight
                                          relatedBy: NSLayoutRelationEqual
                                             toItem: self.navBarContainer
                                          attribute: NSLayoutAttributeLeft
                                         multiplier: 1.0
                                           constant: 0.0
              ]
            ];
            [self.navBarContainer addConstraints:
             [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-(topMargin)-[view]|"
                                                     options: 0
                                                     metrics: @{@"topMargin": @((view.tag == NAVBAR_VERTICAL_LINE) ? verticalLineTopMargin : 0)}
                                                       views: NSDictionaryOfVariableBindings(view)
              ]
             ];
        }
    }
}

#pragma mark Setup

-(void)setupNavbarContainerSubviews
{
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.navigationBar.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:0.97];
    }

    self.textField = [[NavBarTextField alloc] init];
    self.textField.delegate = self;
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.font = SEARCH_FONT;
    self.textField.textColor = SEARCH_FONT_HIGHLIGHTED_COLOR;
    self.textField.tag = NAVBAR_TEXT_FIELD;
    self.textField.clearButtonMode = UITextFieldViewModeNever;
    self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [self.textField addTarget:self action:@selector(postNavItemTappedNotification:) forControlEvents:UIControlEventTouchUpInside];
    self.textField.placeholder = MWLocalizedString(@"search-field-placeholder-text", nil);

    // Perform search when text entered into textField
    [self.textField addTarget:self action:@selector(searchStringChanged) forControlEvents:UIControlEventEditingChanged];
    
    [self.navBarContainer addSubview:self.textField];
 
    UIButton *clearButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 26, 26)];
    clearButton.backgroundColor = [UIColor clearColor];
    [clearButton setImage:[UIImage imageNamed:@"text_field_x_circle_gray.png"] forState:UIControlStateNormal];
    [clearButton addTarget:self action:@selector(clearTextFieldText) forControlEvents:UIControlEventTouchUpInside];
    
    self.textField.rightView = clearButton;
    self.textField.rightViewMode = UITextFieldViewModeAlways;
    self.textField.rightView.hidden = YES;

    UIView *(^getLineView)() = ^UIView *() {
        UIView *view = [[UIView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.backgroundColor = [UIColor lightGrayColor];
        view.tag = NAVBAR_VERTICAL_LINE;
        return view;
    };
    
    self.verticalLine1 = getLineView();
    self.verticalLine2 = getLineView();
    self.verticalLine3 = getLineView();
    self.verticalLine4 = getLineView();
    self.verticalLine5 = getLineView();
    self.verticalLine6 = getLineView();
    
    [self.navBarContainer addSubview:self.verticalLine1];
    [self.navBarContainer addSubview:self.verticalLine2];
    [self.navBarContainer addSubview:self.verticalLine3];
    [self.navBarContainer addSubview:self.verticalLine4];
    [self.navBarContainer addSubview:self.verticalLine5];
    [self.navBarContainer addSubview:self.verticalLine6];

    UIButton *(^getButton)(NSString *, NavBarItemTag) = ^UIButton *(NSString *image, NavBarItemTag tag) {
        UIButton *button = [[UIButton alloc] init];
        [button setTitle:@"" forState:UIControlStateNormal];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.backgroundColor = [UIColor clearColor];
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [button setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:image] forState:UIControlStateSelected];
        [button setImage:[UIImage imageNamed:image] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(postNavItemTappedNotification:) forControlEvents:UIControlEventTouchUpInside];

        button.tag = tag;
        return button;
    };

    self.buttonPencil =     getButton(@"abuse-filter-edit-black.png",   NAVBAR_BUTTON_PENCIL);
    self.buttonCheck =      getButton(@"abuse-filter-check.png",        NAVBAR_BUTTON_CHECK);
    self.buttonX =          getButton(@"button_cancel_grey.png",        NAVBAR_BUTTON_X);
    self.buttonEye =        getButton(@"button_preview_white.png",      NAVBAR_BUTTON_EYE);
    self.buttonCC =         getButton(@"button_cc_black.png",           NAVBAR_BUTTON_CC);
    self.buttonArrowLeft =  getButton(@"button_arrow_left.png",         NAVBAR_BUTTON_ARROW_LEFT);
    self.buttonArrowRight = getButton(@"button_arrow_right.png",        NAVBAR_BUTTON_ARROW_RIGHT);
    self.buttonW =          getButton(@"w.png",                         NAVBAR_BUTTON_LOGO_W);

    [self.navBarContainer addSubview:self.buttonPencil];
    [self.navBarContainer addSubview:self.buttonCheck];
    [self.navBarContainer addSubview:self.buttonX];
    [self.navBarContainer addSubview:self.buttonEye];
    [self.navBarContainer addSubview:self.buttonCC];
    [self.navBarContainer addSubview:self.buttonArrowLeft];
    [self.navBarContainer addSubview:self.buttonArrowRight];
    [self.navBarContainer addSubview:self.buttonW];

    self.label = [[UILabel alloc] init];
    self.label.text = @"";
    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    self.label.tag = NAVBAR_LABEL;
    self.label.font = [UIFont boldSystemFontOfSize:15.0];
    self.label.textColor = [UIColor darkGrayColor];
    self.label.backgroundColor = [UIColor clearColor];
    self.label.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapLabel = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(postNavItemTappedNotification:)];
    [self.label addGestureRecognizer:tapLabel];
    [self.navBarContainer addSubview:self.label];
}

-(void)setupNavbarContainer
{
    self.navBarContainer = [[NavBarContainerView alloc] init];
    self.navBarContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.navBarContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.navBarContainer];
}

#pragma mark Nav bar items

-(id)getNavBarItem:(NavBarItemTag)tag
{
    for (UIView *view in self.navBarContainer.subviews) {
        if (view.tag == tag) return view;
    }
    return nil;
}

-(NSDictionary *)getNavBarSubViews
{
    return @{
             @"NAVBAR_BUTTON_X": self.buttonX,
             @"NAVBAR_BUTTON_PENCIL": self.buttonPencil,
             @"NAVBAR_BUTTON_CHECK": self.buttonCheck,
             @"NAVBAR_BUTTON_ARROW_LEFT": self.buttonArrowLeft,
             @"NAVBAR_BUTTON_ARROW_RIGHT": self.buttonArrowRight,
             @"NAVBAR_BUTTON_LOGO_W": self.buttonW,
             @"NAVBAR_BUTTON_EYE": self.buttonEye,
             @"NAVBAR_BUTTON_CC": self.buttonCC,
             @"NAVBAR_TEXT_FIELD": self.textField,
             @"NAVBAR_LABEL": self.label,
             @"NAVBAR_VERTICAL_LINE_1": self.verticalLine1,
             @"NAVBAR_VERTICAL_LINE_2": self.verticalLine2,
             @"NAVBAR_VERTICAL_LINE_3": self.verticalLine3,
             @"NAVBAR_VERTICAL_LINE_4": self.verticalLine4,
             @"NAVBAR_VERTICAL_LINE_5": self.verticalLine5,
             @"NAVBAR_VERTICAL_LINE_6": self.verticalLine6
             };
}

-(NSDictionary *)getNavBarSubViewMetrics
{
    return @{
             @"singlePixel": @(1.0f / [UIScreen mainScreen].scale)
             };
}

-(void)clearViewControllerTitles
{
    // Without this 3 little blue dots can appear on left of nav bar on iOS 7 during animations.
    [self.viewControllers makeObjectsPerformSelector:@selector(setTitle:) withObject:@""];
}

-(void)setNavBarMode:(NavBarMode)navBarMode
{
    [self clearViewControllerTitles];

    PreviewAndSaveViewController *previewAndSaveVC = [self searchNavStackForViewControllerOfClass:[PreviewAndSaveViewController class]];

    _navBarMode = navBarMode;
    switch (navBarMode) {
        case NAVBAR_MODE_EDIT_WIKITEXT:
            self.label.text = MWLocalizedString(@"navbar-title-mode-edit-wikitext", nil);
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_X(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL][NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_EYE(50)]|";
            break;
        case NAVBAR_MODE_LOGIN:
            self.label.text = (!previewAndSaveVC) ?
                MWLocalizedString(@"navbar-title-mode-login", nil)
                :
                MWLocalizedString(@"navbar-title-mode-login-and-save", nil)
            ;
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_X(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL][NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_CHECK(50)]|";
            break;
        case NAVBAR_MODE_EDIT_WIKITEXT_LOGIN_OR_SAVE_ANONYMOUSLY:
            self.label.text = @"";
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_ARROW_LEFT(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL][NAVBAR_BUTTON_CC(50)][NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_CHECK(50)]|";
            break;
        case NAVBAR_MODE_CREATE_ACCOUNT:
            self.label.text = (!previewAndSaveVC) ?
                MWLocalizedString(@"navbar-title-mode-create-account", nil)
                :
                MWLocalizedString(@"navbar-title-mode-create-account-and-save", nil)
            ;
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_ARROW_LEFT(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL][NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_CHECK(50)]|";
            break;
        case NAVBAR_MODE_EDIT_WIKITEXT_WARNING:
            self.label.text = MWLocalizedString(@"navbar-title-mode-edit-wikitext-warning", nil);
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_ARROW_LEFT(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL][NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_CHECK(50)]|";
            break;
        case NAVBAR_MODE_EDIT_WIKITEXT_DISALLOW:
            self.label.text = MWLocalizedString(@"navbar-title-mode-edit-wikitext-disallow", nil);
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_ARROW_LEFT(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL]|";
            break;
        case NAVBAR_MODE_EDIT_WIKITEXT_PREVIEW:
        case NAVBAR_MODE_EDIT_WIKITEXT_SUMMARY:
            self.label.text = (NAVBAR_MODE_EDIT_WIKITEXT_PREVIEW == navBarMode) ?
                MWLocalizedString(@"navbar-title-mode-edit-wikitext-preview", nil)
                :
                MWLocalizedString(@"navbar-title-mode-edit-wikitext-summary", nil)
            ;
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_ARROW_LEFT(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL][NAVBAR_BUTTON_CC(50)][NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_CHECK(50)]|";
            break;
        case NAVBAR_MODE_EDIT_WIKITEXT_CAPTCHA:
            self.label.text = MWLocalizedString(@"navbar-title-mode-edit-wikitext-captcha", nil);
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_ARROW_LEFT(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL][NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_ARROW_RIGHT(50)]|";
            break;
        default: //NAVBAR_MODE_SEARCH
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_LOGO_W(65)][NAVBAR_VERTICAL_LINE_1(singlePixel)][NAVBAR_TEXT_FIELD]-(10)-|";
            break;
    }
    [self.view setNeedsUpdateConstraints];
}

#pragma mark Broadcast nav button taps

-(void)postNavItemTappedNotification:(id)sender
{
    UIView *tappedView = nil;
    if([sender isKindOfClass:[UIGestureRecognizer class]]){
        tappedView = ((UIGestureRecognizer *)sender).view;
    }else{
        tappedView = sender;
    }
    
    void(^postTapNotification)() = ^(){
        if(self.isTransitioningBetweenViewControllers) return;

        [[NSNotificationCenter defaultCenter] postNotificationName: @"NavItemTapped"
                                                            object: self
                                                          userInfo: @{@"tappedItem": tappedView}];
    };
    
    // If the tapped item was a button, first animate it briefly, then post the notication.
    if([tappedView isKindOfClass:[UIButton class]]){
        CGFloat animationScale = 1.15f;
        [tappedView animateAndRewindXF: CATransform3DMakeScale(animationScale, animationScale, 1.0f)
                            afterDelay: 0.0
                              duration: 0.06f
                                  then: postTapNotification];
    }else{
        // If tapped item not a button, don't animate, just post.
        postTapNotification();
    }
}

#pragma mark Handle nav button taps

// Handle nav bar taps. (same way as any other view controller would)
- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_LOGO_W:
            [self mainMenuToggle];
            break;
        default:
            break;
    }
}

#pragma mark Rotation

/*
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.navBarStyle = (UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? NAVBAR_STYLE_DAY : NAVBAR_STYLE_NIGHT);
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}
*/

#pragma mark Toggles

-(void)showSearchResultsController
{
    SearchResultsController *searchResultsVC = [self searchNavStackForViewControllerOfClass:[SearchResultsController class]];

    if(searchResultsVC){
        if (self.topViewController == searchResultsVC) {
            [searchResultsVC refreshSearchResults];
        }else{
            [self popToViewController:searchResultsVC animated:NO];
        }
    }else{
        SearchResultsController *searchResultsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"SearchResultsController"];
        [self pushViewController:searchResultsVC animated:NO];
    }
}

-(void)mainMenuToggle
{
    UIViewController *topVC = self.topViewController;

    [topVC hideKeyboard];
    
    MainMenuViewController *mainMenuTableVC = [self searchNavStackForViewControllerOfClass:[MainMenuViewController class]];
    
    if(mainMenuTableVC){
        [self popToRootViewControllerAnimated:YES];
    }else{
        MainMenuViewController *mainMenuTableVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MainMenuViewController"];
        [self pushViewController:mainMenuTableVC animated:YES];
    }
}

#pragma mark Text field

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SearchFieldBecameFirstResponder" object:self userInfo:nil];
    
    if (self.textField.text.length == 0){
        self.textField.rightView.hidden = YES;
    }else{
        [self showSearchResultsController];
    }
}

-(void)clearTextFieldText
{
    self.textField.text = @"";
    self.textField.rightView.hidden = YES;

    SearchResultsController *searchResultsVC = [self searchNavStackForViewControllerOfClass:[SearchResultsController class]];
    [searchResultsVC clearSearchResults];
    
    if (self.topViewController == searchResultsVC) {
        [self popViewControllerAnimated:NO];
    }
}

- (void)searchStringChanged
{
    NSString *searchString = self.textField.text;

    NSString *trimmedSearchString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.currentSearchString = trimmedSearchString;

    [self showSearchResultsController];

    if (trimmedSearchString.length == 0){
        self.textField.rightView.hidden = YES;
        
        return;
    }
    self.textField.rightView.hidden = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.topViewController hideKeyboard];
    return YES;
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    // In "setIsTransitioningBetweenViewControllers" self.view.userInteractionEnabled is conditionally
    // disabled as a fairly robust "debounce" strategy. But this is problematic on iOS 6 which hides
    // any keyboards which had been visible when a first responder view's superview has its
    // userInteractionEnabled set to NO. So here the seach box keyboard is set to *not* hide if it has
    // been told to hide while transistioning between view controllers. Without this, the first time a
    // search term is entered on iOS 6 they keyboard will immediately hide. That's bad.
    return (self.isTransitioningBetweenViewControllers) ? NO : YES;
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(object == self.navigationBar){
        if ([keyPath isEqualToString:@"bounds"]) {
            [self.view setNeedsUpdateConstraints];
        }
    }
}

#pragma mark Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

    //self.navBarStyle = (self.navBarStyle == NAVBAR_STYLE_DAY) ? NAVBAR_STYLE_NIGHT : NAVBAR_STYLE_DAY;
}

#pragma mark NavBarStyle night/day mode management

-(void)setNavBarStyle:(NavBarStyle)navBarStyle
{
    if (_navBarStyle != navBarStyle) {
        _navBarStyle = navBarStyle;

        // Make the nav bar itself be light or dark.
        NSDictionary *colors = [self getNavBarColorsForNavBarStyle:navBarStyle];
        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
            self.navigationBar.backgroundColor = colors[@"NAVBAR_COLOR_PRE_IOS_7"];
        }else{
            [self.navigationBar setBarTintColor:colors[@"NAVBAR_COLOR"]];
        }
        
        // Make the status bar above the nav bar use light or dark text.
        if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
            [self setNeedsStatusBarAppearanceUpdate];
        }

        // Update the nav bar containers subviews to use light or dark appearance.
        for (id view in self.navBarContainer.subviews) {
            [self updateViewAppearance:view forNavBarStyle:self.navBarStyle];
        }
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return (self.navBarStyle == NAVBAR_STYLE_DAY) ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
}

-(NSDictionary *)getNavBarColorsForNavBarStyle:(NavBarStyle)navBarStyle
{
    NSDictionary *output = nil;
    switch (navBarStyle) {
        case NAVBAR_STYLE_DAY:{
            output = @{
                       @"NAVBAR_COLOR": [UIColor colorWithWhite:1.0 alpha:0.9],
                       @"NAVBAR_COLOR_PRE_IOS_7": [UIColor colorWithWhite:1.0 alpha:0.983],
                       @"NAVBAR_TEXT_FIELD_TEXT_COLOR": [UIColor colorWithWhite:0.33 alpha:1.0],
                       @"NAVBAR_TEXT_FIELD_PLACEHOLDER_TEXT_COLOR": [UIColor colorWithWhite:0.33 alpha:1.0],
                       @"NAVBAR_TEXT_CLEAR_BUTTON_COLOR": [UIColor colorWithWhite:0.33 alpha:1.0],
                       @"NAVBAR_BUTTON_COLOR": [UIColor blackColor],
                       @"NAVBAR_LABEL_TEXT_COLOR": [UIColor blackColor],
                       @"NAVBAR_VERTICAL_LINE_COLOR": [UIColor lightGrayColor]
                       };
        }
            break;
        case NAVBAR_STYLE_NIGHT:{
            output = @{
                       @"NAVBAR_COLOR": [UIColor colorWithWhite:0.0 alpha:0.9],
                       @"NAVBAR_COLOR_PRE_IOS_7": [UIColor colorWithWhite:0.0 alpha:0.925],
                       @"NAVBAR_TEXT_FIELD_TEXT_COLOR": [UIColor whiteColor],
                       @"NAVBAR_TEXT_FIELD_PLACEHOLDER_TEXT_COLOR": [UIColor whiteColor],
                       @"NAVBAR_TEXT_CLEAR_BUTTON_COLOR": [UIColor whiteColor],
                       @"NAVBAR_BUTTON_COLOR": [UIColor whiteColor],
                       @"NAVBAR_LABEL_TEXT_COLOR": [UIColor whiteColor],
                       @"NAVBAR_VERTICAL_LINE_COLOR": [UIColor whiteColor]
                       };
        }
            break;
            
        default:
            break;
    }
    return output;
}

-(void)updateViewAppearance:(UIView *)view forNavBarStyle:(NavBarStyle)navBarStyle
{
    NSDictionary *colors = [self getNavBarColorsForNavBarStyle:navBarStyle];

    switch (view.tag) {
        case NAVBAR_BUTTON_X:
        case NAVBAR_BUTTON_PENCIL:
        case NAVBAR_BUTTON_CHECK:
        case NAVBAR_BUTTON_ARROW_LEFT:
        case NAVBAR_BUTTON_ARROW_RIGHT:
        case NAVBAR_BUTTON_LOGO_W:
        case NAVBAR_BUTTON_EYE:{
            UIButton *button = (UIButton *)view;
            [button maskButtonImageWithColor:colors[@"NAVBAR_BUTTON_COLOR"]];
        }
            break;
        case NAVBAR_TEXT_FIELD:{
            NavBarTextField *textField = (NavBarTextField *)view;
            
            // Typed text and cursor.
            textField.textColor = colors[@"NAVBAR_TEXT_FIELD_TEXT_COLOR"];
            if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
                textField.tintColor = colors[@"NAVBAR_TEXT_FIELD_TEXT_COLOR"];
            }
            
            // Placeholder text.
            textField.placeholderColor = colors[@"NAVBAR_TEXT_FIELD_PLACEHOLDER_TEXT_COLOR"];

            // Text clear button.
            UIButton *button = (UIButton *)textField.rightView;
            [button maskButtonImageWithColor:colors[@"NAVBAR_TEXT_CLEAR_BUTTON_COLOR"]];
        }
            break;
        case NAVBAR_LABEL:{
            UILabel *label = (UILabel *)view;
            label.textColor = colors[@"NAVBAR_LABEL_TEXT_COLOR"];
        }
            break;
        case NAVBAR_VERTICAL_LINE:
            view.backgroundColor = colors[@"NAVBAR_VERTICAL_LINE_COLOR"];
            break;
        default:
            break;
    }
    [view setNeedsDisplay];
}

#pragma mark Article

-(void)loadArticleWithTitle: (NSString *)title
                     domain: (NSString *)domain
                   animated: (BOOL)animated
            discoveryMethod: (ArticleDiscoveryMethod)discoveryMethod
{
    WebViewController *webVC = [self searchNavStackForViewControllerOfClass:[WebViewController class]];
    if (webVC){
        [SessionSingleton sharedInstance].currentArticleTitle = title;
        [SessionSingleton sharedInstance].currentArticleDomain = domain;
        [webVC navigateToPage: title
                       domain: domain
              discoveryMethod: discoveryMethod];
        [self popToViewController:webVC animated:animated];
    }
}

#pragma mark Is editing

-(BOOL)isEditorOnNavstack
{
    id editVC = [self searchNavStackForViewControllerOfClass:[SectionEditorViewController class]];
    return editVC ? YES : NO;
}

@end
