//  Created by Monte Hurd on 12/16/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TopMenuTextField.h"
#import "WikipediaAppUtils.h"
#import "TopMenuViewController.h"
#import "Defines.h"
#import "UIView+Debugging.h"
#import "UIView+RemoveConstraints.h"
#import "UIViewController+HideKeyboard.h"
#import "SearchResultsController.h"
#import "UINavigationController+SearchNavStack.h"
//#import "UIButton+ColorMask.h"
#import "UINavigationController+Alert.h"
#import "PreviewAndSaveViewController.h"

#import "SessionSingleton.h"
#import "WebViewController.h"
#import "UIView+TemporaryAnimatedXF.h"
//#import "SectionEditorViewController.h"

#import "MenuButtonView.h"
#import "MenuLabel.h"
#import "PaddedLabel.h"

#import "WMF_WikiFont_Chars.h"

#import "CenterNavController.h"

#import "RootViewController.h"
#import "TopMenuViewController.h"

#import "RootViewController.h"
#import "TopMenuContainerView.h"

@interface TopMenuViewController (){

}

// Views which go into the container.
@property (strong, nonatomic) TopMenuTextField *textField;
@property (strong, nonatomic) UIView *verticalLine1;
@property (strong, nonatomic) UIView *verticalLine2;
@property (strong, nonatomic) UIView *verticalLine3;
@property (strong, nonatomic) UIView *verticalLine4;
@property (strong, nonatomic) UIView *verticalLine5;
@property (strong, nonatomic) UIView *verticalLine6;
@property (strong, nonatomic) MenuButtonView *buttonW;
@property (strong, nonatomic) MenuButtonView *buttonTOC;
@property (strong, nonatomic) MenuButtonView *buttonPencil;
@property (strong, nonatomic) MenuButtonView *buttonCheck;
@property (strong, nonatomic) MenuButtonView *buttonX;
@property (strong, nonatomic) MenuButtonView *buttonEye;
@property (strong, nonatomic) MenuButtonView *buttonArrowLeft;
@property (strong, nonatomic) MenuButtonView *buttonArrowRight;
@property (strong, nonatomic) MenuButtonView *buttonMagnify;
@property (strong, nonatomic) MenuButtonView *buttonBlank;
@property (strong, nonatomic) MenuButtonView *buttonCancel;
@property (strong, nonatomic) UILabel *label;

// Used for constraining container sub-views.
@property (strong, nonatomic) NSString *navBarSubViewsHorizontalVFLString;
@property (strong, nonatomic) NSDictionary *navBarSubViews;
@property (strong, nonatomic) NSDictionary *navBarSubViewMetrics;

@property (strong, nonatomic) NSString *lastSearchString;

@end

