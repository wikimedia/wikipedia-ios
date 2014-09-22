//  Created by Monte Hurd on 4/18/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "CreditsViewController.h"
#import "WikipediaAppUtils.h"
#import "CenterNavController.h"
#import "RootViewController.h"
#import "TopMenuViewController.h"
#import "UIViewController+ModalPop.h"
#import "TabularScrollView.h"
#import "WikiGlyph_Chars_iOS.h"
#import "Defines.h"
#import "PaddedLabel.h"
#import "SecondaryMenuRowView.h"
#import "UIView+TemporaryAnimatedXF.h"

#define URL_APP_GITHUB @"https://github.com/wikimedia/apps-ios-wikipedia"
#define URL_APP_GERRIT @"https://gerrit.wikimedia.org/r/#/q/project:apps/ios/wikipedia,n,z"
#define URL_APP_WIKIFONT @"https://github.com/munmay/WikiFont"
#define URL_APP_HPPLE @"https://github.com/topfunky/hpple"
#define URL_APP_NSDATE @"https://github.com/erica/NSDate-Extensions"
#define URL_APP_AFNETWORKING @"https://github.com/AFNetworking/AFNetworking"
#define URL_APP_COCOAPODS @"http://cocoapods.org"

#define MENU_ICON_COLOR [UIColor blackColor]
#define MENU_ICON_FONT_SIZE 24

typedef enum {
    CREDITS_ROW_INDEX_HEADING_REPOS_WIKIMEDIA,
    CREDITS_ROW_INDEX_APP_REPO_GERRIT,
    CREDITS_ROW_INDEX_APP_REPO_GITHUB,
    CREDITS_ROW_INDEX_HEADING_REPOS_EXTERNAL,
    CREDITS_ROW_INDEX_REPO_WIKIFONT,
    CREDITS_ROW_INDEX_REPO_HPPLE,
    CREDITS_ROW_INDEX_REPO_NSDATE,
    CREDITS_ROW_INDEX_REPO_AFNETWORKING,
    CREDITS_ROW_INDEX_REPO_COCOAPODS,
    CREDITS_ROW_INDEX_HEADING_BLANK
} CeditsRowIndex;

@interface CreditsViewController ()

@property (strong, nonatomic) NSMutableArray *rowData;
@property (strong, nonatomic) NSMutableArray *rowViews;

@end

@implementation CreditsViewController

-(NavBarMode)navBarMode
{
    return NAVBAR_MODE_X_WITH_LABEL;
}

-(NSString *)title
{
    return MWLocalizedString(@"main-menu-credits", nil);
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(navItemTappedNotification:)
                                                 name: @"NavItemTapped"
                                               object: nil];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(tabularScrollViewItemTappedNotification:)
                                                 name: @"TabularScrollViewItemTapped"
                                               object: nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"NavItemTapped"
                                                  object: nil];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"TabularScrollViewItemTapped"
                                                  object: nil];

    [super viewWillDisappear:animated];
}

- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_X:
            [self popModal];
            break;
        default:
            break;
    }
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.rowViews = @[].mutableCopy;
    self.view.backgroundColor = CHROME_COLOR;
    self.scrollView.minSubviewHeight = 45;
    self.navigationItem.hidesBackButton = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.rowViews removeAllObjects];

    [self loadRowViews];
    
    self.scrollView.orientation = TABULAR_SCROLLVIEW_LAYOUT_HORIZONTAL;
    self.scrollView.tabularSubviews = self.rowViews;
}

-(void)loadRowViews
{
    // Don't forget - had to select "File's Owner" in left column of xib and then choose
    // this view controller in the Identity Inspector (3rd icon from left in right column)
    // in the Custom Class / Class dropdown. See: http://stackoverflow.com/a/21991592
    UINib *secondaryMenuRowViewNib = [UINib nibWithNibName:@"SecondaryMenuRowView" bundle:nil];

    [self setRowData];

    for (NSUInteger i = 0; i < self.rowData.count; i++) {
        NSMutableDictionary *row = self.rowData[i];

        SecondaryMenuRowView *rowView = [[secondaryMenuRowViewNib instantiateWithOwner:self options:nil] firstObject];

        rowView.tag = [self getIndexOfRow:row];

        [self.rowViews addObject:rowView];
    }
    [self applyRowSettings];
}

-(CeditsRowIndex)getIndexOfRow:(NSDictionary *)row
{
    return (CeditsRowIndex)((NSNumber *)row[@"tag"]).integerValue;
}

-(void)applyRowSettings
{
    for (NSUInteger i = 0; i < self.rowData.count; i++) {

        NSMutableDictionary *row = self.rowData[i];
        CeditsRowIndex index = [self getIndexOfRow:row];
        SecondaryMenuRowView *rowView = [self getViewWithTag:index];

        NSDictionary *attributes =
            @{
              NSFontAttributeName: [UIFont fontWithName:@"WikiFontGlyphs-iOS" size:MENU_ICON_FONT_SIZE],
              NSForegroundColorAttributeName : MENU_ICON_COLOR,
              NSBaselineOffsetAttributeName: @0
              };

        NSString *icon = row[@"icon"];
        rowView.iconLabel.attributedText =
            [[NSAttributedString alloc] initWithString: icon
                                            attributes: attributes];

        id title = row[@"title"];
        if([title isKindOfClass:[NSString class]]){
            //title = [NSString stringWithFormat:@"%@ %@ %@", title, title, title];
            rowView.textLabel.text = title;
        }else if([title isKindOfClass:[NSAttributedString class]]){
            rowView.textLabel.attributedText = title;
        }

        NSNumber *rowType = row[@"type"];
        rowView.rowType = rowType.integerValue;
    }

    // Let the rows know their relative positions so they can draw
    // borders appropriately.
    RowType lastRowType = ROW_TYPE_UNKNOWN;
    for (SecondaryMenuRowView *view in self.rowViews) {
        view.rowPosition = (view.rowType != lastRowType) ? ROW_POSITION_TOP : ROW_POSITION_UNKNOWN;
        lastRowType = view.rowType;
    }
}

