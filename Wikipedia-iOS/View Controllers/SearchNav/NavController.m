//  Created by Monte Hurd on 12/16/13.

#import "SearchBarTextField.h"
#import "SearchNavController.h"
#import "SearchBarLogoView.h"
#import "Defines.h"
#import "UIView+Debugging.h"
#import "UIView+RemoveConstraints.h"

@interface SearchNavController (){

}

@property (strong, nonatomic) SearchBarTextField *searchField;
@property (strong, nonatomic) SearchBarLogoView *leftView;
@property (strong, nonatomic) UIView *navBarContainer;

@end

@implementation SearchNavController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
 
    self.currentSearchString = @"";
    self.currentSearchStringWordsToHighlight = @[];

    [self setupNavbarContainer];
    [self setupNavbarContainerSubviews];

    self.searchField.attributedPlaceholder = [self getAttributedPlaceholderString];

    [self.navigationBar addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:nil];

    // Perform search when text entered into searchField
    [self.searchField addTarget:self action:@selector(searchStringChanged) forControlEvents:UIControlEventEditingChanged];
}

-(void)setupNavbarContainer
{
    self.navBarContainer = [[UIView alloc] init];
    self.navBarContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.navBarContainer];
}

-(void)setupNavbarContainerSubviews
{
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.navigationBar.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:0.97];
    }

    self.searchField = [[SearchBarTextField alloc] init];
    self.searchField.delegate = self;
    self.searchField.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchField.returnKeyType = UIReturnKeyGo;
    self.searchField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchField.font = SEARCH_FONT;
    self.searchField.textColor = SEARCH_FONT_HIGHLIGHTED_COLOR;

    self.leftView = [[SearchBarLogoView alloc] init];
    self.leftView.translatesAutoresizingMaskIntoConstraints = NO;

    self.leftView.backgroundColor = [UIColor clearColor];
    self.searchField.clearButtonMode = UITextFieldViewModeAlways;
    self.searchField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

    [self.navBarContainer addSubview:self.searchField];
    [self.navBarContainer addSubview:self.leftView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mainMenuToggle)];
    [self.leftView addGestureRecognizer:tap];
}

-(void)updateViewConstraints
{
    [super updateViewConstraints];
    [self constrainNavBarContainer];
    [self constrainSearchField];
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

-(void)constrainSearchField
{
    // Remove existing searchField constraints.
    [self.searchField removeConstraintsOfViewFromView:self.navBarContainer];

    NSDictionary *views = @{
                            @"searchField": self.searchField,
                            @"leftView": self.leftView
    };
    
    NSArray *searchFieldConstraints = @[
                                        [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[leftView(65)][searchField]|"
                                                                                options: 0
                                                                                metrics: nil
                                                                                  views: views
                                         ],
                                        [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[searchField]|"
                                                                                options: 0
                                                                                metrics: nil
                                                                                  views: views
                                         ],
                                        [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[leftView]|"
                                                                                options: 0
                                                                                metrics: nil
                                                                                  views: views
                                         ]
                                        ];
    
    [self.navBarContainer addConstraints:[searchFieldConstraints valueForKeyPath:@"@unionOfArrays.self"]];
}

#pragma mark Search term changed

- (void)searchStringChanged
{
    NSString *searchString = self.searchField.text;

    self.currentSearchString = searchString;
    [self updateWordsToHighlight];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SearchStringChanged" object:self userInfo:nil];

    NSString *trimmedSearchString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (trimmedSearchString.length == 0){
        self.searchField.clearButtonMode = UITextFieldViewModeNever;
        return;
    }
    
    self.searchField.clearButtonMode = UITextFieldViewModeAlways;
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
