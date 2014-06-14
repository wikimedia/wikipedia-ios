//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WebViewController.h"

#import "WikipediaAppUtils.h"
#import "DownloadWikipediaZeroMessageOp.h"
#import "ArticleDataContextSingleton.h"
#import "SectionEditorViewController.h"
#import "DownloadSectionsOp.h"
#import "ArticleCoreDataObjects.h"
#import "CommunicationBridge.h"
#import "TOCViewController.h"
#import "SessionSingleton.h"
#import "QueuesSingleton.h"
#import "TopMenuTextField.h"
#import "TopMenuTextFieldContainer.h"
#import "MWLanguageInfo.h"
#import "CenterNavController.h"
#import "Defines.h"

#import "UIViewController+SearchChildViewControllers.h"
#import "NSManagedObjectContext+SimpleFetch.h"
#import "UIScrollView+NoHorizontalScrolling.h"
#import "UIViewController+HideKeyboard.h"
#import "UIWebView+HideScrollGradient.h"
#import "UIWebView+ElementLocation.h"
#import "UIView+RemoveConstraints.h"
#import "UIViewController+Alert.h"
#import "Section+ImageRecords.h"
#import "Section+LeadSection.h"
#import "NSString+Extras.h"

#import "PaddedLabel.h"
//#import "UIView+Debugging.h"

#import "DataMigrator.h"
#import "ArticleImporter.h"

#import "SyncAssetsFileOp.h"

#import "RootViewController.h"
#import "TopMenuViewController.h"
#import "BottomMenuViewController.h"

#import "LanguagesTableVC.h"

#import "ModalMenuAndContentViewController.h"
#import "UIViewController+PresentModal.h"
#import "Section+DisplayHtml.h"

#import "EditFunnel.h"

#define TOC_TOGGLE_ANIMATION_DURATION @0.3f

typedef enum {
    DISPLAY_LEAD_SECTION = 0,
    DISPLAY_APPEND_NON_LEAD_SECTIONS = 1,
    DISPLAY_ALL_SECTIONS = 2
} DisplayMode;

@interface WebViewController (){

}

@property (strong, nonatomic) CommunicationBridge *bridge;

@property (nonatomic) CGPoint scrollOffset;

@property (nonatomic) BOOL unsafeToScroll;

@property (nonatomic) NSInteger indexOfFirstOnscreenSectionBeforeRotate;
@property (nonatomic) NSUInteger sectionToEditId;

@property (strong, nonatomic) NSDictionary *adjacentHistoryIDs;
@property (strong, nonatomic) NSString *externalUrl;

@property (weak, nonatomic) IBOutlet UIView *bottomBarView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webViewLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webViewRightConstraint;

@property (weak, nonatomic) NSLayoutConstraint *pullToRefreshViewBottomConstraint;
@property (strong, nonatomic) UILabel *pullToRefreshLabel;
@property (strong, nonatomic) UIView *pullToRefreshView;

@property (strong, nonatomic) TOCViewController *tocVC;
@property (strong, nonatomic) UISwipeGestureRecognizer *tocSwipeLeftRecognizer;
@property (strong, nonatomic) UISwipeGestureRecognizer *tocSwipeRightRecognizer;

@property (strong, nonatomic) IBOutlet PaddedLabel *zeroStatusLabel;

@property (nonatomic) BOOL unsafeToToggleTOC;

@property (weak, nonatomic) BottomMenuViewController *bottomMenuViewController;

@property (strong, nonatomic) NSLayoutConstraint *bottomBarViewBottomConstraint;

@end

#pragma mark Internal variables

@implementation WebViewController {
    CGFloat scrollViewDragBeganVerticalOffset_;
    ArticleDataContextSingleton *articleDataContext_;
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

#pragma mark View lifecycle methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.zeroStatusLabel.text = @"";
    
    self.sectionToEditId = 0;

    self.indexOfFirstOnscreenSectionBeforeRotate = -1;

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(webViewFinishedLoading)
                                                 name: @"WebViewFinishedLoading"
                                               object: nil];
    
    self.unsafeToScroll = NO;
    self.unsafeToToggleTOC = NO;
    self.scrollOffset = CGPointZero;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(saveCurrentPage)
                                                 name: @"SavePage"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(searchFieldBecameFirstResponder)
                                                 name: @"SearchFieldBecameFirstResponder"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(zeroStateChanged:)
                                                 name: @"ZeroStateChanged"
                                               object: nil];

    [self fadeAlert];

    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
    
    scrollViewDragBeganVerticalOffset_ = 0.0f;
    
    // Ensure web view can appear beneath translucent nav bar when scrolled up
    for (UIView *subview in self.webView.subviews) {
        subview.clipsToBounds = NO;
    }

    // Ensure the keyboard hides if the web view is scrolled
    self.webView.scrollView.delegate = self;

    self.webView.backgroundColor = [UIColor whiteColor];

    [self.webView hideScrollGradient];

    [self reloadCurrentArticleInvalidatingCache:NO];
    
    [self setupPullToRefresh];
    
    // Restrict the web view from scrolling horizonally.
    [self.webView.scrollView addObserver: self
                              forKeyPath: @"contentSize"
                                 options: NSKeyValueObservingOptionNew
                                 context: nil];

    [self.bottomBarView addObserver:self
                         forKeyPath: @"bounds"
                            options: NSKeyValueObservingOptionNew
                            context: nil];
    
    [self tocSetupSwipeGestureRecognizers];
    
    // UIWebView has a bug which causes a black bar to appear at
    // bottom of the web view if toc quickly dragged on and offscreen.
    self.webView.opaque = NO;
    
    // This is the first view that's opened when the app opens...
    // Perform any first-time data migration as needed.
    [self migrateDataIfNecessary];
    
    
    self.bottomBarViewBottomConstraint = nil;

    // This needs to be in viewDidLoad.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(languageItemSelectedNotification:)
                                                 name: @"LanguageItemSelected"
                                               object: nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Don't move this to viewDidLoad - this is because viewDidLoad may only get
    // called very occasionally as app suspend/resume probably doesn't cause
    // viewDidLoad to fire.
    [self downloadAssetsFilesIfNecessary];

    //[self.view randomlyColorSubviews];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.bottomMenuHidden = ROOT.topMenuHidden;

    [self copyAssetsFolderToAppDataDocuments];

    ROOT.topMenuViewController.navBarMode = NAVBAR_MODE_DEFAULT;
    [ROOT.topMenuViewController updateTOCButtonVisibility];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self tocHideWithDuration:TOC_TOGGLE_ANIMATION_DURATION];
    
    [super viewWillDisappear:animated];
}

#pragma mark Copy bundled assets folder and contents to app "AppData/Documents/assets/"