@implementation TopMenuViewController

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.currentSearchResultsOrdered = [@[] mutableCopy];
    self.currentSearchString = @"";

    [self setupNavbarContainerSubviews];

    self.navBarStyle = NAVBAR_STYLE_DAY;

    self.navBarMode = NAVBAR_MODE_DEFAULT;
    
    self.navBarSubViews = [self getNavBarSubViews];
    
    self.navBarSubViewMetrics = [self getNavBarSubViewMetrics];
    
    self.lastSearchString = @"";
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    
    CGFloat verticalLineTopMargin = 20;
    CGFloat topMargin = 20;
    CGFloat bottomMargin = 0;
    
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        verticalLineTopMargin = 0;
        topMargin = 0;
    }
    
    // Now take the views which were constrained horizontally (above) and constrain them
    // vertically as well. Also set hidden = NO for just these views.
    for (NSLayoutConstraint *c in [self.navBarContainer.constraints copy]) {
        UIView *view = (c.firstItem != self.navBarContainer) ? c.firstItem: c.secondItem;
        view.hidden = NO;
        
        CGFloat thisTopMargin = topMargin;//(view.tag == NAVBAR_VERTICAL_LINE) ? verticalLineTopMargin : topMargin;
        CGFloat thisBottomMargin = bottomMargin;//(view.tag == NAVBAR_TEXT_FIELD) ? verticalLineTopMargin : topMargin;

        switch (view.tag) {
            case NAVBAR_VERTICAL_LINE:
                thisTopMargin = verticalLineTopMargin;
                break;
            case NAVBAR_TEXT_FIELD:
                thisTopMargin = topMargin + 8;
                thisBottomMargin = 7;
                break;
            default:
                break;
        }
        
        [self.navBarContainer addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-(topMargin)-[view]-(bottomMargin)-|"
                                                 options: 0
                                                 metrics: @{
                                                    @"topMargin": @(thisTopMargin),
                                                    @"bottomMargin": @(thisBottomMargin)
                                                    }
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
//    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
//        self.navigationBar.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:0.97];
//    }

    self.textField = [[TopMenuTextField alloc] init];
    self.textField.delegate = self;
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.font = SEARCH_TEXT_FIELD_FONT;
    self.textField.textColor = SEARCH_TEXT_FIELD_HIGHLIGHTED_COLOR;
    self.textField.tag = NAVBAR_TEXT_FIELD;
    self.textField.clearButtonMode = UITextFieldViewModeNever;
    self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [self.textField addTarget:self action:@selector(postNavItemTappedNotification:) forControlEvents:UIControlEventTouchUpInside];
    self.textField.placeholder = MWLocalizedString(@"search-field-placeholder-text", nil);

    // Perform search when text entered into textField
    [self.textField addTarget:self action:@selector(searchStringChanged) forControlEvents:UIControlEventEditingChanged];
    
    [self.navBarContainer addSubview:self.textField];
 
    UIButton *clearButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25, 25)];
    clearButton.backgroundColor = [UIColor clearColor];
    [clearButton setImage:[UIImage imageNamed:@"text_field_x_circle_gray.png"] forState:UIControlStateNormal];
    [clearButton addTarget:self action:@selector(clearTextFieldText) forControlEvents:UIControlEventTouchUpInside];
    
    self.textField.rightView = clearButton;
    self.textField.rightViewMode = UITextFieldViewModeNever;

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

    MenuButtonView *(^getButton)(NSString *, NavBarItemTag) = ^MenuButtonView *(NSString *character, NavBarItemTag tag) {
        MenuButtonView *button = [[MenuButtonView alloc] init];
        [button.label setWikiText:character color:[UIColor blackColor] size:34];
        button.translatesAutoresizingMaskIntoConstraints = NO;

    [button addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(postNavItemTappedNotification:)]];

        button.tag = tag;
        return button;
    };

    self.buttonPencil =     getButton(WIKIFONT_CHAR_PENCIL,             NAVBAR_BUTTON_PENCIL);
    self.buttonCheck =      getButton(WIKIFONT_CHAR_TICK,               NAVBAR_BUTTON_CHECK);
    self.buttonX =          getButton(WIKIFONT_CHAR_X,                  NAVBAR_BUTTON_X);
    self.buttonEye =        getButton(WIKIFONT_CHAR_EYE,                NAVBAR_BUTTON_EYE);
    self.buttonArrowLeft =  getButton(WIKIFONT_CHAR_ARROW_LEFT,         NAVBAR_BUTTON_ARROW_LEFT);
    self.buttonArrowRight = getButton(WIKIFONT_CHAR_ARROW_LEFT,         NAVBAR_BUTTON_ARROW_RIGHT);
    self.buttonW =          getButton(WIKIFONT_CHAR_IOS_W,              NAVBAR_BUTTON_LOGO_W);
    self.buttonTOC =        getButton(WIKIFONT_CHAR_IOS_TOC,            NAVBAR_BUTTON_TOC);
    self.buttonMagnify =    getButton(WIKIFONT_CHAR_IOS_MAGNIFY,        NAVBAR_BUTTON_MAGNIFY);
    self.buttonBlank =      getButton(@"",                              NAVBAR_BUTTON_BLANK);
    self.buttonCancel =     getButton(@"",                              NAVBAR_BUTTON_CANCEL);

    self.buttonCancel.label.font = [UIFont systemFontOfSize:17.0];
    self.buttonCancel.label.text = MWLocalizedString(@"search-cancel", nil);

    // Ensure the cancel button content is hugged more tightly than the search text box.
    // Otherwise on iOS 6 the cancel button is super wide.
    [self.buttonCancel.label setContentHuggingPriority: 1000
                                               forAxis: UILayoutConstraintAxisHorizontal];

    self.buttonCancel.label.padding = UIEdgeInsetsMake(0, 5, 0, 5);
    
    self.textField.backgroundColor = [UIColor whiteColor];

    // Mirror the left arrow.
    self.buttonArrowRight.transform = CGAffineTransformMakeScale(-1.0, 1.0);

    [self.navBarContainer addSubview:self.buttonPencil];
    [self.navBarContainer addSubview:self.buttonCheck];
    [self.navBarContainer addSubview:self.buttonX];
    [self.navBarContainer addSubview:self.buttonEye];
    [self.navBarContainer addSubview:self.buttonArrowLeft];
    [self.navBarContainer addSubview:self.buttonArrowRight];
    [self.navBarContainer addSubview:self.buttonW];
    [self.navBarContainer addSubview:self.buttonTOC];
    [self.navBarContainer addSubview:self.buttonMagnify];
    [self.navBarContainer addSubview:self.buttonBlank];
    [self.navBarContainer addSubview:self.buttonCancel];

    self.label = [[UILabel alloc] init];
    self.label.text = @"";
    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    self.label.tag = NAVBAR_LABEL;
    self.label.font = [UIFont systemFontOfSize:21.0];
    self.label.textAlignment = NSTextAlignmentCenter;
    
    self.label.adjustsFontSizeToFitWidth = YES;
    self.label.minimumScaleFactor = 0.5f;
    self.label.textColor = [UIColor darkGrayColor];
    self.label.backgroundColor = [UIColor clearColor];
    self.label.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapLabel = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(postNavItemTappedNotification:)];
    [self.label addGestureRecognizer:tapLabel];
    [self.navBarContainer addSubview:self.label];
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
             @"NAVBAR_BUTTON_TOC": self.buttonTOC,
             @"NAVBAR_BUTTON_MAGNIFY": self.buttonMagnify,
             @"NAVBAR_BUTTON_BLANK": self.buttonBlank,
             @"NAVBAR_BUTTON_CANCEL": self.buttonCancel,
             @"NAVBAR_BUTTON_EYE": self.buttonEye,
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

