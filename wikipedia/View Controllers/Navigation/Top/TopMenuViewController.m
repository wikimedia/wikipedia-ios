//  Created by Monte Hurd on 12/16/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TopMenuTextField.h"
#import "TopMenuTextFieldContainer.h"
#import "WikipediaAppUtils.h"
#import "TopMenuViewController.h"
#import "Defines.h"
#import "UIView+Debugging.h"
#import "UIView+RemoveConstraints.h"
#import "UIViewController+HideKeyboard.h"
#import "SearchResultsController.h"
#import "UINavigationController+SearchNavStack.h"
#import "PreviewAndSaveViewController.h"
#import "SessionSingleton.h"
#import "WebViewController.h"
#import "UIView+TemporaryAnimatedXF.h"
#import "WikiGlyphButton.h"
#import "WikiGlyphLabel.h"
#import "PaddedLabel.h"
#import "WikiGlyph_Chars.h"
#import "WikiGlyph_Chars_iOS.h"
#import "CenterNavController.h"
#import "RootViewController.h"
#import "TopMenuViewController.h"
#import "RootViewController.h"
#import "TopMenuContainerView.h"
#import "UIViewController+StatusBarHeight.h"
#import "MenuButton.h"
#import "LoginViewController.h"
#import "AccountCreationViewController.h"
#import "WMF_Colors.h"
#import "UIView+ConstraintsScale.h"

@interface TopMenuViewController (){

}

// Views which go into the container.
@property (strong, nonatomic) TopMenuTextFieldContainer *textFieldContainer;
@property (strong, nonatomic) WikiGlyphButton *buttonW;
@property (strong, nonatomic) WikiGlyphButton *buttonTOC;
@property (strong, nonatomic) WikiGlyphButton *buttonPencil;
@property (strong, nonatomic) WikiGlyphButton *buttonX;
@property (strong, nonatomic) WikiGlyphButton *buttonEye;
@property (strong, nonatomic) WikiGlyphButton *buttonArrowLeft;
@property (strong, nonatomic) WikiGlyphButton *buttonArrowRight;
@property (strong, nonatomic) WikiGlyphButton *buttonMagnify;
@property (strong, nonatomic) WikiGlyphButton *buttonBlank;
@property (strong, nonatomic) WikiGlyphButton *buttonCancel;
@property (strong, nonatomic) WikiGlyphButton *buttonTrash;
@property (strong, nonatomic) MenuButton *buttonNext;
@property (strong, nonatomic) MenuButton *buttonSave;
@property (strong, nonatomic) MenuButton *buttonDone;
@property (strong, nonatomic) MenuButton *buttonCheck;
@property (strong, nonatomic) UILabel *label;
// Used for constraining container sub-views.
@property (strong, nonatomic) NSString *navBarSubViewsHorizontalVFLString;
@property (strong, nonatomic) NSDictionary *navBarSubViews;
@property (strong, nonatomic) NSDictionary *navBarSubViewMetrics;

@end

@implementation TopMenuViewController