-(void)copyAssetsFolderToAppDataDocuments
{
    /*
    Some files need to be bunded with releases, but potentially updated between
    releases as well. These files are placed in the bundled "assets" directory, 
    which is copied over to the "AppData/Documents/assets/" folder because the 
    bundle cannot be written to by the running app.
    
    The files in "AppData/Documents/assets/" are then accessed instead of their 
    bundled copies. This way, when newly downloaded versions overwrite the 
    "AppData/Documents/assets/" files, the new versions actually get used.

    So, this method
        - Copies bundled assets folder over to "AppData/Documents/assets/"
            if it's not already there. (Fresh app install)
     
        - Copies new files that may be added to bundle assets folder over to
            "AppData/Documents/assets/". (App update including new bundled files)
            
        - Copies files that exist in both the bundle and 
            "AppData/Documents/assets/" if the bundled file is newer. (App
            update to files which were bundled in previous release.) Note
            that when an app update is installed and the app files are written
            the creation and last modified dates of the bundled files are 
            probably changed to the current timestamp, which means these
            updated files will as a matter of course always be newer than
            any files in "AppData/Documents/assets/". In other words, the
            date comparison check in this method is probably redundant as the
            bundled file is always newer.
    */

    NSString *folderName = @"assets";
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:folderName];
    NSString *bundledPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:folderName];

    void(^copy)(NSString *, NSString *) = ^void(NSString *path1, NSString *path2) {
        NSError *error = nil;
        [[NSFileManager defaultManager] copyItemAtPath:path1 toPath:path2 error:&error];
        if (error) {
            NSLog(@"Could not copy '%@' to '%@'", path1, path2);
        }
    };

    if (![[NSFileManager defaultManager] fileExistsAtPath:documentsPath]){
        // "AppData/Documents/assets/" didn't exist so copy bundled assets folder and its contents over to "AppData/Documents/assets/"
        copy(bundledPath, documentsPath);
    }else{
        
        // "AppData/Documents/assets/" exists, so only copy new or *newer* bundled assets folder files over to "AppData/Documents/assets/"
        
        NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:bundledPath];
        NSString *fileName;
        while ((fileName = [dirEnum nextObject] )) {
            
            NSString *documentsFilePath = [documentsPath stringByAppendingPathComponent:fileName];
            NSString *bundledFilePath = [bundledPath stringByAppendingPathComponent:fileName];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:documentsFilePath]){
                // No file in "AppData/Documents/assets/" so copy from bundle
                copy(bundledFilePath, documentsFilePath);
            }else{
                // File exists in "AppData/Documents/assets/" so copy it if bundled file is newer
                NSError *error1 = nil, *error2 = nil;
                NSDictionary *fileInDocumentsAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:documentsFilePath error:&error1];
                NSDictionary *fileInBundleAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:bundledFilePath error:&error2];
                
                if (!error1 && !error1) {

                    NSDate *date1 = (NSDate*)fileInBundleAttr[NSFileModificationDate];
                    NSDate *date2 = (NSDate*)fileInDocumentsAttr[NSFileModificationDate];
                    
                    if ([date1 timeIntervalSinceDate:date2] > 0) {
                        // Bundled file is newer.

                        // Remove existing "AppData/Documents/assets/" file - otherwise the copy will fail.
                        NSError *error = nil;
                        [[NSFileManager defaultManager] removeItemAtPath:documentsFilePath error:&error];
                        
                        // Copy!
                        copy(bundledFilePath, documentsFilePath);
                    }
                }
            }
        }
    }
}

#pragma mark Sync config/ios.json if necessary

-(void)downloadAssetsFilesIfNecessary
{
    // Sync config/ios.json at most once per day.
    CGFloat maxAge = 60 * 60 * 24;

    SyncAssetsFileOp *configSyncOp =
    [[SyncAssetsFileOp alloc] initForAssetsFile: ASSETS_FILE_CONFIG
                                         maxAge: maxAge];
    
    SyncAssetsFileOp *cssSyncOp =
    [[SyncAssetsFileOp alloc] initForAssetsFile: ASSETS_FILE_CSS
                                         maxAge: maxAge];
    
    SyncAssetsFileOp *abuseFilterCssSyncOp =
    [[SyncAssetsFileOp alloc] initForAssetsFile: ASSETS_FILE_CSS_ABUSE_FILTER
                                         maxAge: maxAge];
    
    SyncAssetsFileOp *previewCssSyncOp =
    [[SyncAssetsFileOp alloc] initForAssetsFile: ASSETS_FILE_CSS_PREVIEW
                                         maxAge: maxAge];
    
    [[QueuesSingleton sharedInstance].assetsFileSyncQ cancelAllOperations];
    [[QueuesSingleton sharedInstance].assetsFileSyncQ addOperation:configSyncOp];
    [[QueuesSingleton sharedInstance].assetsFileSyncQ addOperation:cssSyncOp];
    [[QueuesSingleton sharedInstance].assetsFileSyncQ addOperation:abuseFilterCssSyncOp];
    [[QueuesSingleton sharedInstance].assetsFileSyncQ addOperation:previewCssSyncOp];
}

#pragma mark Edit section

-(void)showSectionEditor
{
    EditFunnel *funnel = [[EditFunnel alloc] init];
    [funnel logStart];

    SectionEditorViewController *sectionEditVC =
    [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"SectionEditorViewController"];

    NSManagedObjectID *articleID =
    [articleDataContext_.mainContext getArticleIDForTitle: [SessionSingleton sharedInstance].currentArticleTitle
                                                   domain: [SessionSingleton sharedInstance].currentArticleDomain];
    if (articleID) {
        Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
        
        Section *section =
        (Section *)[articleDataContext_.mainContext getEntityForName: @"Section"
                                                 withPredicateFormat: @"article == %@ AND sectionId == %@", article, @(self.sectionToEditId)];
        
        sectionEditVC.sectionID = section.objectID;
        sectionEditVC.funnel = funnel;
    }

    [ROOT pushViewController:sectionEditVC animated:YES];
}

-(void)searchFieldBecameFirstResponder
{
    [self tocHide];
}

#pragma mark Update constraints

-(void)updateViewConstraints
{
    [self tocConstrainView];
    
    [self constrainBottomMenu];
    
    [super updateViewConstraints];
}

#pragma mark Angle from velocity vector

-(CGFloat)getAngleInDegreesForVelocity:(CGPoint)velocity
{
    // Returns angle from 0 to 360 (ccw from right)
    return (atan2(velocity.y, -velocity.x) / M_PI * 180 + 180);
}

-(CGFloat)getAbsoluteHorizontalDegreesFromVelocity:(CGPoint)velocity
{
    // Returns deviation from horizontal axis in degrees.
    return (atan2(fabs(velocity.y), fabs(velocity.x)) / M_PI * 180);
}

#pragma mark Table of contents

-(BOOL)tocDrawerIsOpen
{
    return (self.webViewLeftConstraint.constant == 0) ? NO : YES;
}

-(void)tocHideIfSafeToToggleDuringNextRunLoopWithDuration:(NSNumber *)duration
{
    if(self.unsafeToToggleTOC || !self.tocVC) return;

    // iOS 6 can blank out the web view this isn't scheduled for next run loop.
    [[NSRunLoop currentRunLoop] performSelector: @selector(tocHideWithDuration:)
                                         target: self
                                       argument: duration
                                          order: 0
                                          modes: [NSArray arrayWithObject:@"NSDefaultRunLoopMode"]];
}

-(void)tocHideWithDuration:(NSNumber *)duration
{
    self.unsafeToToggleTOC = YES;

    // Clear alerts
    [self fadeAlert];

    // Ensure one exists to be hidden.
    [UIView animateWithDuration: duration.floatValue
                          delay: 0.0f
                        options: UIViewAnimationOptionBeginFromCurrentState
                     animations: ^{

                         // If the top menu isn't hidden, reveal the bottom menu.
                         if(!ROOT.topMenuHidden){
                             self.bottomMenuHidden = NO;
                             [self.view setNeedsUpdateConstraints];
                         }
                         self.webView.transform = CGAffineTransformIdentity;
                         self.bottomBarView.transform = CGAffineTransformIdentity;
                         self.webViewLeftConstraint.constant = 0;

                         [self.view layoutIfNeeded];
                     }completion: ^(BOOL done){
                         if(self.tocVC) [self tocViewControllerRemove];
                         self.unsafeToToggleTOC = NO;
                     }];
}

-(void)tocShowIfSafeToToggleDuringNextRunLoopWithDuration:(NSNumber *)duration
{
    if([[SessionSingleton sharedInstance] isCurrentArticleMain]) return;

    if(self.unsafeToToggleTOC || self.tocVC) return;

    // iOS 6 can blank out the web view this isn't scheduled for next run loop.
    [[NSRunLoop currentRunLoop] performSelector: @selector(tocShowWithDuration:)
                                         target: self
                                       argument: duration
                                          order: 0
                                          modes: [NSArray arrayWithObject:@"NSDefaultRunLoopMode"]];
}

-(void)tocShowWithDuration:(NSNumber *)duration
{
    self.unsafeToToggleTOC = YES;

    // Clear alerts
    [self fadeAlert];

    // Ensure the toc is rebuilt from scratch! Very weird toc scroll view
    // resizing issues (can't scroll up to bottom toc entry sometimes, etc)
    // when choosing different article languages otherwise!
    if(self.tocVC) [self tocViewControllerRemove];
    
    [self tocViewControllerAdd];
    
    [self.tocVC centerCellForWebViewTopMostSectionAnimated:NO];

    CGFloat webViewScale = [self tocGetWebViewScaleWhenTOCVisible];
    CGAffineTransform xf = CGAffineTransformMakeScale(webViewScale, webViewScale);

    [UIView animateWithDuration: duration.floatValue
                          delay: 0.0f
                        options: UIViewAnimationOptionBeginFromCurrentState
                     animations: ^{

                         self.bottomMenuHidden = YES;
                         [self.view setNeedsUpdateConstraints];
                         self.webView.transform = xf;
                         self.bottomBarView.transform = xf;
                         self.webViewLeftConstraint.constant = [self tocGetWidthForWebViewScale:webViewScale];
                         [self.view layoutIfNeeded];
                     }completion: ^(BOOL done){
                         [self.view setNeedsUpdateConstraints];
                         self.unsafeToToggleTOC = NO;
                     }];
}

