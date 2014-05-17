//  Created by Monte Hurd on 1/23/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LanguagesTableVC.h"
#import "WikipediaAppUtils.h"
#import "SessionSingleton.h"
#import "DownloadLangLinksOp.h"
#import "QueuesSingleton.h"
#import "LanguagesCell.h"
#import "LanguagesSectionHeadingLabel.h"
#import "CenterNavController.h"
#import "Defines.h"
#import "BundledJson.h"

#import "UIViewController+Alert.h"

#pragma mark - Defines

#define BACKGROUND_COLOR [UIColor colorWithWhite:0.97f alpha:1.0f]

#pragma mark - Private properties

@interface LanguagesTableVC ()

@property (strong, nonatomic) NSArray *languagesData;
@property (strong, nonatomic) NSMutableArray *filteredLanguagesData;

@property (strong, nonatomic) NSString *filterString;
@property (strong, nonatomic) UITextField *filterTextField;
@property (strong, nonatomic) LanguagesSectionHeadingLabel *headingLabel;
@property (strong, nonatomic) UIButton *cancelButton;

@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) NSLayoutConstraint *headerViewTopConstraint;

@property (nonatomic) CGFloat scrollViewDragBeganVerticalOffset;

@end

@implementation LanguagesTableVC

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.scrollViewDragBeganVerticalOffset = 0.0f;
    self.navigationItem.hidesBackButton = YES;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.languagesData = @[];
    self.filteredLanguagesData = @[].mutableCopy;
    
    self.view.backgroundColor = BACKGROUND_COLOR;
 
    self.tableView.contentInset = UIEdgeInsetsMake(115, 0, 0, 0);

    self.filterString = @"";
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self setupHeaderView];

    if(self.downloadLanguagesForCurrentArticle){
        [self downloadLangLinkData];
    }else{
        self.languagesData = [BundledJson arrayFromBundledJsonFile:BUNDLED_JSON_LANGUAGES];
            self.headerView.hidden = NO;
        [self reloadTableDataFiltered];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.filterTextField resignFirstResponder];

    [[QueuesSingleton sharedInstance].langLinksQ cancelAllOperations];

    [self.headerView removeFromSuperview];

    [super viewWillDisappear:animated];
}

#pragma mark - Scrolling

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Hide the keyboard if it was visible when the results are scrolled, but only if
    // the results have been scrolled in excess of some small distance threshold first.
    CGFloat distanceScrolled = self.scrollViewDragBeganVerticalOffset - scrollView.contentOffset.y;
    CGFloat fabsDistanceScrolled = fabs(distanceScrolled);
    if (fabsDistanceScrolled > HIDE_KEYBOARD_ON_SCROLL_THRESHOLD) {
        if (self.filterTextField.isFirstResponder) {
            //NSLog(@"Keyboard Hidden!");
            [self.filterTextField resignFirstResponder];
        }
    }
  
    // Scroll the headerView to track with the table view.
    // Comment this line out to have headerView stick to top of page instead
    // of scrolling away.
    self.headerViewTopConstraint.constant = -(scrollView.contentOffset.y + self.tableView.contentInset.top);
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.scrollViewDragBeganVerticalOffset = scrollView.contentOffset.y;
}

#pragma mark - Header

-(void)setupHeaderView
{
    self.headerView = [self getHeaderView];
    self.headingLabel = [self getLanguagesSectionHeadingLabel];
    self.filterTextField = [self getFilterTextField];
    self.cancelButton = [self getCancelButton];

    [self.headerView addSubview:self.headingLabel];
    [self.headerView addSubview:self.filterTextField];
    [self.headerView addSubview:self.cancelButton];

    [self constrainHeaderSubviews];

    // Insert just beneath the nav bar (so no overlap issues).
    [self.navigationController.view insertSubview:self.headerView belowSubview:self.navigationController.navigationBar];

    [self constrainHeaderView];
}

-(void)constrainHeaderSubviews
{
    NSDictionary *views = @{
                            @"label": self.headingLabel,
                            @"textField": self.filterTextField,
                            @"cancelButton": self.cancelButton
                            };
    
    NSArray *constraints =
    @[
      [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-(20)-[label]-(>=0)-[cancelButton]-(10)-|"
                                              options: 0
                                              metrics: nil
                                                views: views
       ]
      ,
      [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-(20)-[textField]-(10)-|"
                                              options: 0
                                              metrics: nil
                                                views: views
       ]
      ,
      [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-(25)-[label]-(15)-[textField]-(10)-|"
                                              options: 0
                                              metrics: nil
                                                views: views]
      ,
      @[[NSLayoutConstraint constraintWithItem: self.cancelButton
                                     attribute: NSLayoutAttributeCenterY
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: self.headingLabel
                                     attribute: NSLayoutAttributeCenterY
                                    multiplier: 1.0
                                      constant: 0]]
      ];
    
    [self.headerView addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];
}