-(void)setStatusBarHidden:(BOOL)statusBarHidden
{
    _statusBarHidden = statusBarHidden;
    [self.view setNeedsUpdateConstraints];
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.searchResultsController = [self.storyboard instantiateViewControllerWithIdentifier:@"SearchResultsController"];

    [self setupNavbarContainerSubviews];

    self.navBarStyle = NAVBAR_STYLE_DAY;
    
    self.navBarSubViews = [self getNavBarSubViews];
    
    self.navBarSubViewMetrics = [self getNavBarSubViewMetrics];

    // This needs to happend *after* navBarSubViews are set up.
    self.navBarMode = NAVBAR_MODE_DEFAULT;
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
                                             options: NSLayoutFormatAlignAllCenterY
                                             metrics: self.navBarSubViewMetrics
                                               views: self.navBarSubViews
      ]
     ];
    
    CGFloat topMargin = [self getStatusBarHeight];
    
    if ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) || self.statusBarHidden) {
        topMargin = 0;
    }
    
    // Now take the views which were constrained horizontally (above) and constrain them
    // vertically as well. Also set hidden = NO for just these views.
    for (NSLayoutConstraint *c in [self.navBarContainer.constraints copy]) {
        UIView *view = (c.firstItem != self.navBarContainer) ? c.firstItem: c.secondItem;
        view.hidden = NO;

        [self.navBarContainer addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-(topMargin)-[view(CHROME_MENUS_HEIGHT)]"
                                                 options: 0
                                                 metrics: @{
                                                    @"topMargin": @(topMargin),
                                                    @"CHROME_MENUS_HEIGHT": @(CHROME_MENUS_HEIGHT)
                                                    }
                                                   views: NSDictionaryOfVariableBindings(view)
          ]
         ];
    }

    // Adjust constraints relative to screen size.
    for (id v in [self.navBarContainer.subviews copy]) {
        if ([v isMemberOfClass:[WikiGlyphButton class]] || [v isMemberOfClass:[MenuButton class]]){
            [v adjustConstraintsFor:NSLayoutAttributeLeading byMultiplier:MENUS_SCALE_MULTIPLIER];
            [v adjustConstraintsFor:NSLayoutAttributeTrailing byMultiplier:MENUS_SCALE_MULTIPLIER];
            [v adjustConstraintsFor:NSLayoutAttributeWidth byMultiplier:MENUS_SCALE_MULTIPLIER];
        }
    }
}

#pragma mark Setup