- (void)tocViewControllerAdd
{
    self.tocVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"TOCViewController"];
    self.tocVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.tocVC.webVC = self;

    [self addChildViewController:self.tocVC];

    [self.view setNeedsUpdateConstraints];
        
    [self.view addSubview:self.tocVC.view];

    [self.tocVC didMoveToParentViewController:self];

    // Make the toc's scroll view not scroll until the swipe recognizer fails.
    [self.tocVC.scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.tocSwipeLeftRecognizer];
    [self.tocVC.scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.tocSwipeRightRecognizer];

    [self.view.superview layoutIfNeeded];
}

- (void)tocViewControllerRemove
{
    [self.tocVC willMoveToParentViewController:nil];
    [self.tocVC.view removeFromSuperview];
    [self.tocVC removeFromParentViewController];
    
    self.tocVC = nil;
}

-(void)tocHide
{
    [self tocHideIfSafeToToggleDuringNextRunLoopWithDuration:TOC_TOGGLE_ANIMATION_DURATION];
}

-(void)tocShow
{
    [self tocShowIfSafeToToggleDuringNextRunLoopWithDuration:TOC_TOGGLE_ANIMATION_DURATION];
}

-(void)tocToggle
{
    // Clear alerts
    [self fadeAlert];

    if ([self tocDrawerIsOpen]) {
        [self tocHide];
    }else{
        [self tocShow];
    }
}

-(void)tocSetupSwipeGestureRecognizers
{
    self.tocSwipeLeftRecognizer =
    [[UISwipeGestureRecognizer alloc] initWithTarget: self
                                              action: @selector(tocSwipeLeftHandler:)];
    
    self.tocSwipeRightRecognizer =
    [[UISwipeGestureRecognizer alloc] initWithTarget: self
                                              action: @selector(tocSwipeRightHandler:)];

    [self tocSetupSwipeGestureRecognizer: self.tocSwipeLeftRecognizer
                            forDirection: UISwipeGestureRecognizerDirectionLeft];

    [self tocSetupSwipeGestureRecognizer: self.tocSwipeRightRecognizer
                            forDirection: UISwipeGestureRecognizerDirectionRight];
}

-(void)tocSetupSwipeGestureRecognizer: (UISwipeGestureRecognizer *)recognizer
                         forDirection: (UISwipeGestureRecognizerDirection)direction
{
    recognizer.delegate = self;

    recognizer.direction = direction;
    
    [self.view addGestureRecognizer:recognizer];

    // Make the web view's scroll view not scroll until the swipe recognizer fails.
    [self.webView.scrollView.panGestureRecognizer requireGestureRecognizerToFail:recognizer];
    
}

-(void)tocSwipeLeftHandler:(UISwipeGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded){
        [self tocHide];
    }
}

-(void)tocSwipeRightHandler:(UISwipeGestureRecognizer *)recognizer
{
    NSString *currentArticleTitle = [SessionSingleton sharedInstance].currentArticleTitle;
    if (!currentArticleTitle || (currentArticleTitle.length == 0)) return;

    if (recognizer.state == UIGestureRecognizerStateEnded){
        [self tocShow];
    }
}

-(CGFloat)tocGetWebViewScaleWhenTOCVisible
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        return (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0.67f : 0.72f);
    }else{
        return (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0.45f : 0.65f);
    }
}

-(CGFloat)tocGetWidthForWebViewScale:(CGFloat)webViewScale
{
    return self.view.frame.size.width * (1.0f - webViewScale);
}

-(void)tocConstrainView
{
    if (!self.tocVC) return;
    
    [self.tocVC.view removeConstraintsOfViewFromView:self.view];

    CGFloat webViewScale = [self tocGetWebViewScaleWhenTOCVisible];
    
    NSDictionary *views = @{
                            @"view": self.view,
                            @"tocView": self.tocVC.view,
                            @"webView": self.webView
                            };
    
    NSDictionary *metrics = @{
                              @"tocInitialWidth": @([self tocGetWidthForWebViewScale:webViewScale])
                              };
    
    NSArray *constraints =
    @[
      @[
          [NSLayoutConstraint constraintWithItem: self.tocVC.view
                                       attribute: NSLayoutAttributeRight
                                       relatedBy: NSLayoutRelationEqual
                                          toItem: self.webView
                                       attribute: NSLayoutAttributeLeft
                                      multiplier: 1.0
                                        constant: 0]
          ]
      ,
      [NSLayoutConstraint constraintsWithVisualFormat: @"H:[tocView(==tocInitialWidth@1000)]"
                                              options: 0
                                              metrics: metrics
                                                views: views]
      ,
      [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[tocView]|"
                                              options: 0
                                              metrics: metrics
                                                views: views]
      ];
    
    [self.view addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];
}

-(CGFloat)tocGetPercentOnscreen
{
    CGFloat defaultWebViewScaleWhenTOCVisible = [self tocGetWebViewScaleWhenTOCVisible];
    CGFloat defaultTOCWidth = [self tocGetWidthForWebViewScale:defaultWebViewScaleWhenTOCVisible];
    return 1.0f - (fabsf(self.tocVC.view.frame.origin.x) / defaultTOCWidth);
}

-(void)tocScrollWebViewToPoint: (CGPoint)point
                      duration: (CGFloat)duration
                   thenHideTOC: (BOOL)hideTOC
{
    point.x = self.webView.scrollView.contentOffset.x;
    
    [UIView animateWithDuration: duration
                          delay: 0.0f
                        options: UIViewAnimationOptionBeginFromCurrentState
                     animations: ^{

                         // Not using "setContentOffset:animated:" so duration of animation
                         // can be controlled and action can be taken after animation completes.
                         self.webView.scrollView.contentOffset = point;

                     } completion:^(BOOL done){
                         
                         // Record the new scroll location.
                         [self saveWebViewScrollOffset];
                         // Toggle toc.
                         if (hideTOC) [self tocHide];
                     }];
}

#pragma mark UIContainerViewControllerCallbacks

-(BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return YES;
}

-(BOOL)shouldAutomaticallyForwardRotationMethods
{
    return YES;
}

#pragma mark KVO

-(void)observeValueForKeyPath: (NSString *)keyPath
                     ofObject: (id)object
                       change: (NSDictionary *)change
                      context: (void *)context
{
    if (
        (object == self.webView.scrollView)
        &&
        [keyPath isEqual:@"contentSize"]
        ) {
        [object preventHorizontalScrolling];
    } else if (
        (object == self.bottomBarView)
        &&
        ([keyPath isEqual:@"bounds"])
        ) {
            [self updateWebViewContentAndScrollInsets];
    }
}

#pragma mark Dealloc

-(void)dealloc
{
    [self.webView.scrollView removeObserver:self forKeyPath:@"contentSize"];
    [self.bottomBarView removeObserver:self forKeyPath:@"bounds"];

    // This needs to be in dealloc.
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"LanguageItemSelected"
                                                  object: nil];
}

#pragma mark Webview obj-c to javascript bridge