-(SecondaryMenuRowView *)getViewWithTag:(CeditsRowIndex)tag
{
    for (SecondaryMenuRowView *view in self.rowViews) {
        if(view.tag == tag) return view;
    }
    return nil;
}

-(void)setRowData
{
    NSString *ltrSafeCaretCharacter = @""; //[WikipediaAppUtils isDeviceLanguageRTL] ? IOS_WIKIGLYPH_BACKWARD : IOS_WIKIGLYPH_FORWARD;
    
    NSMutableArray *rowData =
    @[
      @{
          @"title": MWLocalizedString(@"credits-wikimedia-repos", nil),
          @"tag": @(CREDITS_ROW_INDEX_HEADING_REPOS_WIKIMEDIA),
          @"icon": @"",
          @"type": @(ROW_TYPE_HEADING),
          @"url": @"",
          }.mutableCopy
      ,
      @{
          @"title": MWLocalizedString(@"credits-gerrit-repo", nil),
          @"tag": @(CREDITS_ROW_INDEX_APP_REPO_GERRIT),
          @"icon": ltrSafeCaretCharacter,
          @"type": @(ROW_TYPE_SELECTION),
          @"url": URL_APP_GERRIT,
          }.mutableCopy
      ,
      @{
          @"title": MWLocalizedString(@"credits-github-mirror", nil),
          @"tag": @(CREDITS_ROW_INDEX_APP_REPO_GITHUB),
          @"icon": ltrSafeCaretCharacter,
          @"type": @(ROW_TYPE_SELECTION),
          @"url": URL_APP_GITHUB,
          }.mutableCopy
      ,
      @{
          @"title": MWLocalizedString(@"credits-external-libraries", nil),
          @"tag": @(CREDITS_ROW_INDEX_HEADING_REPOS_EXTERNAL),
          @"icon": @"",
          @"type": @(ROW_TYPE_HEADING),
          @"url": @"",
          }.mutableCopy
      ,
      @{
          @"title": @"Wikifont",
          @"tag": @(CREDITS_ROW_INDEX_REPO_WIKIFONT),
          @"icon": ltrSafeCaretCharacter,
          @"type": @(ROW_TYPE_SELECTION),
          @"url": URL_APP_WIKIFONT,
          }.mutableCopy
      ,
      @{
          @"title": @"Hpple",
          @"tag": @(CREDITS_ROW_INDEX_REPO_HPPLE),
          @"icon": ltrSafeCaretCharacter,
          @"type": @(ROW_TYPE_SELECTION),
          @"url": URL_APP_HPPLE,
          }.mutableCopy
      ,
      @{
          @"title": @"NSDate-Extensions",
          @"tag": @(CREDITS_ROW_INDEX_REPO_NSDATE),
          @"icon": ltrSafeCaretCharacter,
          @"type": @(ROW_TYPE_SELECTION),
          @"url": URL_APP_NSDATE,
          }.mutableCopy
      ,
      @{
          @"title": @"AFNetworking",
          @"tag": @(CREDITS_ROW_INDEX_REPO_AFNETWORKING),
          @"icon": ltrSafeCaretCharacter,
          @"type": @(ROW_TYPE_SELECTION),
          @"url": URL_APP_AFNETWORKING,
          }.mutableCopy
      ,
      @{
          @"title": @"Cocoapods",
          @"tag": @(CREDITS_ROW_INDEX_REPO_COCOAPODS),
          @"icon": ltrSafeCaretCharacter,
          @"type": @(ROW_TYPE_SELECTION),
          @"url": URL_APP_COCOAPODS,
          }.mutableCopy
      ,
      @{
          @"title": @"",
          @"tag": @(CREDITS_ROW_INDEX_HEADING_BLANK),
          @"icon": @"",
          @"type": @(ROW_TYPE_HEADING),
          @"url": @"",
          }.mutableCopy

      ].mutableCopy;

    self.rowData = rowData;
}

-(NSMutableDictionary *)getRowWithTag:(CeditsRowIndex)tag
{
    for (NSMutableDictionary *row in self.rowData) {
        CeditsRowIndex index = [self getIndexOfRow:row];
        if (tag == index) return row;
    }
    return nil;
}

- (void)tabularScrollViewItemTappedNotification:(NSNotification *)notification
{
    CGFloat animationDuration = 0.08f;
    NSDictionary *userInfo = [notification userInfo];
    SecondaryMenuRowView *tappedItem = userInfo[@"tappedItem"];
    
    NSMutableDictionary *row = [self getRowWithTag:(CeditsRowIndex)tappedItem.tag];

    void(^performTapAction)() = ^(){
        NSString *url = row[@"url"];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    };

    CGFloat animationScale = 1.28f;
    
    NSString *icon = [row objectForKey:@"icon"];
    
    if (icon && (icon.length > 0) && (animationDuration > 0)) {
        [tappedItem.iconLabel animateAndRewindXF: CATransform3DMakeScale(animationScale, animationScale, 1.0f)
                                      afterDelay: 0.0
                                        duration: animationDuration
                                            then: performTapAction
         ];
    }else{
        performTapAction();
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
