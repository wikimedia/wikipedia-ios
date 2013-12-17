//  Created by Monte Hurd on 12/16/13.

#import "SearchBarTextField.h"
#import "SearchNavController.h"
#import "SearchBarLogoView.h"
#import "Defines.h"
#import "SearchResultsController.h"

@interface SearchNavController (){
    UIView *navBarSubview_;
}

@property (strong, nonatomic) SearchBarTextField *searchField;

@end

@implementation SearchNavController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
 
    self.currentSearchString = @"";
    self.currentSearchStringWordsToHighlight = @[];

    [self setupNavbarSubview];

    self.searchField.attributedPlaceholder = [self getAttributedPlaceholderString];

    // Force the nav bar's subview to update for initial display - needed for iOS 6.
    [self updateNavBarSubviewFrame];
    
    // Observe changes to nav bar's bounds so the nav bar's subview's frame can be
    // kept in sync so it always overlays it perfectly, even as rotation animation
    // tweens the nav bar frame.
    [self.navigationBar addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:nil];

    // Perform search when text entered into searchField
    [self.searchField addTarget:self action:@selector(searchStringChanged) forControlEvents:UIControlEventEditingChanged];
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

-(void)setupNavbarSubview
{
    navBarSubview_ = [[UIView alloc] init];
    navBarSubview_.backgroundColor = [UIColor clearColor];
    navBarSubview_.translatesAutoresizingMaskIntoConstraints = NO;

    [self.navigationBar addSubview:navBarSubview_];
    
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.navigationBar.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:0.97];
    }

    self.searchField = [[SearchBarTextField alloc] init];
    self.searchField.delegate = self;
    self.searchField.returnKeyType = UIReturnKeyGo;
    self.searchField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchField.font = SEARCH_FONT;
    self.searchField.textColor = SEARCH_FONT_HIGHLIGHTED_COLOR;
    //self.searchField.frame = CGRectInset(navBarSubview_.frame, 3, 3);

    self.searchField.leftViewMode = UITextFieldViewModeAlways;
    self.searchField.leftView = [[SearchBarLogoView alloc] initWithFrame:CGRectMake(0, 0, 65, 50)];

    self.searchField.leftView.backgroundColor = [UIColor clearColor];
    self.searchField.clearButtonMode = UITextFieldViewModeAlways;
    self.searchField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

    [navBarSubview_ addSubview:self.searchField];

    //navBarSubview_.layer.borderWidth = 0.5f;
    //self.searchField.layer.borderWidth = 0.5f;
    //navBarSubview_.layer.borderColor = [UIColor greenColor].CGColor;
    //self.searchField.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
    //self.navigationBar.backgroundColor = [UIColor greenColor];
    //self.navigationBar.layer.borderWidth = 0.5;
    //self.navigationBar.layer.borderColor = [UIColor purpleColor].CGColor;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(historyToggle)];
    [self.searchField.leftView addGestureRecognizer:tap];

//TODO: remove these access points to the saved pages toggle and save functionality - setting searchField.rightView blocks the clear text button!

    // Temporarily hook save up to disc icon long press.
    self.searchField.rightViewMode = UITextFieldViewModeAlways;
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 28, 35)];
    l.text = @"💾";
    l.userInteractionEnabled = YES;
    self.searchField.rightView = l;
    self.searchField.rightView.backgroundColor = [UIColor clearColor];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(savePage:)];
    longPress.minimumPressDuration = 0.25f;
    [self.searchField.rightView addGestureRecognizer:longPress];

    // Temporarily hook saved interface up to disc icon tap.
    UITapGestureRecognizer *rightTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(savedPagesToggle:)];
    [self.searchField.rightView addGestureRecognizer:rightTap];
}

-(void)historyToggle
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HistoryToggle" object:self userInfo:nil];
}

-(void)savePage:(UILongPressGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
        animation.autoreverses = YES;
        animation.duration = 0.15;
        animation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(2.4, 2.4, 1)];
        [self.searchField.rightView.layer addAnimation:animation forKey:nil];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"SavePage" object:self userInfo:nil];
    }
}

-(void)savedPagesToggle:(UITapGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SavedPagesToggle" object:self userInfo:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(object == self.navigationBar){
        [self updateNavBarSubviewFrame];
    }
}

-(void)updateNavBarSubviewFrame
{
    // To get the search box floating over a translucent view it was placed as a subview of
    // the nav bar, but the nav bar doesn't do autolayout on it's subviews, so the subview
    // is resized manually here.
    navBarSubview_.frame = self.navigationBar.bounds;
    //self.searchField.frame = navBarSubview_.bounds;
    CGFloat rightPadding = (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) ? 0.0f : 6.0f;
    
    self.searchField.frame = CGRectMake(
                                        navBarSubview_.bounds.origin.x,
                                        navBarSubview_.bounds.origin.y,
                                        navBarSubview_.bounds.size.width - rightPadding,
                                        navBarSubview_.bounds.size.height
                                        );

    // Make the search field's leftView (a UIImageView) be as tall as the search field
    // so its image can resize accordingly
    self.searchField.leftView.frame = CGRectMake(self.searchField.leftView.frame.origin.x, self.searchField.leftView.frame.origin.y, self.searchField.leftView.frame.size.width, self.searchField.frame.size.height);
}

-(void)resignSearchFieldFirstResponder
{
    if ([self isSearchFieldFirstResponder]) {
        [self.searchField resignFirstResponder];
    }
}

-(BOOL)isSearchFieldFirstResponder{
    return self.searchField.isFirstResponder;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