-(void)resetBridge
{
    // This needs to be called before sending a new page of html to the embedded UIWebView.
    // The bridge is the web view's delegate, and one of the web view delegate methods which
    // the bridge implements is "webViewDidFinishLoad:". This method only gets called the first
    // time a page is displayed unless the bridge is reset before beginning to send a page of
    // html. "webViewDidFinishLoad:" seems the only *reliable* way of being notified when the
    // page dom has been loaded and the web view's view had taken on the size of the content
    // it is rendering. It is only then that we can scroll to a saved article's previous
    // scroll offsets.

    // Because the bridge is a property now, rather than a private var, ARC should take care of
    // cleanup when the bridge is reset.
//TODO: confirm this comment ^
    self.bridge = [[CommunicationBridge alloc] initWithWebView:self.webView htmlFileName:@"index.html"];
    [self.bridge addListener:@"DOMLoaded" withBlock:^(NSString *messageType, NSDictionary *payload) {
        //NSLog(@"QQQ HEY DOMLoaded!");
    }];

    __weak WebViewController *weakSelf = self;
    [self.bridge addListener:@"linkClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
        NSString *href = payload[@"href"];
        
        [weakSelf tocHide];
        
        if ([href hasPrefix:@"/wiki/"]) {
            NSString *title = [href substringWithRange:NSMakeRange(6, href.length - 6)];

            [weakSelf navigateToPage: title
                              domain: [SessionSingleton sharedInstance].currentArticleDomain
                     discoveryMethod: DISCOVERY_METHOD_LINK
                   invalidatingCache: NO];
        }else if ([href hasPrefix:@"//"]) {
            href = [@"http:" stringByAppendingString:href];
            
NSString *msg = [NSString stringWithFormat:@"To do: add code for navigating to external link: %@", href];
[weakSelf.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"alert('%@')", msg]];

        } else if ([href hasPrefix:@"http:"] || [href hasPrefix:@"https:"]) {
            // A standard link.
            // TODO: make all of the stuff above parse the URL into parts
            // unless it's /wiki/ or #anchor style.
            // Then validate if it's still in Wikipedia land and branch appropriately.
            if ([SessionSingleton sharedInstance].zeroConfigState.disposition &&
                [[NSUserDefaults standardUserDefaults] boolForKey:@"ZeroWarnWhenLeaving"]) {
                weakSelf.externalUrl = href;
                UIAlertView *dialog = [[UIAlertView alloc]
                                       initWithTitle:MWLocalizedString(@"zero-interstitial-title", nil)
                                       message:MWLocalizedString(@"zero-interstitial-leave-app", nil)
                                       delegate:weakSelf
                                       cancelButtonTitle:MWLocalizedString(@"zero-interstitial-cancel", nil)
                                       otherButtonTitles:MWLocalizedString(@"zero-interstitial-continue", nil)
                                       , nil];
                [dialog show];
            } else {
                NSURL *url = [NSURL URLWithString:href];
                [[UIApplication sharedApplication] openURL:url];
            }
        }
    }];

    [self.bridge addListener:@"editClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
        [weakSelf tocHide];
        weakSelf.sectionToEditId = [payload[@"sectionId"] integerValue];

        [weakSelf showSectionEditor];
    }];
    
    [self.bridge addListener:@"langClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
        NSLog(@"Language button pushed");
        [weakSelf languageButtonPushed];
    }];
    
    [self.bridge addListener:@"nonAnchorTouchEndedWithoutDragging" withBlock:^(NSString *messageType, NSDictionary *payload) {
        NSLog(@"nonAnchorTouchEndedWithoutDragging = %@", payload);

        if (!weakSelf.tocVC) {
            if (ROOT.topMenuViewController.navBarMode != NAVBAR_MODE_SEARCH) {
                [ROOT animateTopAndBottomMenuToggle];
            }
        }

        // nonAnchorTouchEndedWithoutDragging is used so TOC may be hidden if user tapped, but did *not* drag.
        // Used because UIWebView is difficult to attach one-finger touch events to.
        [weakSelf tocHide];
    }];

    self.unsafeToScroll = NO;
    self.scrollOffset = CGPointZero;
}

#pragma mark History

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // Ensure the web VC is the top VC.
    [ROOT popToViewController:self animated:YES];

    [self fadeAlert];
}

#pragma Saved Pages

-(void)saveCurrentPage
{
    NSManagedObjectID *articleID = [articleDataContext_.mainContext getArticleIDForTitle: [SessionSingleton sharedInstance].currentArticleTitle
                                                                                  domain: [SessionSingleton sharedInstance].currentArticleDomain];
    
    if (!articleID) return;
    
    Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
    
    Saved *alreadySaved = (Saved *)[articleDataContext_.mainContext getEntityForName: @"Saved" withPredicateFormat: @"article == %@", article];
    
    NSLog(@"SAVE PAGE FOR %@, alreadySaved = %@", article.title, alreadySaved);
    if (article && !alreadySaved) {
        NSLog(@"SAVED PAGE %@", article.title);
        // Save!
        Saved *saved = [NSEntityDescription insertNewObjectForEntityForName:@"Saved" inManagedObjectContext:articleDataContext_.mainContext];
        saved.dateSaved = [NSDate date];
        [article addSavedObject:saved];
        
        NSError *error = nil;
        [articleDataContext_.mainContext save:&error];
        NSLog(@"SAVE PAGE ERROR = %@", error);
    }
}

#pragma mark Web view scroll offset recording

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if(!decelerate) [self scrollViewScrollingEnded:scrollView];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self scrollViewScrollingEnded:scrollView];
}

-(void)scrollViewScrollingEnded:(UIScrollView *)scrollView
{
    if (scrollView == self.webView.scrollView) {
        // Once we've started scrolling around don't allow the webview delegate to scroll
        // to a saved position! Super annoying otherwise.
        self.unsafeToScroll = YES;

        //[self printLiveContentLocationTestingOutputToConsole];
        //NSLog(@"%@", NSStringFromCGPoint(scrollView.contentOffset));
        [self saveWebViewScrollOffset];
        
        TOCViewController *tocVC = [self searchForChildViewControllerOfClass:[TOCViewController class]];
        if (tocVC) [tocVC centerCellForWebViewTopMostSectionAnimated:YES];

        self.pullToRefreshView.alpha = 0.0f;
    }
}

-(void)saveWebViewScrollOffset
{
    // Don't record scroll position of "main" pages.
    if ([[SessionSingleton sharedInstance] isCurrentArticleMain]) return;

    [articleDataContext_.mainContext performBlockAndWait:^(){
        // Save scroll location
        NSManagedObjectID *articleID = [articleDataContext_.mainContext getArticleIDForTitle: [SessionSingleton sharedInstance].currentArticleTitle
                                                                                      domain: [SessionSingleton sharedInstance].currentArticleDomain];
        if (articleID) {
            Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
            if (article) {
                article.lastScrollX = @(self.webView.scrollView.contentOffset.x);
                article.lastScrollY = @(self.webView.scrollView.contentOffset.y);
                NSError *error = nil;
                [articleDataContext_.mainContext save:&error];
            }
        }
    }];
}

#pragma mark Web view html content live location retrieval

-(void)printLiveContentLocationTestingOutputToConsole
{
    // Test with the top image (presently) on the San Francisco article.
    // (would test p.x and p.y against CGFLOAT_MAX to ensure good value was retrieved)
    CGPoint p = [self.webView getScreenCoordsForHtmlImageWithSrc:@"//upload.wikimedia.org/wikipedia/commons/thumb/d/da/SF_From_Marin_Highlands3.jpg/280px-SF_From_Marin_Highlands3.jpg"];
    NSLog(@"p = %@", NSStringFromCGPoint(p));

    CGPoint p2 = [self.webView getWebViewCoordsForHtmlImageWithSrc:@"//upload.wikimedia.org/wikipedia/commons/thumb/d/da/SF_From_Marin_Highlands3.jpg/280px-SF_From_Marin_Highlands3.jpg"];
    NSLog(@"p2 = %@", NSStringFromCGPoint(p2));

    // Also test location of second section on page.
    // (would test r with CGRectIsNull(r) to ensure good values were retrieved)
    CGRect r = [self.webView getScreenRectForHtmlElementWithId:@"section_heading_and_content_block_1"];
    NSLog(@"r = %@", NSStringFromCGRect(r));

    CGRect r2 = [self.webView getWebViewRectForHtmlElementWithId:@"section_heading_and_content_block_1"];
    NSLog(@"r2 = %@", NSStringFromCGRect(r2));
}

-(void)debugScrollLeadSanFranciscoArticleImageToTopLeft
{
    // Awesome! Now works regarless of pinch-zoom scale!
    CGPoint p = [self.webView getWebViewCoordsForHtmlImageWithSrc:@"//upload.wikimedia.org/wikipedia/commons/thumb/d/da/SF_From_Marin_Highlands3.jpg/280px-SF_From_Marin_Highlands3.jpg"];
    [self.webView.scrollView setContentOffset:p animated:YES];
}

#pragma mark Web view scroll offset - using it!

-(void)webViewFinishedLoading
{
    if(!self.unsafeToScroll){
        [self.webView.scrollView setContentOffset:self.scrollOffset animated:NO];
    }
    
    [self.tocVC centerCellForWebViewTopMostSectionAnimated:NO];
}