-(void)setNavBarMode:(NavBarMode)navBarMode
{
    if(_navBarMode == navBarMode) return;

    if (_navBarMode == NAVBAR_MODE_SEARCH) {
        // Hide keyboard if mode had been search.
        [NAV.topViewController hideKeyboard];
    }

    if (navBarMode == NAVBAR_MODE_SEARCH) {
        // Show keyboard if new mode is search.
        TopMenuTextField *textField = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
        [textField becomeFirstResponder];
    }

    _navBarMode = navBarMode;

    PreviewAndSaveViewController *previewAndSaveVC = [NAV searchNavStackForViewControllerOfClass:[PreviewAndSaveViewController class]];

    switch (navBarMode) {
        case NAVBAR_MODE_EDIT_WIKITEXT:
            self.label.text = MWLocalizedString(@"navbar-title-mode-edit-wikitext", nil);
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_X(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL]-(10)-[NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_ARROW_RIGHT(50)]|";
            break;
        case NAVBAR_MODE_LOGIN:
            self.label.text = (!previewAndSaveVC) ?
                MWLocalizedString(@"navbar-title-mode-login", nil)
                :
                MWLocalizedString(@"navbar-title-mode-login-and-save", nil)
            ;
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_X(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL]-(10)-[NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_CHECK(50)]|";
            break;
        case NAVBAR_MODE_EDIT_WIKITEXT_LOGIN_OR_SAVE_ANONYMOUSLY:
            self.label.text = @"";
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_PENCIL(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL]|";
            break;
        case NAVBAR_MODE_EDIT_WIKITEXT_SAVE:
            self.label.text = MWLocalizedString(@"navbar-title-mode-edit-wikitext-save", nil);
            self.navBarSubViewsHorizontalVFLString =
            @"H:|[NAVBAR_BUTTON_PENCIL(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL]-(10)-[NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_CHECK(50)]|";
            break;
        case NAVBAR_MODE_CREATE_ACCOUNT:
            self.label.text = (!previewAndSaveVC) ?
                MWLocalizedString(@"navbar-title-mode-create-account", nil)
                :
                MWLocalizedString(@"navbar-title-mode-create-account-and-save", nil)
            ;
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_ARROW_LEFT(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL]-(10)-[NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_CHECK(50)]|";
            break;
        case NAVBAR_MODE_EDIT_WIKITEXT_WARNING:
            self.label.text = MWLocalizedString(@"navbar-title-mode-edit-wikitext-warning", nil);
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_PENCIL(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL]-(10)-[NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_CHECK(50)]|";
            break;
        case NAVBAR_MODE_EDIT_WIKITEXT_DISALLOW:
            self.label.text = MWLocalizedString(@"navbar-title-mode-edit-wikitext-disallow", nil);
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_PENCIL(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL]-(60)-|";
            break;
        case NAVBAR_MODE_EDIT_WIKITEXT_PREVIEW:
        case NAVBAR_MODE_EDIT_WIKITEXT_SUMMARY:
            self.label.text = (NAVBAR_MODE_EDIT_WIKITEXT_PREVIEW == navBarMode) ?
                MWLocalizedString(@"navbar-title-mode-edit-wikitext-preview", nil)
                :
                MWLocalizedString(@"navbar-title-mode-edit-wikitext-summary", nil)
            ;
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_PENCIL(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL]-(10)-[NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_ARROW_RIGHT(50)]|";
            break;
        case NAVBAR_MODE_EDIT_WIKITEXT_CAPTCHA:
            self.label.text = MWLocalizedString(@"navbar-title-mode-edit-wikitext-captcha", nil);
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_PENCIL(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL]-(10)-[NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_ARROW_RIGHT(50)]|";
            break;
        case NAVBAR_MODE_SEARCH:
            self.navBarSubViewsHorizontalVFLString =
            @"H:|-(5)-[NAVBAR_TEXT_FIELD]-(6)-[NAVBAR_BUTTON_CANCEL]-(5)-|";
            break;
        case NAVBAR_MODE_X_WITH_LABEL:
            self.navBarSubViewsHorizontalVFLString =
            @"H:|-(5)-[NAVBAR_BUTTON_X(50)][NAVBAR_LABEL]-(55)-|";
            break;
        case NAVBAR_MODE_X_WITH_TEXT_FIELD:
            self.navBarSubViewsHorizontalVFLString =
            @"H:|-(5)-[NAVBAR_BUTTON_X(50)][NAVBAR_TEXT_FIELD]-(15)-|";
            break;
        case NAVBAR_MODE_DEFAULT_WITH_TOC:
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_LOGO_W(65)][NAVBAR_BUTTON_MAGNIFY(35)][NAVBAR_BUTTON_BLANK]-(10)-[NAVBAR_BUTTON_TOC(50)]-(3)-|";
            break;
        default: //NAVBAR_MODE_DEFAULT
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_LOGO_W(65)][NAVBAR_BUTTON_MAGNIFY(35)][NAVBAR_BUTTON_BLANK]-(10)-|";
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

        if(NAV.isTransitioningBetweenViewControllers) return;

        [[NSNotificationCenter defaultCenter] postNotificationName: @"NavItemTapped"
                                                            object: self
                                                          userInfo: @{@"tappedItem": tappedView}];
    };
    
    // If the tapped item was a button, first animate it briefly, then post the notication.
    if([tappedView isKindOfClass:[MenuButtonView class]]){
        CGFloat animationScale = 1.25f;
        MenuButtonView *button = (MenuButtonView *)tappedView;
        [button.label animateAndRewindXF: CATransform3DMakeScale(animationScale, animationScale, 1.0f)
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
        case NAVBAR_BUTTON_LOGO_W: {
            UIViewController *topVC = NAV.topViewController;
            [topVC hideKeyboard];
            [ROOT togglePrimaryMenu];
        }
            break;
        case NAVBAR_BUTTON_TOC:{
            WebViewController *webVC = [NAV searchNavStackForViewControllerOfClass:[WebViewController class]];
            [webVC tocToggle];
        }
            break;
        case NAVBAR_BUTTON_MAGNIFY:
        case NAVBAR_BUTTON_BLANK: {
            switch (self.navBarMode) {
                case NAVBAR_MODE_DEFAULT:
                case NAVBAR_MODE_DEFAULT_WITH_TOC:
                    self.navBarMode = NAVBAR_MODE_SEARCH;
                    break;
                default:
                    break;
            }
        }
            break;
        case NAVBAR_BUTTON_CANCEL:
            self.navBarMode = NAVBAR_MODE_DEFAULT;
            [self updateTOCButtonVisibility];
            [self clearSearchResults];
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
    SearchResultsController *searchResultsVC = [NAV searchNavStackForViewControllerOfClass:[SearchResultsController class]];

    if(searchResultsVC){
        if (NAV.topViewController == searchResultsVC) {
            [searchResultsVC refreshSearchResults];
        }else{
            [NAV popToViewController:searchResultsVC animated:NO];
        }
    }else{
        SearchResultsController *searchResultsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"SearchResultsController"];
        [NAV pushViewController:searchResultsVC animated:NO];
    }
}

