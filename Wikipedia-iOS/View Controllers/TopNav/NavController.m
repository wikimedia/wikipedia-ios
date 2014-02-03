//  Created by Monte Hurd on 12/16/13.

#import "NavBarTextField.h"
#import "NavController.h"
#import "Defines.h"
#import "UIView+Debugging.h"
#import "UIView+RemoveConstraints.h"
#import "NavBarContainerView.h"

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
@property (strong, nonatomic) UIButton *buttonArrowLeft;
@property (strong, nonatomic) UIButton *buttonArrowRight;
@property (strong, nonatomic) UILabel *label;


// Used for constraining container sub-views.
@property (strong, nonatomic) NSString *navBarSubViewsHorizontalVFLString;
@property (strong, nonatomic) NSDictionary *navBarSubViews;
@property (strong, nonatomic) NSDictionary *navBarSubViewMetrics;

@end

@implementation NavController

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

-(void)setNavBarStyle:(NavBarStyle)navBarStyle
{
        _navBarStyle = navBarStyle;
        switch (navBarStyle) {
            case NAVBAR_STYLE_EDIT_WIKITEXT:
                self.label.text = @"Edit";
            case NAVBAR_STYLE_LOGIN:
                self.navBarSubViewsHorizontalVFLString = @"H:|[NAVBAR_BUTTON_X(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL][NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_CHECK(50)]|";
                break;
            case NAVBAR_STYLE_EDIT_WIKITEXT_WARNING:
                self.label.text = @"Edit issues";
                self.navBarSubViewsHorizontalVFLString = @"H:|[NAVBAR_BUTTON_CHECK(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL][NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_PENCIL(50)]|";
                break;
            case NAVBAR_STYLE_EDIT_WIKITEXT_DISALLOW:
                self.label.text = @"Edit issues";
                self.navBarSubViewsHorizontalVFLString = @"H:|-(10)-[NAVBAR_LABEL][NAVBAR_VERTICAL_LINE_1(singlePixel)][NAVBAR_BUTTON_PENCIL(50)]|";
                break;
            default: //NAVBAR_STYLE_SEARCH
                self.navBarSubViewsHorizontalVFLString = @"H:|[NAVBAR_BUTTON_LOGO_W(65)][NAVBAR_VERTICAL_LINE_1(singlePixel)][NAVBAR_TEXT_FIELD]-(10)-|";
                break;
        }
        [self.view setNeedsUpdateConstraints];
}

-(void)setupNavbarContainerSubviews
{
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.navigationBar.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:0.97];
    }

    self.textField = [[NavBarTextField alloc] init];
    self.textField.delegate = self;
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    self.textField.returnKeyType = UIReturnKeyGo;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.font = SEARCH_FONT;
    self.textField.textColor = SEARCH_FONT_HIGHLIGHTED_COLOR;
    self.textField.tag = NAVBAR_TEXT_FIELD;
    self.textField.clearButtonMode = UITextFieldViewModeAlways;
    self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [self.textField addTarget:self action:@selector(navItemTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.navBarContainer addSubview:self.textField];

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
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.backgroundColor = [UIColor clearColor];
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [button setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(navItemTapped:) forControlEvents:UIControlEventTouchUpInside];

        button.tag = tag;
        return button;
    };

    self.buttonPencil =     getButton(@"abuse-filter-edit-black.png",   NAVBAR_BUTTON_PENCIL);
    self.buttonCheck =      getButton(@"abuse-filter-check.png",        NAVBAR_BUTTON_CHECK);
    self.buttonX =          getButton(@"button_cancel_grey.png",        NAVBAR_BUTTON_X);
    self.buttonEye =        getButton(@"button_preview_white.png",      NAVBAR_BUTTON_EYE);
    self.buttonArrowLeft =  getButton(@"button_arrow_left.png",         NAVBAR_BUTTON_ARROW_LEFT);
    self.buttonArrowRight = getButton(@"button_arrow_right.png",        NAVBAR_BUTTON_ARROW_RIGHT);
    self.buttonW =          getButton(@"w.png",                         NAVBAR_BUTTON_LOGO_W);

    [self.navBarContainer addSubview:self.buttonPencil];
    [self.navBarContainer addSubview:self.buttonCheck];
    [self.navBarContainer addSubview:self.buttonX];
    [self.navBarContainer addSubview:self.buttonEye];
    [self.navBarContainer addSubview:self.buttonArrowLeft];
    [self.navBarContainer addSubview:self.buttonArrowRight];
    [self.navBarContainer addSubview:self.buttonW];

    self.label = [[UILabel alloc] init];
    self.label.text = @"";
    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    self.label.tag = NAVBAR_LABEL;
    self.label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0];
    self.label.textColor = [UIColor darkGrayColor];
    self.label.backgroundColor = [UIColor clearColor];
    self.label.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapLabel = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navItemTapped:)];
    [self.label addGestureRecognizer:tapLabel];
    [self.navBarContainer addSubview:self.label];
}