#pragma mark Scroll hiding keyboard threshold

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    /*
    // Hides nav bar when a scroll threshold is exceeded. Probably only want to do this
    // when the webView's scrollView scrolls. Probably also want to set the status bar to
    // be not transparent when the nav bar is hidden - if not possible could position a
    // view just behind it, but above the webView.
    if (scrollView == self.webView.scrollView) {
        CGFloat f = scrollViewDragBeganVerticalOffset_ - scrollView.contentOffset.y;
        if (f < -55 && ![UIApplication sharedApplication].statusBarHidden) {
            [self.navigationController setNavigationBarHidden:YES animated:YES];
            //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
            //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        }else if (f > 55 && [UIApplication sharedApplication].statusBarHidden) {
              [self.navigationController setNavigationBarHidden:NO animated:YES];
            //[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
            //[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        }
    }
    */

    // Hide the keyboard if it was visible when the results are scrolled, but only if
    // the results have been scrolled in excess of some small distance threshold first.
    // This prevents tiny scroll adjustments, which seem to occur occasionally for some
    // reason, from causing the keyboard to hide when the user is typing on it!
    CGFloat distanceScrolled = scrollViewDragBeganVerticalOffset_ - scrollView.contentOffset.y;
    CGFloat fabsDistanceScrolled = fabs(distanceScrolled);
    
    if (fabsDistanceScrolled > HIDE_KEYBOARD_ON_SCROLL_THRESHOLD) {
        [self hideKeyboard];
        //NSLog(@"Keyboard Hidden!");
    }
    
    [self updatePullToRefreshForScrollView:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    scrollViewDragBeganVerticalOffset_ = scrollView.contentOffset.y;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    [self.tocVC centerCellForWebViewTopMostSectionAnimated:NO];
    [self saveWebViewScrollOffset];
}

#pragma Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    // Do not remove the following commented toggle. It's for testing W0 stuff.
    //[[SessionSingleton sharedInstance].zeroConfigState toggleFakeZeroOn];
}

#pragma mark Article loading ops

- (void)navigateToPage: (NSString *)title
                domain: (NSString *)domain
       discoveryMethod: (ArticleDiscoveryMethod)discoveryMethod
     invalidatingCache: (BOOL)invalidateCache
{
    NSString *cleanTitle = [title wikiTitleWithoutUnderscores];
    
    // Don't try to load nothing. Core data takes exception with such nonsense.
    if (cleanTitle == nil) return;
    if (cleanTitle.length == 0) return;
    
    [self hideKeyboard];
    
    // Show loading message
    [self showAlert:MWLocalizedString(@"search-loading-section-zero", nil)];
    
    [self retrieveArticleForPageTitle: cleanTitle
                               domain: domain
                      discoveryMethod: [NAV getStringForDiscoveryMethod:discoveryMethod]
                    invalidatingCache: invalidateCache];

    // Reset the search field to its placeholder text after 5 seconds.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        TopMenuTextFieldContainer *textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
        if (!textFieldContainer.textField.isFirstResponder) textFieldContainer.textField.text = @"";
    });
}

-(void)reloadCurrentArticleInvalidatingCache:(BOOL)invalidateCache
{    
    [self navigateToPage: [SessionSingleton sharedInstance].currentArticleTitle
                  domain: [SessionSingleton sharedInstance].currentArticleDomain
         discoveryMethod: DISCOVERY_METHOD_SEARCH
       invalidatingCache: invalidateCache];
}