#pragma mark Text field

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.textField.rightViewMode = UITextFieldViewModeAlways;

    if (self.textField.text.length == 0){
        // Remeber user's last search term. Must come before the
        // @"SearchFieldBecameFirstResponder" notification is posted.
        if (self.lastSearchString.length != 0) self.textField.text = self.lastSearchString;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SearchFieldBecameFirstResponder" object:self userInfo:nil];
    
    if (self.textField.text.length == 0){
        self.textField.rightViewMode = UITextFieldViewModeNever;
    }else{
        [self showSearchResultsController];
    }
}

-(void)clearTextFieldText
{
    self.textField.text = @"";
    self.textField.rightViewMode = UITextFieldViewModeNever;
    self.lastSearchString = @"";

    if (self.navBarMode == NAVBAR_MODE_SEARCH) {
        //[self clearSearchResults];
    }else{
        // So NavTextFieldTextChanged notification will fire when text cleared.
        [self searchStringChanged];
    }
}

-(void)clearSearchResults
{
    SearchResultsController *searchResultsVC = [NAV searchNavStackForViewControllerOfClass:[SearchResultsController class]];
    [searchResultsVC clearSearchResults];
    
    if (NAV.topViewController == searchResultsVC) {
        [NAV popViewControllerAnimated:NO];
    }
}

