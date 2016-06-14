//  Created by Monte Hurd on 7/25/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "ReferencesVC.h"
#import "ReferenceVC.h"
#import "WikiGlyphButton.h"
#import "WikiGlyphLabel.h"
#import "WikiGlyph_Chars.h"
#import "WikipediaAppUtils.h"
#import "UIView+Debugging.h"
#import "WMF_Colors.h"
#import "ReferenceGradientView.h"
#import "SessionSingleton.h"
#import "MWLanguageInfo.h"
#import "Defines.h"
#import "NSObject+ConstraintsScale.h"
#import "Wikipedia-Swift.h"

// Show prev-next buttons instead of page dots if number of refs exceeds this number.
#define PAGE_CONTROL_MAX_REFS 10
#define PAGE_CONTROL_DOT_COLOR 0x2b6fb2

@interface ReferencesVC ()<ReferenceVCDelegate>

@property (strong, nonatomic) UIPageControl* topPageControl;
@property (strong, nonatomic) WikiGlyphButton* xButton;

@property (strong, nonatomic) WikiGlyphButton* nextButton;
@property (strong, nonatomic) WikiGlyphButton* prevButton;

@property (strong, nonatomic) ReferenceGradientView* topContainerView;

@property (strong, nonatomic) NSArray* refs;
@property (nonatomic) NSUInteger refsIndex;
@property (strong, nonatomic) NSArray* linkIds;
@property (strong, nonatomic) NSArray* linkText;

@end

@implementation ReferencesVC

- (void)reset {
    // Load a fake blank set of data.
    self.payload = @{
        @"linkId": @[@"fake_refs_id"],
        @"linkText": @[@""],
        @"refs": @[@""],
        @"refsIndex": @(0)
    };
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.panelHeight = 0;
    self.refs        = @[@""];
    self.linkIds     = @[];
    self.linkText    = @[];
    self.refsIndex   = 0;

    self.view.backgroundColor = [UIColor blackColor];

    [self setupPageController];

    [self setupTopContainer];

    [self setupConstraints];

    //self.view.layer.borderColor = [UIColor redColor].CGColor;
    //self.view.layer.borderWidth = 10;
    //[self.view randomlyColorSubviews];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.view);
}

- (void)setupPageController {
    self.pageController =
        [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                        navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                      options:nil];

    self.pageController.dataSource = self;
    self.pageController.delegate   = self;

    [self addChildViewController:self.pageController];
    [self.view addSubview:self.pageController.view];
    [self.pageController didMoveToParentViewController:self];

    ReferenceVC* initialVC = [self viewControllerAtIndex:0];

    if (initialVC) {
        [self setViewControllers:@[initialVC]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:NO
                      completion:nil];
    }
}