-(void)constrainHeaderView
{
    NSDictionary *views = @{@"headerView": self.headerView};

    self.headerViewTopConstraint =
    [NSLayoutConstraint constraintWithItem: self.headerView
                                 attribute: NSLayoutAttributeTop
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: self.navigationController.navigationBar
                                 attribute: NSLayoutAttributeBottom
                                multiplier: 1.0f
                                  constant: 0.0f];
    
    NSArray *constraints =
    @[
      [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[headerView]-(10)-|"
                                              options: 0
                                              metrics: nil
                                                views: views
       ]
      ,
      @[self.headerViewTopConstraint]
      ];

    [self.navigationController.view addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];
}

-(UIView *)getHeaderView
{
    UIView *view = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.hidden = YES;
    view.userInteractionEnabled = YES;
    view.backgroundColor = BACKGROUND_COLOR;
    return view;
}

-(UITextField *)getFilterTextField
{
    UITextField *textField = [[UITextField alloc] init];
    textField.delegate = self;
    [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.returnKeyType = UIReturnKeyDone;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.spellCheckingType = UITextSpellCheckingTypeNo;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.placeholder = MWLocalizedString(@"article-languages-filter-placeholder", nil);
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    return textField;
}

-(LanguagesSectionHeadingLabel *)getLanguagesSectionHeadingLabel
{
    LanguagesSectionHeadingLabel *label = [[LanguagesSectionHeadingLabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = MWLocalizedString(@"article-languages-label", nil);
    return label;
}

-(UIButton *)getCancelButton
{
    UIButton *cancelButton = [[UIButton alloc] init];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:14];
    cancelButton.userInteractionEnabled = YES;
    [cancelButton setTitle:MWLocalizedString(@"article-languages-cancel", nil) forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(hide) forControlEvents: UIControlEventTouchUpInside];
    [cancelButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    return cancelButton;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.filterTextField resignFirstResponder];
    return YES;
}

-(void)textFieldDidChange:(UITextField *)textField
{
    self.filterString = textField.text;
    [self reloadTableDataFiltered];
}

-(void)reloadTableDataFiltered
{
    if (self.filterString.length == 0){
        self.filteredLanguagesData = self.languagesData.mutableCopy;
        [self.tableView reloadData];
        return;
    }

    [self.filteredLanguagesData removeAllObjects];

    self.filteredLanguagesData =
        [self.languagesData filteredArrayUsingPredicate:
         [NSPredicate predicateWithFormat:@"\
              SELF.name contains[c] %@\
              || \
              SELF.canonical_name contains[c] %@\
              || \
              SELF.code == [c] %@\
          ", self.filterString, self.filterString, self.filterString]
        ].mutableCopy;

    [self.tableView reloadData];
}

#pragma mark - Article lang list download op

-(void)downloadLangLinkData
{
    [self showAlert:MWLocalizedString(@"article-languages-downloading", nil)];

    DownloadLangLinksOp *langLinksOp =
    [[DownloadLangLinksOp alloc] initForPageTitle: [SessionSingleton sharedInstance].currentArticleTitle
                                           domain: [SessionSingleton sharedInstance].currentArticleDomain
                                     allLanguages: [BundledJson arrayFromBundledJsonFile:BUNDLED_JSON_LANGUAGES]
                                  completionBlock: ^(NSArray *result){
                                      
                                      [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
                                          //[self showAlert:@"Language links loaded."];
                                          //[self fadeAlert];
                                                      self.headerView.hidden = NO;

                                          self.languagesData = result;
                                          [self reloadTableDataFiltered];
                                      }];
                                      
                                  } cancelledBlock: ^(NSError *error){
                                      //NSString *errorMsg = error.localizedDescription;
                                      [self fadeAlert];
                                      
                                  } errorBlock: ^(NSError *error){
                                      //NSString *errorMsg = error.localizedDescription;
                                      [self showAlert:error.localizedDescription];
                                      
                                  }];
    
    [[QueuesSingleton sharedInstance].langLinksQ cancelAllOperations];
    [[QueuesSingleton sharedInstance].langLinksQ addOperation:langLinksOp];
}

#pragma mark - Table protocol methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.filteredLanguagesData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 48;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
{
    return 0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"LanguagesCell";
    LanguagesCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    
    NSDictionary *d = self.filteredLanguagesData[indexPath.row];

    cell.textLabel.text = d[@"name"];
    cell.canonicalLabel.text = d[@"canonical_name"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *selectedLangInfo = self.filteredLanguagesData[indexPath.row];

    if(self.selectionBlock) self.selectionBlock(selectedLangInfo);
}

#pragma mark - Hide

-(void)hide
{
    [self.navigationController.view.layer addAnimation:[self getTransition] forKey:nil];

    // Don't animate - so the transistion set above will be used.
    [NAV popViewControllerAnimated:NO];
}

#pragma mark - Transition

-(CATransition *)getTransition
{
    CATransition *transition = [CATransition animation];
    transition.duration = 0.25;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    return transition;
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