- (void)retrieveArticleForPageTitle: (NSString *)pageTitle
                             domain: (NSString *)domain
                    discoveryMethod: (NSString *)discoveryMethod
                  invalidatingCache: (BOOL)invalidateCache
{
    if (invalidateCache) {
        // Mark article for refreshing so its core data records will be reloaded.
        // (Needs to be done on worker context as worker context changes bubble up through
        // main context too - so web view controller accessing main context will see changes.)
        
        NSManagedObjectID *articleID =
        [articleDataContext_.mainContext getArticleIDForTitle: pageTitle
                                                       domain: domain];
        
        if (articleID) {
            [articleDataContext_.workerContext performBlockAndWait:^(){
                Article *article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];
                if (article) {
                    article.needsRefresh = @YES;
                    NSError *error = nil;
                    [articleDataContext_.workerContext save:&error];
                    NSLog(@"error = %@", error);
                }
            }];
        }
    }

    // Cancel any in-progress article retrieval operations
    [[QueuesSingleton sharedInstance].articleRetrievalQ cancelAllOperations];
    [[QueuesSingleton sharedInstance].searchQ cancelAllOperations];
    [[QueuesSingleton sharedInstance].thumbnailQ cancelAllOperations];

    __block NSManagedObjectID *articleID =
    [articleDataContext_.mainContext getArticleIDForTitle: pageTitle
                                                   domain: domain];
    BOOL needsRefresh = NO;

    if (articleID) {
        Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
        
        // If article with sections just show them (unless needsRefresh is YES)
        if (article.section.count > 0 && !article.needsRefresh.boolValue) {
            [self displayArticle:articleID mode:DISPLAY_ALL_SECTIONS];
            [self showAlert:MWLocalizedString(@"search-loading-article-loaded", nil)];
            [self fadeAlert];
            return;
        }
        needsRefresh = article.needsRefresh.boolValue;
    }

    // Retrieve remaining sections op (dependent on first section op)
    DownloadSectionsOp *remainingSectionsOp =
    [[DownloadSectionsOp alloc] initForPageTitle: pageTitle
                                          domain: [SessionSingleton sharedInstance].currentArticleDomain
                                 leadSectionOnly: NO
                                 completionBlock: ^(NSDictionary *results){
        
        // Just in case the article wasn't created during the "parent" operation.
        if (!articleID) return;
        
        // The completion block happens on non-main thread, so must get article from articleID again.
        // Because "you can only use a context on a thread when the context was created on that thread"
        // this must happen on workerContext as well (see: http://stackoverflow.com/a/6356201/135557)
        Article *article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];

        //Non-lead sections have been retreived so set needsRefresh to NO.
        article.needsRefresh = @NO;

        NSArray *sectionsRetrieved = results[@"sections"];

        for (NSDictionary *section in sectionsRetrieved) {
            if (![section[@"id"] isEqual: @0]) {
                                
                // Add sections for article
                Section *thisSection = [NSEntityDescription insertNewObjectForEntityForName:@"Section" inManagedObjectContext:articleDataContext_.workerContext];

                // Section index is a string because transclusion sections indexes will start with "T-".
                if ([section[@"index"] isKindOfClass:[NSString class]]) {
                    thisSection.index = section[@"index"];
                }

                thisSection.title = section[@"line"];

                if ([section[@"level"] isKindOfClass:[NSString class]]) {
                    thisSection.level = section[@"level"];
                }

                // Section number, from the api, can be 3.5.2 etc, so it's a string.
                if ([section[@"number"] isKindOfClass:[NSString class]]) {
                    thisSection.number = section[@"number"];
                }

                if (section[@"fromtitle"]) {
                    thisSection.fromTitle = section[@"fromtitle"];
                }

                thisSection.sectionId = section[@"id"];

                thisSection.html = section[@"text"];
                thisSection.tocLevel = section[@"toclevel"];
                thisSection.dateRetrieved = [NSDate date];
                thisSection.anchor = (section[@"anchor"]) ? section[@"anchor"] : @"";

                [article addSectionObject:thisSection];
            }
        }

        NSError *error = nil;
        [articleDataContext_.workerContext save:&error];
        
        [self displayArticle:articleID mode:DISPLAY_APPEND_NON_LEAD_SECTIONS];
        [self showAlert:MWLocalizedString(@"search-loading-article-loaded", nil)];
        [self fadeAlert];

    } cancelledBlock:^(NSError *error){
        [self fadeAlert];
    } errorBlock:^(NSError *error){
        NSString *errorMsg = error.localizedDescription;
        [self showAlert:errorMsg];
    }];

    remainingSectionsOp.delegate = self;


    // Retrieve first section op
    DownloadSectionsOp *firstSectionOp =
    [[DownloadSectionsOp alloc] initForPageTitle: pageTitle
                                          domain: [SessionSingleton sharedInstance].currentArticleDomain
                                 leadSectionOnly: YES
                                 completionBlock: ^(NSDictionary *dataRetrieved){

        Article *article = nil;

        NSString *redirectedTitle = [dataRetrieved[@"redirected"] copy];

        // Redirect if the pageTitle which triggered this call to "retrieveArticleForPageTitle"
        // differs from titleReflectingAnyRedirects.
        if (redirectedTitle.length > 0) {
            NSString *newTitle = redirectedTitle.copy;
            [self retrieveArticleForPageTitle: newTitle
                                       domain: domain
                              discoveryMethod: discoveryMethod
                            invalidatingCache: NO];
            return;
        }

        if (!articleID) {
            article = [NSEntityDescription
                insertNewObjectForEntityForName:@"Article"
                inManagedObjectContext:articleDataContext_.workerContext
            ];
            article.title = pageTitle;
            article.dateCreated = [NSDate date];
            article.site = [SessionSingleton sharedInstance].site;
            article.domain = [SessionSingleton sharedInstance].currentArticleDomain;
            article.domainName = [SessionSingleton sharedInstance].currentArticleDomainName;
            articleID = article.objectID;
        }else{
            article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];
        }

        if (needsRefresh) {
            // If and article needs refreshing remove its sections so they get reloaded too.
            for (Section *thisSection in [article.section copy]) {
                [articleDataContext_.workerContext deleteObject:thisSection];
            }
        }

        // If "needsRefresh", an existing article's data is being retrieved again, so these need
        // to be updated whether a new article record is being inserted or not as data may have
        // changed since the article record was first created.
        article.languagecount = dataRetrieved[@"languagecount"];
        article.lastmodified = dataRetrieved[@"lastmodified"];
        article.lastmodifiedby = dataRetrieved[@"lastmodifiedby"];
        article.articleId = dataRetrieved[@"articleId"];

        // Note: Because "retrieveArticleForPageTitle" recurses with the redirected-to title if
        // the lead section op determines a redirect occurred, the "redirected" value below will
        // probably never be set.
        article.redirected = dataRetrieved[@"redirected"];

        //NSDateFormatter *anotherDateFormatter = [[NSDateFormatter alloc] init];
        //[anotherDateFormatter setDateStyle:NSDateFormatterLongStyle];
        //[anotherDateFormatter setTimeStyle:NSDateFormatterShortStyle];
        //NSLog(@"formatted lastmodified = %@", [anotherDateFormatter stringFromDate:article.lastmodified]);

        // Associate thumbnail with article.
        // If search result for this pageTitle had a thumbnail url associated with it, see if
        // a core data image object exists with a matching sourceURL. If so make the article
        // thumbnailImage property point to that core data image object. This associates the
        // search result thumbnail with the article.
        
        NSArray *result = [ROOT.topMenuViewController.currentSearchResultsOrdered filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"(title == %@) AND (thumbnail.source.length > 0)", pageTitle]
        ];
        if (result.count == 1) {
            NSString *thumbURL = result[0][@"thumbnail"][@"source"];
            thumbURL = [thumbURL getUrlWithoutScheme];
            Image *thumb = (Image *)[articleDataContext_.workerContext getEntityForName: @"Image" withPredicateFormat:@"sourceUrl == %@", thumbURL];
            if (thumb) article.thumbnailImage = thumb;
        }

        article.lastScrollX = @0.0f;
        article.lastScrollY = @0.0f;

        // Get article section zero html
        NSArray *sectionsRetrieved = dataRetrieved[@"sections"];
        NSDictionary *section0Dict = (sectionsRetrieved.count >= 1) ? sectionsRetrieved[0] : nil;

        // If there was only one section then we have what we need so no refresh
        // is needed. Otherwise leave needsRefresh set to YES until subsequent sections
        // have been retrieved. Reminder: "onlyrequestedsections" is not used
        // by the mobileview query so that sectionsRetrieved.count will
        // reflect the article's total number of sections here ("sections"
        // was set to "0" though so only the first section entry actually has
        // any html). This fixes the bug which caused subsequent sections to never
        // be retrieved if the article was navigated away from before they had loaded.
        article.needsRefresh = (sectionsRetrieved.count == 1) ? @NO : @YES;

        NSString *section0HTML = @"";
        if (section0Dict && [section0Dict[@"id"] isEqual: @0] && section0Dict[@"text"]) {
            section0HTML = section0Dict[@"text"];
        }

        // Add sections for article
        Section *section0 = [NSEntityDescription insertNewObjectForEntityForName:@"Section" inManagedObjectContext:articleDataContext_.workerContext];
        // Section index is a string because transclusion sections indexes will start with "T-"
        section0.index = @"0";
        section0.level = @"0";
        section0.number = @"0";
        section0.sectionId = @0;
        section0.title = @"";
        section0.dateRetrieved = [NSDate date];
        section0.html = section0HTML;
        section0.anchor = @"";
        article.section = [NSSet setWithObjects:section0, nil];

        // Don't add multiple history items for the same article or back-forward button
        // behavior becomes a confusing mess.
        if(article.history.count == 0){
            // Add history for article
            History *history0 = [NSEntityDescription insertNewObjectForEntityForName:@"History" inManagedObjectContext:articleDataContext_.workerContext];
            history0.dateVisited = [NSDate date];
            //history0.dateVisited = [NSDate dateWithDaysBeforeNow:31];
            history0.discoveryMethod = discoveryMethod;
            [article addHistoryObject:history0];
        }

        // Save the article!
        NSError *error = nil;
        [articleDataContext_.workerContext save:&error];

        if (error) {
            NSLog(@"error = %@", error);
            NSLog(@"error = %@", error.localizedDescription);
        }

        [self displayArticle:articleID mode:DISPLAY_LEAD_SECTION];
        [self showAlert:MWLocalizedString(@"search-loading-section-remaining", nil)];

    } cancelledBlock:^(NSError *error){

        // Remove the article so it doesn't get saved.
        if (articleID) {
            Article *article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];
            [articleDataContext_.workerContext deleteObject:article];
        }

    } errorBlock:^(NSError *error){
        NSString *errorMsg = error.localizedDescription;
        [self showAlert:errorMsg];
        if (articleID) {
            // Remove the article so it doesn't get saved.
            Article *article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];
            [articleDataContext_.workerContext deleteObject:article];
        }
    }];

    firstSectionOp.delegate = self;
    
    
    // Retrieval of remaining sections depends on retrieving first section
    [remainingSectionsOp addDependency:firstSectionOp];
    
    [[QueuesSingleton sharedInstance].articleRetrievalQ addOperation:remainingSectionsOp];
    [[QueuesSingleton sharedInstance].articleRetrievalQ addOperation:firstSectionOp];
}

#pragma mark Progress report

-(void)opProgressed:(MWNetworkOp *)op;
{
    return;
    if (op.dataRetrieved.length) {
        NSLog(@"Receive progress: %lu of %lu", (unsigned long)op.dataRetrieved.length, (unsigned long)op.dataRetrievedExpectedLength);
    }else{
        NSLog(@"Send progress: %@ of %@", op.bytesWritten, op.bytesExpectedToWrite);
    }
}

#pragma mark Display article from core data