-(void)setupNavbarContainerSubviews
{
    UIEdgeInsets textFieldContainerMargin = UIEdgeInsetsMake(8, 0, 7, 0);
    self.textFieldContainer = [[TopMenuTextFieldContainer alloc] initWithMargin:textFieldContainerMargin];
    self.textFieldContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.textFieldContainer.textField.delegate = self;
    self.textFieldContainer.textField.returnKeyType = UIReturnKeyDone;
    self.textFieldContainer.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textFieldContainer.textField.font = SEARCH_TEXT_FIELD_FONT;
    self.textFieldContainer.textField.textColor = SEARCH_TEXT_FIELD_HIGHLIGHTED_COLOR;
    self.textFieldContainer.tag = NAVBAR_TEXT_FIELD;
    self.textFieldContainer.textField.clearButtonMode = UITextFieldViewModeNever;
    self.textFieldContainer.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [self.textFieldContainer.textField addTarget:self action:@selector(postNavItemTappedNotification:) forControlEvents:UIControlEventTouchUpInside];
    self.textFieldContainer.textField.placeholder = MWLocalizedString(@"search-field-placeholder-text", nil);

    // Perform search when text entered into textField
    [self.textFieldContainer.textField addTarget:self action:@selector(searchStringChanged) forControlEvents:UIControlEventEditingChanged];
    
    [self.navBarContainer addSubview:self.textFieldContainer];
 
    UIButton *clearButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 30, 25)];
    clearButton.backgroundColor = [UIColor clearColor];
    [clearButton setImage:[UIImage imageNamed:@"text_field_x_circle_gray.png"] forState:UIControlStateNormal];
    [clearButton addTarget:self action:@selector(clearTextFieldText) forControlEvents:UIControlEventTouchUpInside];
    
    self.textFieldContainer.textField.rightView = clearButton;
    [self updateClearButtonVisibility];

    WikiGlyphButton *(^getWikiGlyphButton)(NSString *, NSString *accessLabel, NavBarItemTag, CGFloat) =
    ^WikiGlyphButton *(NSString *character, NSString *accessLabel, NavBarItemTag tag, CGFloat size) {
        WikiGlyphButton *button = [[WikiGlyphButton alloc] init];

        [button.label setWikiText:character color:[UIColor blackColor] size:size baselineOffset:0];
        button.translatesAutoresizingMaskIntoConstraints = NO;

        [button addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget: self
                                                                             action: @selector(postNavItemTappedNotification:)]];
        button.tag = tag;
        
        button.accessibilityLabel = accessLabel;
        button.accessibilityTraits = UIAccessibilityTraitButton;
        return button;
    };

    CGFloat size = MENU_TOP_GLYPH_FONT_SIZE;

    BOOL isRTL = [WikipediaAppUtils isDeviceLanguageRTL];
    NSString *caret = !isRTL ? WIKIGLYPH_CARET_LEFT: IOS_WIKIGLYPH_FORWARD;

    self.buttonX =          getWikiGlyphButton(WIKIGLYPH_X,           MWLocalizedString(@"menu-close-accessibility-label", nil),   NAVBAR_BUTTON_X, size);
    self.buttonEye =        getWikiGlyphButton(WIKIGLYPH_EYE,         MWLocalizedString(@"menu-preview-accessibility-label", nil), NAVBAR_BUTTON_EYE, size);
    self.buttonArrowLeft =  getWikiGlyphButton(caret,                 MWLocalizedString(@"menu-back-accessibility-label", nil),    NAVBAR_BUTTON_ARROW_LEFT, size);
    self.buttonArrowRight = getWikiGlyphButton(caret,                 MWLocalizedString(@"menu-forward-accessibility-label", nil), NAVBAR_BUTTON_ARROW_RIGHT, size);
    self.buttonW =          getWikiGlyphButton(IOS_WIKIGLYPH_W,       MWLocalizedString(@"menu-w-accessibility-label", nil),       NAVBAR_BUTTON_LOGO_W, size);
    self.buttonTOC =        getWikiGlyphButton(IOS_WIKIGLYPH_TOC_COLLAPSED, MWLocalizedString(@"menu-toc-accessibility-label", nil),     NAVBAR_BUTTON_TOC, size);
    self.buttonMagnify =    getWikiGlyphButton(IOS_WIKIGLYPH_MAGNIFY, MWLocalizedString(@"menu-search-accessibility-label", nil),  NAVBAR_BUTTON_MAGNIFY, size);
    self.buttonBlank =      getWikiGlyphButton(@"",                   @"", NAVBAR_BUTTON_BLANK, size);
    self.buttonCancel =     getWikiGlyphButton(@"",                   MWLocalizedString(@"menu-cancel-accessibility-label", nil),  NAVBAR_BUTTON_CANCEL, size);
    self.buttonTrash =      getWikiGlyphButton(WIKIGLYPH_TRASH,       MWLocalizedString(@"menu-trash-accessibility-label", nil),   NAVBAR_BUTTON_TRASH, size);
    
    if (isRTL) {
        self.buttonTOC.transform = CGAffineTransformScale(CGAffineTransformIdentity, -1.0, 1.0);
    }

    self.buttonCancel.label.font = [UIFont systemFontOfSize:MENU_TOP_FONT_SIZE_CANCEL];
    self.buttonCancel.label.text = MWLocalizedString(@"search-cancel", nil);

    MenuButton *(^getMenuButton)(NSString *, NavBarItemTag, CGFloat, UIColor *, UIEdgeInsets, UIEdgeInsets) =
    ^MenuButton *(NSString *string, NavBarItemTag tag, CGFloat size, UIColor *color, UIEdgeInsets padding, UIEdgeInsets margin) {
        
        MenuButton *button = [[MenuButton alloc] initWithText: string
                                                     fontSize: size
                                                         bold: YES
                                                        color: color
                                                      padding: padding
                                                       margin: margin];
        
        [button addGestureRecognizer:
         [[UITapGestureRecognizer alloc] initWithTarget: self
                                                 action: @selector(postNavItemTappedNotification:)]];
        
        button.tag = tag;
        return button;
    };

    UIEdgeInsets padding = UIEdgeInsetsMake(0, 13, 0, 13);
    UIEdgeInsets margin = UIEdgeInsetsMake(8, 9, 7, 10);

    self.buttonNext =
        getMenuButton(MWLocalizedString(@"button-next", nil), NAVBAR_BUTTON_NEXT, MENU_TOP_FONT_SIZE_NEXT, WMF_COLOR_BLUE, padding, margin);
    self.buttonSave =
        getMenuButton(MWLocalizedString(@"button-save", nil), NAVBAR_BUTTON_SAVE, MENU_TOP_FONT_SIZE_SAVE, WMF_COLOR_GREEN, padding, margin);
    self.buttonDone =
        getMenuButton(MWLocalizedString(@"button-done", nil), NAVBAR_BUTTON_DONE, MENU_TOP_FONT_SIZE_DONE, WMF_COLOR_BLUE, padding, margin);
    self.buttonCheck =
        getMenuButton(WIKIGLYPH_TICK, NAVBAR_BUTTON_CHECK, MENU_TOP_FONT_SIZE_CHECK, WMF_COLOR_BLUE, UIEdgeInsetsMake(0, 0, 2, 0), UIEdgeInsetsMake(9, 0, 9, 8));

    // Ensure the cancel button content is hugged more tightly than the search text box.
    // Otherwise on iOS 6 the cancel button is super wide.
    [self.buttonCancel.label setContentHuggingPriority: 1000
                                               forAxis: UILayoutConstraintAxisHorizontal];

    self.buttonCancel.label.padding = UIEdgeInsetsMake(0, 5, 0, 5);
    
    self.textFieldContainer.textField.backgroundColor = [UIColor whiteColor];

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
    [self.navBarContainer addSubview:self.buttonTrash];

    [self.navBarContainer addSubview:self.buttonNext];
    [self.navBarContainer addSubview:self.buttonSave];
    [self.navBarContainer addSubview:self.buttonDone];


    self.label = [[UILabel alloc] init];
    self.label.text = @"";
    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    self.label.tag = NAVBAR_LABEL;
    self.label.font = [UIFont systemFontOfSize:19.0];
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
    for (UIView *view in [self.navBarContainer.subviews copy]) {
        if (view.tag == tag) return view;
    }
    return nil;
}