- (void)setupTopContainer {
    self.topContainerView = [[ReferenceGradientView alloc] init];

    self.topContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.topContainerView.backgroundColor                           = [UIColor clearColor];
    [self.view addSubview:self.topContainerView];

    self.xButton                                           = [[WikiGlyphButton alloc] init];
    self.xButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.xButton.label setWikiText:WIKIGLYPH_X
                              color:[UIColor darkGrayColor]
                               size:22.0 * MENUS_SCALE_MULTIPLIER
                     baselineOffset:0];
    self.xButton.accessibilityLabel     = MWLocalizedString(@"close-button-accessibility-label", nil);
    self.xButton.label.textAlignment    = NSTextAlignmentCenter;
    self.xButton.userInteractionEnabled = YES;
    [self.topContainerView addSubview:self.xButton];

    BOOL isRTL = [[UIApplication sharedApplication] wmf_isRTL];

    self.nextButton                                           = [[WikiGlyphButton alloc] init];
    self.nextButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nextButton.label setWikiText:isRTL ? WIKIGLYPH_BACKWARD : WIKIGLYPH_FORWARD
                                 color:[UIColor darkGrayColor]
                                  size:24.0 * MENUS_SCALE_MULTIPLIER
                        baselineOffset:2.0];
    self.nextButton.hidden = YES;
    [self.topContainerView addSubview:self.nextButton];

    self.prevButton                                           = [[WikiGlyphButton alloc] init];
    self.prevButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.prevButton.label setWikiText:isRTL ? WIKIGLYPH_FORWARD : WIKIGLYPH_BACKWARD
                                 color:[UIColor darkGrayColor]
                                  size:24.0 * MENUS_SCALE_MULTIPLIER
                        baselineOffset:2.0];
    self.prevButton.hidden = YES;
    [self.topContainerView addSubview:self.prevButton];

    UITapGestureRecognizer* prevTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(prevButtonTap:)];
    [self.prevButton addGestureRecognizer:prevTap];

    UITapGestureRecognizer* nextTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(nextButtonTap:)];
    [self.nextButton addGestureRecognizer:nextTap];

    UITapGestureRecognizer* xTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(xButtonTap:)];
    [self.xButton addGestureRecognizer:xTap];

    //self.nextButton.layer.borderWidth = 1;
    //self.prevButton.layer.borderWidth = 1;
    //self.nextButton.layer.borderColor = [UIColor whiteColor].CGColor;
    //self.prevButton.layer.borderColor = [UIColor whiteColor].CGColor;

    //self.xButton.layer.borderWidth = 1;
    //self.xButton.layer.borderColor = [UIColor whiteColor].CGColor;

    self.topPageControl = [[UIPageControl alloc] init];

    //self.topPageControl.pageIndicatorTintColor = [UIColor redColor];
    self.topPageControl.currentPageIndicatorTintColor = UIColorFromRGBWithAlpha(PAGE_CONTROL_DOT_COLOR, 1.0);

    self.topPageControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.topPageControl.numberOfPages                             = 0;
    self.topPageControl.currentPage                               = 0;
    self.topPageControl.hidesForSinglePage                        = YES;
    [self.topPageControl addTarget:self action:@selector(topPageControlTapped:) forControlEvents:UIControlEventValueChanged];
    [self.topContainerView addSubview:self.topPageControl];

    // For now disable page control interactions. Taps are ok, but
    // if you try to swipe the page control is doing something goofy
    // with control events and swipes are sometimes falling through
    // to the article web view, which causes the WebViewController
    // to present the TOC.
    self.topPageControl.userInteractionEnabled = NO;

    //self.topContainerView.layer.borderWidth = 1;
    //self.topContainerView.layer.borderColor = [UIColor whiteColor].CGColor;
}

- (void)xButtonTap:(UITapGestureRecognizer*)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.delegate referenceViewControllerCloseReferences:self];
    }
}

- (void)setupConstraints {
    NSDictionary* views = @{
        @"xButton": self.xButton,
        @"topPageControl": self.topPageControl,
        @"topContainerView": self.topContainerView,
        @"nextButton": self.nextButton,
        @"prevButton": self.prevButton
    };

    NSDictionary* metrics = @{
        @"topItemsHeight": @50,
        @"vPadding": @7,
        @"hPadding": @14,
        @"xWidth": @50
    };

    [self.topContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[xButton(xWidth)]"
                                                                                  options:0
                                                                                  metrics:metrics
                                                                                    views:views]];

    [self.topContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[topPageControl]-(25)-|"
                                                                                  options:0
                                                                                  metrics:metrics
                                                                                    views:views]];

    [self.topContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(vPadding)-[xButton]-(vPadding)-|"
                                                                                  options:0
                                                                                  metrics:metrics
                                                                                    views:views]];

    [self.topContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(vPadding)-[nextButton]-(vPadding)-|"
                                                                                  options:0
                                                                                  metrics:metrics
                                                                                    views:views]];

    [self.topContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(vPadding)-[prevButton]-(vPadding)-|"
                                                                                  options:0
                                                                                  metrics:metrics
                                                                                    views:views]];

    [self.topContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[prevButton]-(20)-[nextButton]-(hPadding)-|"
                                                                                  options:0
                                                                                  metrics:metrics
                                                                                    views:views]];

    [self.topContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(vPadding)-[topPageControl]-(vPadding)-|"
                                                                                  options:0
                                                                                  metrics:metrics
                                                                                    views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topContainerView(topItemsHeight)]"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[topContainerView]|"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];

    [self adjustConstraintsScaleForViews:@[self.xButton, self.nextButton, self.prevButton, self.topContainerView, self.topPageControl]];
}

- (NSArray*)refs {
    if (!_refs || (_refs.count == 0)) {
        return @[@""];
    }
    return self.payload[@"refs"];
}

- (NSUInteger)refsIndex {
    NSNumber* index = self.payload[@"refsIndex"];
    return index.integerValue;
}

- (NSArray*)linkIds {
    return self.payload[@"linkId"];
}

- (NSArray*)linkText {
    return self.payload[@"linkText"];
}