- (void)searchStringChanged
{
    NSString *searchString = self.textField.text;

    NSString *trimmedSearchString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (self.navBarMode == NAVBAR_MODE_SEARCH) {
        
        self.currentSearchString = trimmedSearchString;
        
        self.lastSearchString = trimmedSearchString;
        
        [self showSearchResultsController];
        
    }else{
    
        [[NSNotificationCenter defaultCenter] postNotificationName: @"NavTextFieldTextChanged"
                                                            object: self
                                                          userInfo: @{@"text": searchString}];
    }
    
    if (trimmedSearchString.length == 0){
        self.textField.rightViewMode = UITextFieldViewModeNever;
        return;
    }
    self.textField.rightViewMode = UITextFieldViewModeAlways;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self hideKeyboard];
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

    self.textField.rightViewMode = UITextFieldViewModeNever;
    
    return (NAV.isTransitioningBetweenViewControllers) ? NO : YES;
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
    if (_navBarStyle == navBarStyle) return;
    
    _navBarStyle = navBarStyle;
    
    // Make the nav bar itself be light or dark.
    NSDictionary *colors = [self getNavBarColorsForNavBarStyle:navBarStyle];
    
    self.view.backgroundColor = colors[@"NAVBAR_COLOR"];
    
    // Make the status bar above the nav bar use light or dark text.
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
    
    // Update the nav bar containers subviews to use light or dark appearance.
    for (id view in self.navBarContainer.subviews) {
        // Ignore layout guides.
        if (![view conformsToProtocol:@protocol(UILayoutSupport)]) {
            [self updateViewAppearance:view forNavBarStyle:self.navBarStyle];
        }
    }
}