-(NSDictionary *)getNavBarSubViews
{
    return @{
             @"NAVBAR_BUTTON_X": self.buttonX,
             @"NAVBAR_BUTTON_CHECK": self.buttonCheck,
             @"NAVBAR_BUTTON_ARROW_LEFT": self.buttonArrowLeft,
             @"NAVBAR_BUTTON_ARROW_RIGHT": self.buttonArrowRight,
             @"NAVBAR_BUTTON_LOGO_W": self.buttonW,
             @"NAVBAR_BUTTON_TOC": self.buttonTOC,
             @"NAVBAR_BUTTON_MAGNIFY": self.buttonMagnify,
             @"NAVBAR_BUTTON_BLANK": self.buttonBlank,
             @"NAVBAR_BUTTON_CANCEL": self.buttonCancel,
             @"NAVBAR_BUTTON_NEXT": self.buttonNext,
             @"NAVBAR_BUTTON_SAVE": self.buttonSave,
             @"NAVBAR_BUTTON_DONE": self.buttonDone,
             @"NAVBAR_BUTTON_EYE": self.buttonEye,
             @"NAVBAR_BUTTON_TRASH": self.buttonTrash,
             @"NAVBAR_TEXT_FIELD": self.textFieldContainer,
             @"NAVBAR_LABEL": self.label
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
        TopMenuTextFieldContainer *textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
        [textFieldContainer.textField becomeFirstResponder];
    }

    _navBarMode = navBarMode;

    //PreviewAndSaveViewController *previewAndSaveVC = [NAV searchNavStackForViewControllerOfClass:[PreviewAndSaveViewController class]];
    //LoginViewController *loginVC = [NAV searchNavStackForViewControllerOfClass:[LoginViewController class]];
    //AccountCreationViewController *acctCreationVC = [NAV searchNavStackForViewControllerOfClass:[AccountCreationViewController class]];

    switch (navBarMode) {
        case NAVBAR_MODE_EDIT_WIKITEXT:
            self.label.text = @""; //MWLocalizedString(@"navbar-title-mode-edit-wikitext", nil);
            self.navBarSubViewsHorizontalVFLString =
                @"H:|-(4)-[NAVBAR_BUTTON_ARROW_LEFT(50)]-(10)-[NAVBAR_LABEL]-(10)-[NAVBAR_BUTTON_NEXT(50@250)]|";
            break;
        case NAVBAR_MODE_LOGIN:
            self.label.text = @"";
            //if((!previewAndSaveVC) && (!acctCreationVC)){
            //    self.navBarSubViewsHorizontalVFLString =
            //        @"H:|-(4)-[NAVBAR_BUTTON_X(50)]-(16)-[NAVBAR_LABEL]-(10)-[NAVBAR_BUTTON_DONE(50@250)]|";
            //}else{
                self.navBarSubViewsHorizontalVFLString =
                    @"H:|-(4)-[NAVBAR_BUTTON_X(50)]-(16)-[NAVBAR_LABEL]-(10)-[NAVBAR_BUTTON_DONE(50@250)]|";
            //}
            break;
        case NAVBAR_MODE_CREATE_ACCOUNT:
            self.label.text = @"";
            //if(loginVC){
                self.navBarSubViewsHorizontalVFLString =
                    @"H:|-(4)-[NAVBAR_BUTTON_X(50)]-(16)-[NAVBAR_LABEL]-(10)-[NAVBAR_BUTTON_NEXT(50@250)]|";
            //}else{
            //    self.navBarSubViewsHorizontalVFLString =
            //        @"H:|-(4)-[NAVBAR_BUTTON_X(50)]-(16)-[NAVBAR_LABEL]-(10)-[NAVBAR_BUTTON_NEXT(50@250)]|";
            //}
            
            break;
        case NAVBAR_MODE_CREATE_ACCOUNT_CAPTCHA:
            self.label.text = @"";
                self.navBarSubViewsHorizontalVFLString =
                    @"H:|-(4)-[NAVBAR_BUTTON_X(50)]-(16)-[NAVBAR_LABEL]-(10)-[NAVBAR_BUTTON_DONE(50@250)]|";
            break;
        case NAVBAR_MODE_EDIT_WIKITEXT_WARNING:
            //self.label.text = MWLocalizedString(@"navbar-title-mode-edit-wikitext-warning", nil);
            self.navBarSubViewsHorizontalVFLString =
                @"H:|-(4)-[NAVBAR_BUTTON_ARROW_LEFT(50)]-(16)-[NAVBAR_LABEL]-(10)-[NAVBAR_BUTTON_SAVE(50@250)]|";
            break;
        case NAVBAR_MODE_EDIT_WIKITEXT_DISALLOW:
            //self.label.text = MWLocalizedString(@"navbar-title-mode-edit-wikitext-disallow", nil);
            self.navBarSubViewsHorizontalVFLString =
                @"H:|-(4)-[NAVBAR_BUTTON_ARROW_LEFT(50)]-(10)-[NAVBAR_LABEL]-(60)-|";
            break;
        case NAVBAR_MODE_EDIT_WIKITEXT_PREVIEW:
            self.label.text = @"";
            //self.label.text = (NAVBAR_MODE_EDIT_WIKITEXT_PREVIEW == navBarMode) ?
            //    MWLocalizedString(@"navbar-title-mode-edit-wikitext-preview", nil)
            //    :
            //    MWLocalizedString(@"navbar-title-mode-edit-wikitext-summary", nil)
            //;
            self.navBarSubViewsHorizontalVFLString =
                @"H:|-(4)-[NAVBAR_BUTTON_ARROW_LEFT(50)]-(10)-[NAVBAR_LABEL]-(10)-[NAVBAR_BUTTON_SAVE(50@250)]|";
            break;
        case NAVBAR_MODE_EDIT_WIKITEXT_SUMMARY:
            self.label.text = @"";
            self.navBarSubViewsHorizontalVFLString =
                @"H:|-(4)-[NAVBAR_BUTTON_X(50)]-(10)-[NAVBAR_LABEL]-(10)-[NAVBAR_BUTTON_DONE(50@250)]|";

            break;
        case NAVBAR_MODE_EDIT_WIKITEXT_CAPTCHA:
            self.label.text = @""; //MWLocalizedString(@"navbar-title-mode-edit-wikitext-captcha", nil);
            self.navBarSubViewsHorizontalVFLString =
                @"H:|-(4)-[NAVBAR_BUTTON_X(50)]-(10)-[NAVBAR_LABEL]-(10)-[NAVBAR_BUTTON_SAVE(50@250)]|";
            break;
        case NAVBAR_MODE_SEARCH:
            self.navBarSubViewsHorizontalVFLString =
            @"H:|-(6)-[NAVBAR_TEXT_FIELD]-(6)-[NAVBAR_BUTTON_CANCEL]-(6)-|";
            break;
        case NAVBAR_MODE_X_WITH_LABEL:
            self.navBarSubViewsHorizontalVFLString =
            @"H:|-(6)-[NAVBAR_BUTTON_X(50)][NAVBAR_LABEL]-(56)-|";
            break;
        case NAVBAR_MODE_PAGES_HISTORY:
        case NAVBAR_MODE_PAGES_SAVED:
            self.navBarSubViewsHorizontalVFLString =
            @"H:|-(6)-[NAVBAR_BUTTON_X(50)]-(10)-[NAVBAR_LABEL]-(10)-[NAVBAR_BUTTON_TRASH(50@250)]-(6)-|";
            break;
        case NAVBAR_MODE_X_WITH_TEXT_FIELD:
            self.navBarSubViewsHorizontalVFLString =
            @"H:|-(6)-[NAVBAR_BUTTON_X(50)][NAVBAR_TEXT_FIELD]-(16)-|";
            break;
        case NAVBAR_MODE_DEFAULT_WITH_TOC:
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_LOGO_W(66)][NAVBAR_BUTTON_MAGNIFY(36)][NAVBAR_BUTTON_BLANK]-(10)-[NAVBAR_BUTTON_TOC(62)]|";
            break;
        default: //NAVBAR_MODE_DEFAULT
            self.navBarSubViewsHorizontalVFLString =
                @"H:|[NAVBAR_BUTTON_LOGO_W(66)][NAVBAR_BUTTON_MAGNIFY(36)][NAVBAR_BUTTON_BLANK]-(10)-|";
            break;
    }

    [self.view setNeedsUpdateConstraints];
}