- (NSDictionary*)reversePayloadArraysIfRTL:(NSDictionary*)payload {
    //NSString *domain = [SessionSingleton sharedInstance].currentArticleDomain;
    //MWLanguageInfo *languageInfo = [MWLanguageInfo languageInfoForCode:domain];
    BOOL isRTL = [[UIApplication sharedApplication] wmf_isRTL];
    if (isRTL) {
        //if ([languageInfo.dir isEqualToString:@"ltr"]) {
        NSArray* a = payload[@"linkId"];
        if (a.count > 0) {
            NSNumber* n = payload[@"refsIndex"];
            payload = @{
                @"linkId": [[payload[@"linkId"] reverseObjectEnumerator] allObjects],
                @"linkText": [[payload[@"linkText"] reverseObjectEnumerator] allObjects],
                @"refs": [[payload[@"refs"] reverseObjectEnumerator] allObjects],
                @"refsIndex": @((a.count - 1) - n.integerValue)
            };
        }
    }
    return payload;
}

- (void)scrollTappedReferenceUp {
    NSNumber* n = self.payload[@"refsIndex"];
    if (!n) {
        return;
    }
    NSArray* a = self.payload[@"linkId"];
    if (!a || (a.count == 0)) {
        return;
    }
    NSString* firstLinkId = a[0];
    if ([firstLinkId isEqualToString:@"fake_refs_id"]) {
        return;
    }

    NSString* elementId = a[n.integerValue];
    if (!elementId) {
        return;
    }
}

- (void)setPayload:(NSDictionary*)payload {
    payload = [self reversePayloadArraysIfRTL:payload];

    _payload = payload;

    [self scrollTappedReferenceUp];

    BOOL hidePageControl = (self.refs.count > PAGE_CONTROL_MAX_REFS);
    self.prevButton.hidden = (!hidePageControl) || (self.refs.count < 2);
    self.nextButton.hidden = (!hidePageControl) || (self.refs.count < 2);
    // Use alpha - other changes to page control properties apparently cause it to be
    // set to be not hidden. This way all that other code can remain as-is.
    self.topPageControl.alpha = (hidePageControl ? 0.0 : 1.0);

    UIPageViewControllerNavigationDirection dir = (self.topPageControl.currentPage < self.refsIndex)
                                                  ?
                                                  UIPageViewControllerNavigationDirectionForward
                                                  :
                                                  UIPageViewControllerNavigationDirectionReverse;

    BOOL shouldAnimate = ((self.refs.count == 1) ? NO : YES);

    if (self.topPageControl.currentPage == self.refsIndex) {
        shouldAnimate = NO;
    }

    [self setViewControllers:@[[self viewControllerAtIndex:self.refsIndex]]
                   direction:dir
                    animated:shouldAnimate
                  completion:nil];

    self.topPageControl.numberOfPages = self.refs.count;
    self.topPageControl.currentPage   = self.refsIndex;
}

- (void)refViewDidAppear:(NSUInteger)index {
    self.prevButton.enabled = (index <= 0) ? NO : YES;
    self.nextButton.enabled = (index >= (self.refs.count - 1)) ? NO : YES;
}

- (void)setViewControllers:(NSArray*)viewControllers
                 direction:(UIPageViewControllerNavigationDirection)direction
                  animated:(BOOL)animated
                completion:(void (^)(BOOL finished))completion {
    // UIPageViewController is ridiculous. Making it jump to a specific page is tricky - it
    // will not then swipe back or forward correctly. This method fixes that. Use it rather
    // than calling UIPageViewController's "setViewControllers" method directly.
    // Based on: http://stackoverflow.com/a/18602186

    __weak ReferencesVC* weakSelf = self;
    [self.pageController setViewControllers:viewControllers
                                  direction:direction
                                   animated:animated
                                 completion:^(BOOL finished) {
        if (!weakSelf.pageController) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.pageController setViewControllers:viewControllers
                                              direction:direction
                                               animated:NO
                                             completion:^(BOOL done){
                [weakSelf refViewDidAppear:weakSelf.topPageControl.currentPage];
            }];
        });
    }];
}

- (void) pageViewController:(UIPageViewController*)pageViewController
         didFinishAnimating:(BOOL)finished
    previousViewControllers:(NSArray*)previousViewControllers
        transitionCompleted:(BOOL)completed {
    // UIPageViewController was swiped.
    // Update the UIPageControl dots to reflect the UIPageViewController selection.
    ReferenceVC* currentView = [pageViewController.viewControllers objectAtIndex:0];
    self.topPageControl.currentPage = currentView.index;

    [self refViewDidAppear:self.topPageControl.currentPage];
}