- (void)displayArticle:(NSManagedObjectID *)articleID mode:(DisplayMode)mode
{
    // Get sorted sections for this article (sorts the article.section NSSet into sortedSections)
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sectionId" ascending:YES];

    Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];

    if (!article) return;
    [SessionSingleton sharedInstance].currentArticleTitle = article.title;
    [SessionSingleton sharedInstance].currentArticleDomain = article.domain;
    MWLanguageInfo *languageInfo = [MWLanguageInfo languageInfoForCode:article.domain];

    NSNumber *langCount = article.languagecount;
    NSDate *lastModified = article.lastmodified;
    NSString *lastModifiedBy = article.lastmodifiedby;
    
    [self.bottomMenuViewController updateBottomBarButtonsEnabledState];

    [ROOT.topMenuViewController updateTOCButtonVisibility];

    NSArray *sortedSections = [article.section sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    NSMutableArray *sectionTextArray = [@[] mutableCopy];
    
    for (Section *section in sortedSections) {
        if (mode == DISPLAY_APPEND_NON_LEAD_SECTIONS) {
            if ([section isLeadSection]) continue;
        }
        if (section.html){

            [section createImageRecordsForHtmlOnContext:articleDataContext_.mainContext];

            // Structural html added around section html just before display.
            NSString *sectionHTMLWithID = [section displayHTML];

            [sectionTextArray addObject:sectionHTMLWithID];
        }
        if (mode == DISPLAY_LEAD_SECTION) break;
    }

    // Pull the scroll offset out so the article object doesn't have to be passed into the block below.
    CGPoint scrollOffset = CGPointMake(article.lastScrollX.floatValue, article.lastScrollY.floatValue);

    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        if (mode != DISPLAY_APPEND_NON_LEAD_SECTIONS) {
            // See comments inside resetBridge.
            [self resetBridge];
        }
        
        self.scrollOffset = scrollOffset;


        if ((mode != DISPLAY_LEAD_SECTION) && ![[SessionSingleton sharedInstance] isCurrentArticleMain]) {
            [sectionTextArray addObject: [self renderLanguageButtonForCount: langCount.integerValue]];
            [sectionTextArray addObject: [self renderLastModified:lastModified by:lastModifiedBy]];
        }

        
        // Join article sections text
        NSString *joint = @""; //@"<div style=\"background-color:#ffffff;height:55px;\"></div>";
        NSString *htmlStr = [sectionTextArray componentsJoinedByString:joint];
        
        // NSLog(@"languageInfo = %@", languageInfo.code);
        // Display all sections
        [self.bridge sendMessage: @"setLanguage"
                     withPayload: @{
                                   @"lang": languageInfo.code,
                                   @"dir": languageInfo.dir
                                   }];
        
        [self.bridge sendMessage:@"append" withPayload:@{@"html": htmlStr}];

        if ([self tocDrawerIsOpen]) {
            // Drawer is already open, so just refresh the toc quickly w/o animation.
            // Make sure "tocShowWithDuration:" is allowed to happen even if the TOC
            // is already onscreen or non-lead sections won't appear in the TOC when
            // they've been retrieved if the TOC is open.
            [self tocShowWithDuration:@0.0f];
        }
    }];
}

-(NSString *)renderLanguageButtonForCount:(NSInteger)count
{
    if (count > 0) {
        NSString *langCode = [[NSLocale preferredLanguages] objectAtIndex:0];
        MWLanguageInfo *lang = [MWLanguageInfo languageInfoForCode:langCode];
        NSString *dir = lang.dir;

        NSString *aa = @"<span class=\"mw-language-icon\">Aあ</span>";
        NSString *countStr = [NSString stringWithFormat:@"<span class=\"mw-language-count\">%d</span>", (int)count];
        NSString *otherLanguages = [NSString stringWithFormat:@"<span class=\"mw-language-label\">%@</span>", MWLocalizedString(@"language-button-other-languages", nil)];
        
        return [NSString stringWithFormat:@"<button dir=\"%@\" class=\"mw-language-button\"><span class=\"mw-language-items\">%@%@%@</span></button>", dir, aa, countStr, otherLanguages];
    } else {
        return @"";
    }
}

-(NSString *)renderLastModified:(NSDate *)date by:(NSString *)username
{
    NSString *langCode = [[NSLocale preferredLanguages] objectAtIndex:0];
    MWLanguageInfo *lang = [MWLanguageInfo languageInfoForCode:langCode];
    NSString *dir = lang.dir;

    NSString *ts = [WikipediaAppUtils relativeTimestamp:date];
    NSString *lm = [MWLocalizedString(@"lastmodified-timestamp", nil) stringByReplacingOccurrencesOfString:@"$1" withString:ts];
    NSString *by;
    if (username && ![username isEqualToString:@""]) {
        by = [MWLocalizedString(@"lastmodified-by", nil) stringByReplacingOccurrencesOfString:@"$1" withString:username];
    } else {
        by = MWLocalizedString(@"lastmodified-anon", nil);
    }

    return [NSString stringWithFormat:@"<div dir=\"%@\" class=\"mw-last-modified\">%@<br>%@</div>", dir, lm, by];
}

#pragma mark Scroll to last section after rotate

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    NSManagedObjectID *articleID = [articleDataContext_.mainContext getArticleIDForTitle: [SessionSingleton sharedInstance].currentArticleTitle
                                                                                  domain: [SessionSingleton sharedInstance].currentArticleDomain];
    if (articleID) {
        Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];

        self.indexOfFirstOnscreenSectionBeforeRotate = [self.webView getIndexOfTopOnScreenElementWithPrefix:@"section_heading_and_content_block_" count:article.section.count];
    }
    //self.view.alpha = 0.0f;

    [self tocHideWithDuration:@0.0f];
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [self performSelector:@selector(scrollToIndexOfFirstOnscreenSectionBeforeRotate) withObject:nil afterDelay:0.15f];
    
    [self updateWebViewContentAndScrollInsets];
}

-(void)scrollToIndexOfFirstOnscreenSectionBeforeRotate{
    if(self.indexOfFirstOnscreenSectionBeforeRotate == -1)return;
    NSString *elementId = [NSString stringWithFormat:@"section_heading_and_content_block_%ld", (long)self.indexOfFirstOnscreenSectionBeforeRotate];
    CGRect r = [self.webView getWebViewRectForHtmlElementWithId:elementId];
    if (CGRectIsNull(r)) return;
    CGPoint p = r.origin;
    p.x = self.webView.scrollView.contentOffset.x;
    [self.webView.scrollView setContentOffset:p animated:NO];

    [self.tocVC centerCellForWebViewTopMostSectionAnimated:NO];
}

#pragma mark Wikipedia Zero handling

-(void)zeroStateChanged: (NSNotification*) notification
{
    [[QueuesSingleton sharedInstance].zeroRatedMessageStringQ cancelAllOperations];

    if ([[[notification userInfo] objectForKey:@"state"] boolValue]) {
        DownloadWikipediaZeroMessageOp *zeroMessageRetrievalOp =
        [
         [DownloadWikipediaZeroMessageOp alloc]
         initForDomain: [SessionSingleton sharedInstance].currentArticleDomain
         completionBlock: ^(NSString *message) {
         
             if (message) {
                 dispatch_async(dispatch_get_main_queue(), ^(){
                 
                     TopMenuTextFieldContainer *textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
                     textFieldContainer.textField.placeholder = MWLocalizedString(@"search-field-placeholder-text-zero", nil);

                     self.zeroStatusLabel.text = message;
                     self.zeroStatusLabel.padding = UIEdgeInsetsMake(3, 10, 3, 10);
                     self.zeroStatusLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.93];

                     [self showAlert:message];
                     [NAV promptFirstTimeZeroOnWithMessageIfAppropriate:message];
                 });
             }
         } cancelledBlock:^(NSError *errorCancel) {
             NSLog(@"error w0 cancel");
         } errorBlock:^(NSError *errorError) {
             NSLog(@"error w0 error");
         }];

        [[QueuesSingleton sharedInstance].zeroRatedMessageStringQ addOperation:zeroMessageRetrievalOp];
        
    } else {
    
        TopMenuTextFieldContainer *textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
        textFieldContainer.textField.placeholder = MWLocalizedString(@"search-field-placeholder-text", nil);
        NSString *warnVerbiage = MWLocalizedString(@"zero-charged-verbiage", nil);

        self.zeroStatusLabel.text = warnVerbiage;
        self.zeroStatusLabel.backgroundColor = [UIColor redColor];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.zeroStatusLabel.text = @"";
            self.zeroStatusLabel.padding = UIEdgeInsetsZero;
        });

        [self showAlert:warnVerbiage];
        [NAV promptFirstTimeZeroOffIfAppropriate];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (1 == buttonIndex) {
        NSURL *url = [NSURL URLWithString:self.externalUrl];
        [[UIApplication sharedApplication] openURL:url];
    }
}

#pragma mark Pull to refresh

-(void)setupPullToRefresh
{
    self.pullToRefreshLabel = [[UILabel alloc] init];
    self.pullToRefreshLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.pullToRefreshLabel.backgroundColor = [UIColor clearColor];
    self.pullToRefreshLabel.textAlignment = NSTextAlignmentCenter;
    self.pullToRefreshLabel.numberOfLines = 2;
    self.pullToRefreshLabel.font = [UIFont systemFontOfSize:10];
    self.pullToRefreshLabel.textColor = [UIColor darkGrayColor];
    
    self.pullToRefreshView = [[UIView alloc] init];
    self.pullToRefreshView.alpha = 0.0f;
    self.pullToRefreshView.backgroundColor = [UIColor clearColor];
    self.pullToRefreshView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.pullToRefreshView];
    [self.pullToRefreshView addSubview:self.pullToRefreshLabel];
    
    [self constrainPullToRefresh];
}