-(NSDictionary *)getNavBarColorsForNavBarStyle:(NavBarStyle)navBarStyle
{
    NSDictionary *output = nil;
    switch (navBarStyle) {
        case NAVBAR_STYLE_DAY:{
            output = @{
                       @"NAVBAR_COLOR": [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0],
                       @"NAVBAR_TEXT_FIELD_TEXT_COLOR": [UIColor colorWithWhite:0.33 alpha:1.0],
                       @"NAVBAR_TEXT_FIELD_PLACEHOLDER_TEXT_COLOR": [UIColor lightGrayColor],
                       @"NAVBAR_TEXT_CLEAR_BUTTON_COLOR": [UIColor colorWithWhite:0.33 alpha:1.0],
                       @"NAVBAR_BUTTON_COLOR": [UIColor blackColor],
                       @"NAVBAR_LABEL_TEXT_COLOR": [UIColor blackColor],
                       @"NAVBAR_VERTICAL_LINE_COLOR": [UIColor colorWithWhite:0.88 alpha:1.0],
                       };
        }
            break;
        case NAVBAR_STYLE_NIGHT:{
            output = @{
                       @"NAVBAR_COLOR": [UIColor colorWithWhite:0.0 alpha:1.0],
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
        case NAVBAR_BUTTON_EYE:
        case NAVBAR_BUTTON_TOC:
        case NAVBAR_BUTTON_MAGNIFY:
        case NAVBAR_BUTTON_BLANK:
        case NAVBAR_BUTTON_CANCEL:
        {
            MenuButtonView *button = (MenuButtonView *)view;
            button.label.textColor = colors[@"NAVBAR_BUTTON_COLOR"];
        }
            break;
        case NAVBAR_TEXT_FIELD:{
            TopMenuTextField *textField = (TopMenuTextField *)view;
            
            // Typed text and cursor.
            textField.textColor = colors[@"NAVBAR_TEXT_FIELD_TEXT_COLOR"];
            if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
                textField.tintColor = colors[@"NAVBAR_TEXT_FIELD_TEXT_COLOR"];
            }
            
            // Text clear button.
            //UIButton *button = (UIButton *)textField.rightView;
            //[button maskButtonImageWithColor:colors[@"NAVBAR_TEXT_CLEAR_BUTTON_COLOR"]];
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

#pragma mark TOC button

-(void)updateTOCButtonVisibility
{
    // Only flip between NAVBAR_MODE_DEFAULT and NAVBAR_MODE_DEFAULT_WITH_TOC if one
    // of them is presently in use.
    switch (self.navBarMode) {
        case NAVBAR_MODE_DEFAULT:
        case NAVBAR_MODE_DEFAULT_WITH_TOC:
            break;
        default:
            return;
            break;
    }

    if (
        ![NAV.topViewController isMemberOfClass:[WebViewController class]]
        ||
        [[SessionSingleton sharedInstance] isCurrentArticleMain]
    ) {
        // Hide TOC button if web view isn't on top or if current article is the main page.
        self.navBarMode = NAVBAR_MODE_DEFAULT;
    }else{
        TopMenuTextField *searchTextField = [self getNavBarItem:NAVBAR_TEXT_FIELD];
        NSString *currentArticleTitle = [SessionSingleton sharedInstance].currentArticleTitle;
        self.navBarMode = (!searchTextField.isFirstResponder && currentArticleTitle && (currentArticleTitle.length > 0))
                ?
                NAVBAR_MODE_DEFAULT_WITH_TOC
                :
                NAVBAR_MODE_DEFAULT
                ;
    }
}

@end