#pragma mark Broadcast nav button taps

-(void)postNavItemTappedNotification:(id)sender
{
    UIView *tappedView = nil;
    if([sender isKindOfClass:[UIGestureRecognizer class]]){
        // We only want to take action when the tap recognizer is in Ended state.
        if (((UIGestureRecognizer *)sender).state != UIGestureRecognizerStateEnded) return;

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
    if([tappedView isKindOfClass:[WikiGlyphButton class]]){
        CGFloat animationScale = 1.25f;
        WikiGlyphButton *button = (WikiGlyphButton *)tappedView;
        [button.label animateAndRewindXF: CATransform3DMakeScale(animationScale, animationScale, 1.0f)
                            afterDelay: 0.0
                              duration: 0.04f
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
            [self hideSearchResultsController];
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
    if([NAV.viewControllers containsObject:self.searchResultsController]){
        [ROOT popToViewController:self.searchResultsController animated:NO];
    }else{
        [ROOT pushViewController:self.searchResultsController animated:NO];
    }
}

-(void)hideSearchResultsController
{
    if (NAV.topViewController == self.searchResultsController) {
        [ROOT popViewControllerAnimated:NO];
    }
}

#pragma mark Text field

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (self.textFieldContainer.textField.text.length == 0){
        // Remember user's last search term. Must come before the
        // @"SearchFieldBecameFirstResponder" notification is posted.
        if (self.searchResultsController.searchString.length != 0){
            self.textFieldContainer.textField.text = self.searchResultsController.searchString;
        }
    }

    [self.textFieldContainer.textField selectAll:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SearchFieldBecameFirstResponder" object:self userInfo:nil];

    [self showSearchResultsController];
    
    [self updateClearButtonVisibility];
}

-(void)clearTextFieldText
{
    self.textFieldContainer.textField.text = @"";
    [self updateClearButtonVisibility];
    self.searchResultsController.searchString = @"";
    [self.searchResultsController clearSearchResults];
}

- (void)searchStringChanged
{
    NSString *searchString = self.textFieldContainer.textField.text;

    NSString *trimmedSearchString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (self.navBarMode == NAVBAR_MODE_SEARCH) {
        
        self.searchResultsController.searchString = trimmedSearchString;
        
        [self.searchResultsController search];
        
    }else{
    
        [[NSNotificationCenter defaultCenter] postNotificationName: @"NavTextFieldTextChanged"
                                                            object: self
                                                          userInfo: @{@"text": searchString}];
    }
    
    [self updateClearButtonVisibility];
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

    [self updateClearButtonVisibility];
    
    return (NAV.isTransitioningBetweenViewControllers) ? NO : YES;
}

-(void)updateClearButtonVisibility
{
    self.textFieldContainer.textField.rightViewMode =
        (self.textFieldContainer.textField.text.length == 0) ? UITextFieldViewModeNever : UITextFieldViewModeAlways;
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
                       @"NAVBAR_COLOR": CHROME_COLOR,
                       @"NAVBAR_TEXT_FIELD_TEXT_COLOR": [UIColor colorWithWhite:0.33 alpha:1.0],
                       @"NAVBAR_TEXT_FIELD_PLACEHOLDER_TEXT_COLOR": [UIColor lightGrayColor],
                       @"NAVBAR_TEXT_CLEAR_BUTTON_COLOR": [UIColor colorWithWhite:0.33 alpha:1.0],
                       @"NAVBAR_BUTTON_COLOR": [UIColor blackColor],
                       @"NAVBAR_LABEL_TEXT_COLOR": [UIColor blackColor]
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
                       @"NAVBAR_LABEL_TEXT_COLOR": [UIColor whiteColor]
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
            WikiGlyphButton *button = (WikiGlyphButton *)view;
            button.label.textColor = colors[@"NAVBAR_BUTTON_COLOR"];
        }
            break;
        case NAVBAR_TEXT_FIELD:{
            TopMenuTextFieldContainer *textFieldContainer = (TopMenuTextFieldContainer *)view;
            
            // Typed text and cursor.
            textFieldContainer.textField.textColor = colors[@"NAVBAR_TEXT_FIELD_TEXT_COLOR"];
            if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
                textFieldContainer.textField.tintColor = colors[@"NAVBAR_TEXT_FIELD_TEXT_COLOR"];
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
        TopMenuTextFieldContainer *searchTextFieldContainer = [self getNavBarItem:NAVBAR_TEXT_FIELD];
        NSString *currentArticleTitle = [SessionSingleton sharedInstance].currentArticleTitle;
        self.navBarMode = (!searchTextFieldContainer.textField.isFirstResponder && currentArticleTitle && (currentArticleTitle.length > 0))
                ?
                NAVBAR_MODE_DEFAULT_WITH_TOC
                :
                NAVBAR_MODE_DEFAULT
                ;
    }
}

@end