-(void)constrainPullToRefresh
{
    self.pullToRefreshViewBottomConstraint =
        [NSLayoutConstraint constraintWithItem: self.pullToRefreshView
                                     attribute: NSLayoutAttributeBottom
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: self.view
                                     attribute: NSLayoutAttributeTop
                                    multiplier: 1.0
                                      constant: 0];
    
    NSDictionary *viewsDictionary = @{
                                      @"pullToRefreshView": self.pullToRefreshView,
                                      @"pullToRefreshLabel": self.pullToRefreshLabel,
                                      @"selfView": self.view
                                      };
    
    NSArray *viewConstraintArrays =
        @[
          [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[pullToRefreshView]|"
                                                  options: 0
                                                  metrics: nil
                                                    views: viewsDictionary],
          @[self.pullToRefreshViewBottomConstraint],
          [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-[pullToRefreshLabel]-|"
                                                  options: 0
                                                  metrics: nil
                                                    views: viewsDictionary],
          [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[pullToRefreshLabel]|"
                                                  options: 0
                                                  metrics: nil
                                                    views: viewsDictionary],
          ];
    
    [self.view addConstraints:[viewConstraintArrays valueForKeyPath:@"@unionOfArrays.self"]];
}

- (void)updatePullToRefreshForScrollView:(UIScrollView *)scrollView
{
    CGFloat pullDistance = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) ? 85.0f : 55.0f;

    UIGestureRecognizerState state = ((UIPinchGestureRecognizer *)scrollView.pinchGestureRecognizer).state;

    NSString *title = [SessionSingleton sharedInstance].currentArticleTitle;

    BOOL safeToShow =
        (!scrollView.decelerating)
        &&
        ([QueuesSingleton sharedInstance].articleRetrievalQ.operationCount == 0)
        &&
        (![self tocDrawerIsOpen])
        &&
        (state == UIGestureRecognizerStatePossible)
        &&
        (title && (title.length > 0))
    ;

    //NSLog(@"%@", NSStringFromCGPoint(scrollView.contentOffset));
    if ((scrollView.contentOffset.y < 0.0f)){

        self.pullToRefreshViewBottomConstraint.constant = -scrollView.contentOffset.y;
        //self.pullToRefreshViewBottomConstraint.constant = -(fmaxf(scrollView.contentOffset.y, -self.pullToRefreshView.frame.size.height));

        if (safeToShow) {
            self.pullToRefreshView.alpha = 1.0f;
        }

        NSString *lineOneText = @"";
        NSString *lineTwoText = MWLocalizedString(@"article-pull-to-refresh-prompt", nil);

        if (scrollView.contentOffset.y > -(pullDistance * 0.35)){
            lineOneText = @"▫︎ ▫︎ ▫︎ ▫︎ ▫︎";
        }else if (scrollView.contentOffset.y > -(pullDistance * 0.52)){
            lineOneText = @"▫︎ ▫︎ ▪︎ ▫︎ ▫︎";
        }else if (scrollView.contentOffset.y > -(pullDistance * 0.7)){
            lineOneText = @"▫︎ ▪︎ ▪︎ ▪︎ ▫︎";
        }else if (scrollView.contentOffset.y > -pullDistance){
            lineOneText = @"▫︎ ▪︎ ▪︎ ▪︎ ▫︎";
        }else{
            lineOneText = @"▪︎ ▪︎ ▪︎ ▪︎ ▪︎";
            lineTwoText = MWLocalizedString(@"article-pull-to-refresh-is-refreshing", nil);
        }

        self.pullToRefreshLabel.text = [NSString stringWithFormat:@"%@\n%@", lineOneText, lineTwoText];
    }

    if (scrollView.contentOffset.y < -pullDistance) {
        if (safeToShow) {
            
            //NSLog(@"REFRESH NOW!!!!!");
            
            [self reloadCurrentArticleInvalidatingCache:YES];
            
            [UIView animateWithDuration: 0.3f
                                  delay: 0.6f
                                options: UIViewAnimationOptionTransitionNone
                             animations: ^{
                                 self.pullToRefreshView.alpha = 0.0f;
                                 self.pullToRefreshViewBottomConstraint.constant = 0;
                                 [self.view layoutIfNeeded];
                                 scrollView.panGestureRecognizer.enabled = NO;
                             } completion: ^(BOOL done){
                                 scrollView.panGestureRecognizer.enabled = YES;
                             }];
        }
    }
}

#pragma mark Data migration

- (void)migrateDataIfNecessary
{
    DataMigrator *dataMigrator = [[DataMigrator alloc] init];
    if ([dataMigrator hasData]) {
        NSLog(@"Old data to migrate found!");
        NSArray *titles = [dataMigrator extractSavedPages];
        ArticleImporter *importer = [[ArticleImporter alloc] init];
        
        for (NSDictionary *item in titles) {
            NSLog(@"Will import saved page: %@ %@", item[@"lang"], item[@"title"]);
        }
        
        [importer importArticles:titles];
        
        [dataMigrator removeOldData];
    } else {
        NSLog(@"No old data to migrate.");
    }

}

#pragma mark Bottom menu bar

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString: @"BottomMenuViewController_embed2"]) {
		self.bottomMenuViewController = (BottomMenuViewController *) [segue destinationViewController];
	}
}

-(void)setBottomMenuHidden:(BOOL)bottomMenuHidden
{
    if (self.bottomMenuHidden == bottomMenuHidden) return;

    _bottomMenuHidden = bottomMenuHidden;

    // Fade out the top menu when it is hidden.
    CGFloat alpha = bottomMenuHidden ? 0.0 : 1.0;
    
    self.bottomBarView.alpha = alpha;

    [self updateWebViewContentAndScrollInsets];
}

-(void)constrainBottomMenu
{
    // If visible, constrain bottom of bottomNavBar to bottom of superview.
    // If hidden, constrain top of bottomNavBar to bottom of superview.

    if (self.bottomBarViewBottomConstraint) {
        [self.view removeConstraint:self.bottomBarViewBottomConstraint];
    }

    self.bottomBarViewBottomConstraint =
    [NSLayoutConstraint constraintWithItem: self.bottomBarView
                                      attribute: ((self.bottomMenuHidden) ? NSLayoutAttributeTop : NSLayoutAttributeBottom)
                                      relatedBy: NSLayoutRelationEqual
                                         toItem: self.view
                                      attribute: NSLayoutAttributeBottom
                                     multiplier: 1.0
                                       constant: 0];

    [self.view addConstraint:self.bottomBarViewBottomConstraint];
}

-(void)updateWebViewContentAndScrollInsets
{
    // Ensure web view can be scrolled to bottom and that scroll indicator doesn't underlap
    // bottom menu.
    CGFloat bottomBarHeight = self.bottomBarView.bounds.size.height;
    if(self.bottomBarView.alpha == 0) bottomBarHeight = 0;
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, bottomBarHeight, 0);
    self.webView.scrollView.contentInset = insets;
    self.webView.scrollView.scrollIndicatorInsets = insets;
}

#pragma mark Languages

-(void)languageButtonPushed
{
    [self performModalSequeWithID: @"modal_segue_show_languages"
                  transitionStyle: UIModalTransitionStyleCoverVertical
                            block: ^(LanguagesTableVC *languagesTableVC){
                                languagesTableVC.downloadLanguagesForCurrentArticle = YES;
                                languagesTableVC.invokingVC = self;
                            }];
}

- (void)languageItemSelectedNotification:(NSNotification *)notification
{
    // Ensure action is only taken if the web view controller presented the lang picker.
    LanguagesTableVC *languagesTableVC = notification.object;
    if (languagesTableVC.invokingVC != self) return;

    NSDictionary *selectedLangInfo = [notification userInfo];

    [NAV loadArticleWithTitle: selectedLangInfo[@"*"]
                       domain: selectedLangInfo[@"code"]
                     animated: NO
              discoveryMethod: DISCOVERY_METHOD_SEARCH
            invalidatingCache: NO];

    [self dismissLanguagePicker];
}

-(void)dismissLanguagePicker
{
    [self.presentedViewController dismissViewControllerAnimated: YES
                                                     completion: ^{}];
}

@end