-(void)navItemTapped:(id)sender
{
    UIView *tappedView = nil;
    if([sender isKindOfClass:[UIGestureRecognizer class]]){
        tappedView = ((UIGestureRecognizer *)sender).view;
    }else{
        tappedView = sender;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NavItemTapped" object:self userInfo:
        @{@"tappedItem": tappedView}
    ];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
 
    self.currentSearchString = @"";
    self.currentSearchStringWordsToHighlight = @[];

    [self setupNavbarContainer];
    [self setupNavbarContainerSubviews];

    [self.buttonW addTarget:self action:@selector(mainMenuToggle) forControlEvents:UIControlEventTouchUpInside];

    self.navBarStyle = NAVBAR_STYLE_SEARCH;

    self.textField.attributedPlaceholder = [self getAttributedPlaceholderString];

    [self.navigationBar addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:nil];

    // Perform search when text entered into textField
    [self.textField addTarget:self action:@selector(searchStringChanged) forControlEvents:UIControlEventEditingChanged];
    
    self.navBarSubViews = [self getNavBarSubViews];
    
    self.navBarSubViewMetrics = [self getNavBarSubViewMetrics];
}

-(void)setupNavbarContainer
{
    self.navBarContainer = [[NavBarContainerView alloc] init];
    self.navBarContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.navBarContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.navBarContainer];
}

-(void)updateViewConstraints
{
    [super updateViewConstraints];
    [self constrainNavBarContainer];
    [self constrainNavBarContainerSubViews];
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
    
    // Now take the views which were constrained horizontally (above) and constrain them
    // vertically as well. Also set hidden = NO for just these views.
    for (NSLayoutConstraint *c in [self.navBarContainer.constraints copy]) {
        UIView *view = (c.firstItem != self.navBarContainer) ? c.firstItem: c.secondItem;
        view.hidden = NO;
        [self.navBarContainer addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-(topMargin)-[view]|"
                                                 options: 0
                                                 metrics: @{@"topMargin": @((view.tag == NAVBAR_VERTICAL_LINE) ? 5 : 0)}
                                                   views: NSDictionaryOfVariableBindings(view)
          ]
         ];
    }
}

#pragma mark Search term changed

- (void)searchStringChanged
{
    NSString *searchString = self.textField.text;

    self.currentSearchString = searchString;
    [self updateWordsToHighlight];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SearchStringChanged" object:self userInfo:nil];

    NSString *trimmedSearchString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (trimmedSearchString.length == 0){
        self.textField.clearButtonMode = UITextFieldViewModeNever;
        return;
    }
    
    self.textField.clearButtonMode = UITextFieldViewModeAlways;
}

-(void)updateWordsToHighlight
{
    // Call this only when currentSearchString is updated. Keeps the list of words to highlight up to date.
    // Get the words by splitting currentSearchString on a combination of whitespace and punctuation
    // character sets so search term words get highlighted even if the puncuation in the result is slightly
    // different from the punctuation in the retrieved search result title.
    NSMutableCharacterSet *charSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [charSet formUnionWithCharacterSet:[NSMutableCharacterSet punctuationCharacterSet]];
    self.currentSearchStringWordsToHighlight = [self.currentSearchString componentsSeparatedByCharactersInSet:charSet];
}

-(NSAttributedString *)getAttributedPlaceholderString
{
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:SEARCH_FIELD_PLACEHOLDER_TEXT];

    [str addAttribute:NSFontAttributeName
                value:SEARCH_FONT_HIGHLIGHTED
                range:NSMakeRange(0, str.length)];

    [str addAttribute:NSForegroundColorAttributeName
                value:SEARCH_FIELD_PLACEHOLDER_TEXT_COLOR
                range:NSMakeRange(0, str.length)];

    return str;
}

-(void)mainMenuToggle
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MainMenuToggle" object:self userInfo:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(object == self.navigationBar){
        if ([keyPath isEqualToString:@"bounds"]) {
            [self.view setNeedsUpdateConstraints];
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SearchFieldBecameFirstResponder" object:self userInfo:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