- (ReferenceVC*)viewControllerAtIndex:(NSInteger)index {
    if (index < 0) {
        return nil;
    }
    if (index >= self.refs.count) {
        return nil;
    }

    ReferenceVC* refVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ReferenceVC"];
    refVC.delegate = self;
    refVC.index    = index;
    refVC.html     = self.refs[index];
    refVC.linkId   = self.linkIds[index];
    refVC.linkText = self.linkText[index];

    return refVC;
}

- (void)referenceViewController:(ReferenceVC*)referenceViewController didShowReferenceWithLinkID:(NSString*)linkID {
    [self.delegate referenceViewController:self didShowReferenceWithLinkID:linkID];
}

- (void)referenceViewController:(ReferenceVC*)referenceViewController didFinishShowingReferenceWithLinkID:(NSString*)linkID {
    [self.delegate referenceViewController:self didFinishShowingReferenceWithLinkID:linkID];
}

- (void)referenceViewController:(ReferenceVC*)referenceViewController didSelectInternalReferenceWithFragment:(NSString*)fragment {
    [self.delegate referenceViewController:self didSelectInternalReferenceWithFragment:fragment];
}

- (void)referenceViewController:(ReferenceVC*)referenceViewController didSelectReferenceWithTitle:(MWKTitle*)title {
    [self.delegate referenceViewController:self didSelectReferenceWithTitle:title];
}

- (void)referenceViewController:(ReferenceVC*)referenceViewController didSelectExternalReferenceWithURL:(NSURL*)url {
    [self.delegate referenceViewController:self didSelectExternalReferenceWithURL:url];
}

- (UIViewController*)pageViewController:(UIPageViewController*)pageViewController
     viewControllerBeforeViewController:(UIViewController*)viewController {
    return [self viewControllerAtIndex:(((ReferenceVC*)viewController).index - 1)];
}

- (UIViewController*)pageViewController:(UIPageViewController*)pageViewController
      viewControllerAfterViewController:(UIViewController*)viewController {
    return [self viewControllerAtIndex:(((ReferenceVC*)viewController).index + 1)];
}

- (void)topPageControlTapped:(id)sender {
    // UIPageControl was tapped.
    // Update the UIPageViewController to reflect the UIPageControl selection.

    ReferenceVC* currentView   = [self.pageController.viewControllers objectAtIndex:0];
    BOOL isTopPageControlAhead = (self.topPageControl.currentPage > currentView.index);

    id nextVC = isTopPageControlAhead
                ?
                [self pageViewController : self.pageController viewControllerAfterViewController:currentView]
                :
                [self pageViewController:self.pageController viewControllerBeforeViewController:currentView];

    UIPageViewControllerNavigationDirection dir = isTopPageControlAhead
                                                  ?
                                                  UIPageViewControllerNavigationDirectionForward
                                                  :
                                                  UIPageViewControllerNavigationDirectionReverse;

    if (nextVC) {
        [self setViewControllers:@[nextVC]
                       direction:dir
                        animated:YES
                      completion:nil];
    }
}

- (void)prevButtonTap:(UITapGestureRecognizer*)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (!self.prevButton.enabled) {
            return;
        }

        BOOL isRTL = [[UIApplication sharedApplication] wmf_isRTL];

        UIPageViewControllerNavigationDirection dir = isRTL
                                                      ?
                                                      UIPageViewControllerNavigationDirectionForward
                                                      :
                                                      UIPageViewControllerNavigationDirectionReverse;

        [self setViewControllers:@[[self viewControllerAtIndex:(--self.topPageControl.currentPage)]]
                       direction:dir
                        animated:YES
                      completion:nil];
    }
}

- (void)nextButtonTap:(UITapGestureRecognizer*)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (!self.nextButton.enabled) {
            return;
        }

        BOOL isRTL = [[UIApplication sharedApplication] wmf_isRTL];

        UIPageViewControllerNavigationDirection dir = isRTL
                                                      ?
                                                      UIPageViewControllerNavigationDirectionReverse
                                                      :
                                                      UIPageViewControllerNavigationDirectionForward;

        [self setViewControllers:@[[self viewControllerAtIndex:(++self.topPageControl.currentPage)]]
                       direction:dir
                        animated:YES
                      completion:nil];
    }
}

/*
   // Commented out these two methods to hide the built-in UIPageControl.
   // See: http://stackoverflow.com/a/20749979
   - (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return 5;
   }

   - (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    return 0;
   }
 */

- (void)didReceiveMemoryWarning {
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
