//
//  ViewController.m
//  Wikipedia-iOS
//
//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!
//

#import "Defines.h"
#import "WebViewController.h"
#import "CommunicationBridge.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "NSString+Extras.h"
#import "SearchBarTextField.h"
#import "ArticleCoreDataObjects.h"
#import "ArticleDataContextSingleton.h"
#import "HistoryViewController.h"
#import "NSDate-Utilities.h"
#import "SessionSingleton.h"
#import "NSManagedObjectContext+SimpleFetch.h"
#import "AlertLabel.h"
#import "UIWebView+Reveal.h"
#import "SearchNavController.h"
#import "QueuesSingleton.h"
#import "SearchResultsController.h"
#import "MainMenuTableViewController.h"
#import "TFHpple.h"
#import "TOCViewController.h"
#import "UIWebView+ElementLocation.h"
#import "SectionEditorViewController.h"

#define WEB_VIEW_SCALE_WHEN_TOC_VISIBLE (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0.45f : 0.70f)
#define TOC_TOGGLE_ANIMATION_DURATION 0.35f

@interface WebViewController (){

}

@property (strong, nonatomic) SearchResultsController *searchResultsController;
@property (strong, nonatomic) MainMenuTableViewController *mainMenuTableViewController;
@property (strong, nonatomic) CommunicationBridge *bridge;
@property (weak, nonatomic) SearchNavController *searchNavController;
@property (nonatomic) CGPoint scrollOffset;
@property (nonatomic) BOOL unsafeToScroll;
@property (nonatomic) NSInteger indexOfFirstOnscreenSectionBeforeRotate;
@property (strong, nonatomic) NSDictionary *adjacentHistoryArticleTitles;
@property (nonatomic) BOOL tocVisible;
@property (nonatomic) BOOL sectionEditingVisible;
@property (nonatomic) NSUInteger sectionToEditIndex;
@property (strong, nonatomic) NSMutableArray *tocConstraints;

@end

#pragma mark Internal variables

@implementation WebViewController {
    CGFloat scrollViewDragBeganVerticalOffset_;
    ArticleDataContextSingleton *articleDataContext_;
}

#pragma mark Network activity indicator methods

-(void)networkActivityIndicatorPush
{
    dispatch_async(dispatch_get_main_queue(), ^(){
        // Show status bar spinner
        [[MWNetworkActivityIndicatorManager sharedManager] show];
    });
}

-(void)networkActivityIndicatorPop
{
    dispatch_async(dispatch_get_main_queue(), ^(){
        // Hide status bar spinner
        [[MWNetworkActivityIndicatorManager sharedManager] hide];
    });
}

#pragma mark View lifecycle methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tocConstraints = [@[] mutableCopy];
    self.sectionToEditIndex = 0;

    self.tocVisible = NO;
    self.sectionEditingVisible = NO;
    self.forwardButton.transform = CGAffineTransformMakeScale(-1.0, 1.0);

    self.searchNavController = (SearchNavController *)self.navigationController;
    self.indexOfFirstOnscreenSectionBeforeRotate = 0;

    self.searchResultsController = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"SearchResultsController"];
    self.searchResultsController.webViewController = self;
    self.searchResultsController.searchNavController = self.searchNavController;

    self.mainMenuTableViewController = nil;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webViewFinishedLoading) name:@"WebViewFinishedLoading" object:nil];
    self.unsafeToScroll = NO;
    self.scrollOffset = CGPointZero;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainMenuToggle) name:@"MainMenuToggle" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(historyToggle) name:@"HistoryToggle" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveCurrentPage) name:@"SavePage" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(savedPagesToggle) name:@"SavedPagesToggle" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchFieldBecameFirstResponder) name:@"SearchFieldBecameFirstResponder" object:nil];

    self.alertLabel.text = @"";

    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
    
    scrollViewDragBeganVerticalOffset_ = 0.0f;
    
    // Ensure web view can appear beneath translucent nav bar when scrolled up
    for (UIView *subview in self.webView.subviews) {
        subview.clipsToBounds = NO;
    }

    // Ensure the keyboard hides if the web view is scrolled
    self.webView.scrollView.delegate = self;

    // Observe chages to the search box search term.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchStringChanged) name:@"SearchStringChanged" object:nil];

    [self updateBottomBarButtonsEnabledState];
}

#pragma mark Edit section

-(BOOL)sectionEditingVisible
{
    SectionEditorViewController *sectionEditVC = [self getSectionEditorViewController];
    return (sectionEditVC) ? YES : NO;
}

-(SectionEditorViewController *)getSectionEditorViewController
{
    for (UIViewController *childVC in self.childViewControllers) {
        if([childVC isMemberOfClass:[SectionEditorViewController class]]){
            return (SectionEditorViewController *)childVC;
        }
    }
    return nil;
}

-(void)setSectionEditingVisible:(BOOL)sectionEditingVisible
{
    BOOL _sectionEditingVisible = self.sectionEditingVisible;
    
    if(_sectionEditingVisible != sectionEditingVisible){
        _sectionEditingVisible = sectionEditingVisible;
        
        SectionEditorViewController *sectionEditVC = [self getSectionEditorViewController];
        
        // Hide section editor.
        if(!sectionEditingVisible){
            // Ensure one exists to be hidden.
            if (sectionEditVC) {
                [sectionEditVC.view removeFromSuperview];
                [sectionEditVC removeFromParentViewController];
            }
        }else{
            // Show section editor.
            // Ensure it doesn't already exist.
            if (!sectionEditVC) {
                sectionEditVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"SectionEditorViewController"];

                NSManagedObjectID *articleID = [articleDataContext_.mainContext getArticleIDForTitle:[self getCurrentArticleTitle]];
                
                Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];
                
                Section *section = (Section *)[articleDataContext_.mainContext getEntityForName: @"Section" withPredicateFormat:@"article == %@ AND index == %@", article, @(self.sectionToEditIndex)];
                
                sectionEditVC.sectionID = section.objectID;

                [self addChildViewController:sectionEditVC];

                sectionEditVC.view.translatesAutoresizingMaskIntoConstraints = NO;
                [self.view addSubview:sectionEditVC.view];

                [self.view addConstraints:
                    [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sectionEditorView]|" options:0 metrics:nil views:@{@"sectionEditorView":sectionEditVC.view}]
                ];

                [self.view addConstraints:
                    [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sectionEditorView]|" options:0 metrics:nil views:@{@"sectionEditorView":sectionEditVC.view}]
                ];
                
                [sectionEditVC didMoveToParentViewController:self];
            }
        }
    }
}

-(void)searchFieldBecameFirstResponder
{
    self.tocVisible = NO;
    self.sectionEditingVisible = NO;
}

#pragma mark Table of contents

-(TOCViewController *)getTOCViewController
{
    for (UIViewController *childVC in self.childViewControllers) {
        if([childVC isMemberOfClass:[TOCViewController class]]){
            return (TOCViewController *)childVC;
        }
    }
    return nil;
}

-(void)setTocVisible:(BOOL)tocVisible
{
    if(_tocVisible != tocVisible){
        _tocVisible = tocVisible;
        
        TOCViewController *tocVC = [self getTOCViewController];
        
        // Hide toc.
        if(!tocVisible){
            // Ensure one exists to be hidden.
            if (tocVC) {
                [UIView animateWithDuration:TOC_TOGGLE_ANIMATION_DURATION animations:^{
                    self.webView.transform = CGAffineTransformIdentity;
                    self.webViewLeftConstraint.constant = 0;
                    self.bottomBarViewBottomConstraint.constant = 0;
                    [self.view layoutIfNeeded];
                } completion:^(BOOL done){
                    [tocVC.view removeFromSuperview];
                    [tocVC removeFromParentViewController];
                }];
            }
        }else{
            // Show toc.
            // Ensure it doesn't already exist. Needed because the animation for "hide" case
            // above takes some time to complete - just to be safe.
            if (!tocVC) {
                tocVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"TOCViewController"];
                tocVC.webVC = self;
                [self addChildViewController:tocVC];
                
                tocVC.view.translatesAutoresizingMaskIntoConstraints = NO;
                [self.view addSubview:tocVC.view];
                
                [self constrainTOCView:tocVC.view];
                [self.view layoutIfNeeded];
                
                [tocVC didMoveToParentViewController:self];
                
                CGAffineTransform xf = CGAffineTransformMakeScale(WEB_VIEW_SCALE_WHEN_TOC_VISIBLE, WEB_VIEW_SCALE_WHEN_TOC_VISIBLE);
                [UIView animateWithDuration:TOC_TOGGLE_ANIMATION_DURATION animations:^{
                    self.bottomBarViewBottomConstraint.constant = -self.bottomBarViewHeightConstraint.constant;
                    self.webView.transform = xf;
                    self.webViewLeftConstraint.constant = self.view.frame.size.width * (1.0f - WEB_VIEW_SCALE_WHEN_TOC_VISIBLE);
                    [self.view layoutIfNeeded];
                }];
            }
        }
    }
}

-(void)tocToggle
{
    self.tocVisible = !self.tocVisible;
}

-(void)constrainTOCView:(UIView *)tocView
{
    [self.view removeConstraints:self.tocConstraints];
    [self.tocConstraints removeAllObjects];

    NSLayoutConstraint *constraint = nil;
    
    constraint = [NSLayoutConstraint constraintWithItem:tocView
                                              attribute:NSLayoutAttributeTop
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view
                                              attribute:NSLayoutAttributeTop
                                             multiplier:1.0
                                               constant:0];
    [self.view addConstraint:constraint];
    [self.tocConstraints addObject:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:tocView
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view
                                              attribute:NSLayoutAttributeBottom
                                             multiplier:1.0
                                               constant:0];
    [self.view addConstraint:constraint];
    [self.tocConstraints addObject:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:tocView
                                              attribute:NSLayoutAttributeRight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.webView
                                              attribute:NSLayoutAttributeLeft
                                             multiplier:1.0
                                               constant:0];
    [self.view addConstraint:constraint];
    [self.tocConstraints addObject:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:tocView
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.webView
                                              attribute:NSLayoutAttributeWidth
                                             multiplier:1.0f - WEB_VIEW_SCALE_WHEN_TOC_VISIBLE
                                               constant:0];
    [self.view addConstraint:constraint];
    [self.tocConstraints addObject:constraint];
}

-(BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    // This method is called to determine whether to
    // automatically forward appearance-related containment
    //  callbacks to child view controllers.
    return YES;
    
}
-(BOOL)shouldAutomaticallyForwardRotationMethods
{
    // This method is called to determine whether to
    // automatically forward rotation-related containment
    // callbacks to child view controllers.
    return YES;
}

#pragma mark Search terms changes

-(void)searchStringChanged
{
    // If search results table not on top of nav stack push on to nav stack.
    if (![self.navigationController.topViewController isMemberOfClass:[SearchResultsController class]]) {
        [self.navigationController pushViewController:self.searchResultsController animated:NO];
    }
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
    self.bridge = [[CommunicationBridge alloc] initWithWebView:self.webView];
    [self.bridge addListener:@"DOMLoaded" withBlock:^(NSString *messageType, NSDictionary *payload) {
        //NSLog(@"QQQ HEY DOMLoaded!");
    }];

    __weak WebViewController *weakSelf = self;
    [self.bridge addListener:@"linkClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
        NSString *href = payload[@"href"];
        
        weakSelf.tocVisible = NO;
        
        if ([href hasPrefix:@"/wiki/"]) {
            NSString *title = [href substringWithRange:NSMakeRange(6, href.length - 6)];
            [weakSelf navigateToPage:title discoveryMethod:DISCOVERY_METHOD_LINK];
        }else if ([href hasPrefix:@"//"]) {
            href = [@"http:" stringByAppendingString:href];
            
NSString *msg = [NSString stringWithFormat:@"To do: add code for navigating to external link: %@", href];
[weakSelf.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"alert('%@')", msg]];

        }
    }];

    [self.bridge addListener:@"editClicked" withBlock:^(NSString *messageType, NSDictionary *payload) {
        weakSelf.tocVisible = NO;
        weakSelf.sectionToEditIndex = [[payload[@"href"] stringByReplacingOccurrencesOfString:@"edit_section_" withString:@""] integerValue];

        weakSelf.sectionEditingVisible = YES;
    }];

    [self.bridge addListener:@"nonAnchorTouchEndedWithoutDragging" withBlock:^(NSString *messageType, NSDictionary *payload) {
        NSLog(@"nonAnchorTouchEndedWithoutDragging = %@", payload);
        // nonAnchorTouchEndedWithoutDragging is used so TOC may be hidden if user tapped, but did *not* drag.
        // Used because UIWebView is difficult to attach one-finger touch events to.
        weakSelf.tocVisible = NO;
    }];

    self.unsafeToScroll = NO;
    self.scrollOffset = CGPointZero;
}

#pragma mark Loading last-viewed article on app start

-(void)setLastViewedArticleTitle:(NSString *)lastViewedArticleTitle
{
    [[NSUserDefaults standardUserDefaults] setObject:lastViewedArticleTitle forKey:@"LastViewedArticleTitle"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)getLastViewedArticleTitle
{
    NSString *lastViewedArticleTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastViewedArticleTitle"];
    return lastViewedArticleTitle;
}

-(void)setCurrentArticleTitle:(NSString *)currentArticleTitle
{
    [[NSUserDefaults standardUserDefaults] setObject:currentArticleTitle forKey:@"CurrentArticleTitle"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)getCurrentArticleTitle
{
    NSString *currentArticleTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentArticleTitle"];
    return currentArticleTitle;
}

-(void)viewDidAppear:(BOOL)animated
{
    // Should be ok to call "navigateToPage:" on viewDidAppear because it contains logic preventing
    // reloads of pages already being displayed.

    NSString *title = [self getCurrentArticleTitle];
    if (!title) title = [self getLastViewedArticleTitle];
    
    [self navigateToPage:title discoveryMethod:DISCOVERY_METHOD_SEARCH];
}

#pragma mark History

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // Ensure the web VC is the top VC.
    [self.navigationController popToViewController:self animated:YES];

    self.alertLabel.hidden = YES;
}

-(void)mainMenuToggle
{
    UIViewController *topVC = self.navigationController.topViewController;
    if(topVC == self.mainMenuTableViewController){
        [self.navigationController popToViewController:self animated:NO];
        self.mainMenuTableViewController = nil;
        return;
    }
    if(topVC != self){
        [self.navigationController popToViewController:self animated:NO];
    }
    
    self.tocVisible = NO;

    self.mainMenuTableViewController = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"MainMenuTableViewController"];
    [self.navigationController pushViewController:self.mainMenuTableViewController animated:NO];
}

-(void)historyToggle
{
    if(self.navigationController.topViewController != self){
        // Hide if it's already showing.
        [self.navigationController popToViewController:self animated:YES];
        return;
    }
    
    //self.searchNavController.searchField.text = @"";
    [self.searchNavController resignSearchFieldFirstResponder];
    [self performSegueWithIdentifier:@"ShowHistorySegue" sender:self];
}

#pragma Saved Pages

-(void)saveCurrentPage
{
    NSManagedObjectID *articleID = [articleDataContext_.mainContext getArticleIDForTitle:[self getCurrentArticleTitle]];
    
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

-(void)savedPagesToggle
{
    if(self.navigationController.topViewController != self){
        // Hide if it's already showing.
        [self.navigationController popToViewController:self animated:YES];
        return;
    }
    
    [self.searchNavController resignSearchFieldFirstResponder];
    [self performSegueWithIdentifier:@"ShowSavedPagesSegue" sender:self];
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
        
        for (UIViewController *childVC in self.childViewControllers) {
            if([childVC isMemberOfClass:[TOCViewController class]]){
                TOCViewController *vc = (TOCViewController *)childVC;
                [vc centerCellForWebViewTopMostSection];
                break;
            }
        }
    }
}

-(void)saveWebViewScrollOffset
{
    [articleDataContext_.mainContext performBlockAndWait:^(){
        // Save scroll location
        NSManagedObjectID *articleID = [articleDataContext_.mainContext getArticleIDForTitle:[self getCurrentArticleTitle]];
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
    CGRect r = [self.webView getScreenRectForHtmlElementWithId:@"content_block_1"];
    NSLog(@"r = %@", NSStringFromCGRect(r));

    CGRect r2 = [self.webView getWebViewRectForHtmlElementWithId:@"content_block_1"];
    NSLog(@"r2 = %@", NSStringFromCGRect(r2));
}

-(void)debugScrollLeadSanFranciscoArticleImageToTopLeft
{
    // Awesome! Now works regarless of pinch-zoom scale!
    CGPoint p = [self.webView getWebViewCoordsForHtmlImageWithSrc:@"//upload.wikimedia.org/wikipedia/commons/thumb/d/da/SF_From_Marin_Highlands3.jpg/280px-SF_From_Marin_Highlands3.jpg"];
    [self.webView.scrollView setContentOffset:p animated:YES];
}

#pragma mark Image section associations

-(void)createSectionImageRecordsForSectionHtml:(NSManagedObjectID *)sectionID onContext:(NSManagedObjectContext *)context
{
    // Parse the section html extracting the image urls (in order)
    // See: http://www.raywenderlich.com/14172/how-to-parse-html-on-ios
    // for TFHpple details.
    
    // createSectionImageRecordsForSectionHtml needs to be called *after* article
    // record created but before section html sent across bridge.

    [context performBlockAndWait:^(){
        Section *section = (Section *)[context objectWithID:sectionID];
        
        NSData *sectionHtmlData = [section.html dataUsingEncoding:NSUTF8StringEncoding];
        TFHpple *sectionParser = [TFHpple hppleWithHTMLData:sectionHtmlData];
        //NSString *imageXpathQuery = @"//img[@src]";
        NSString *imageXpathQuery = @"//img[@src][not(ancestor::table[@class='navbox'])]";
        // ^ the navbox exclusion prevents images from the hidden navbox table from appearing
        // in the last section's TOC cell.

        NSArray *imageNodes = [sectionParser searchWithXPathQuery:imageXpathQuery];
        NSUInteger imageIndexInSection = 0;

        for (TFHppleElement *imageNode in imageNodes) {

            NSString *height = imageNode.attributes[@"height"];
            NSString *width = imageNode.attributes[@"width"];

            if (
                height.integerValue < THUMBNAIL_MINIMUM_SIZE_TO_CACHE.width
                ||
                width.integerValue < THUMBNAIL_MINIMUM_SIZE_TO_CACHE.height
                )
            {
                //NSLog(@"SKIPPING - IMAGE TOO SMALL");
                continue;
            }
            
            NSString *alt = imageNode.attributes[@"alt"];
            NSString *src = imageNode.attributes[@"src"];

            Image *image = (Image *)[context getEntityForName: @"Image" withPredicateFormat:@"sourceUrl == %@", src];
            
            if (image) {
                // If Image record already exists, update its attributes.
                image.alt = alt;
                image.height = @(height.integerValue);
                image.width = @(width.integerValue);
            }else{
                // If no Image record, create one setting its "data" attribute to nil. This allows the record to be
                // created so it can be associated with the section in which this , then when the URLCache intercepts the request for this image
                image = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:context];

                /*
                 Moved imageData into own entity:
                    "For small to modest sized BLOBs (and CLOBs), you should create a separate
                    entity for the data and create a to-one relationship in place of the attribute."
                    See: http://stackoverflow.com/a/9288796/135557
                 
                 This allows core data to lazily load the image blob data only when it's needed.
                 */
                image.imageData = [NSEntityDescription insertNewObjectForEntityForName:@"ImageData" inManagedObjectContext:context];

                image.imageData.data = [[NSData alloc] init];
                image.dataSize = @(image.imageData.data.length);
                image.fileName = [src lastPathComponent];
                image.fileNameNoSizePrefix = [image.fileName getWikiImageFileNameWithoutSizePrefix];
                image.extension = [src pathExtension];
                image.imageDescription = nil;
                image.sourceUrl = src;
                image.dateRetrieved = [NSDate date];
                image.dateLastAccessed = [NSDate date];
                image.width = @(width.integerValue);
                image.height = @(height.integerValue);
                image.mimeType = [image.extension getImageMimeTypeForExtension];
            }
            
            // If imageSection doesn't already exist with the same index and image, create sectionImage record
            // associating the image record (from line above) with section record and setting its index to the
            // order from img tag parsing.
            SectionImage *sectionImage = (SectionImage *)[context getEntityForName: @"SectionImage"
                                                                       withPredicateFormat: @"section == %@ AND index == %@ AND image.sourceUrl == %@",
                                      section, @(imageIndexInSection), src
                                      ];
            if (!sectionImage) {
                sectionImage = [NSEntityDescription insertNewObjectForEntityForName:@"SectionImage" inManagedObjectContext:context];
                sectionImage.image = image;
                sectionImage.index = @(imageIndexInSection);
                sectionImage.section = section;
            }
            imageIndexInSection ++;
        }

        NSError *error = nil;
        [context save:&error];
        if (error) {
            NSLog(@"\n\nerror = %@\n\n", error);
            NSLog(@"\n\nerror = %@\n\n", error.localizedDescription);
        }
    }];
}

#pragma mark Web view scroll offset - using it!

-(void)webViewFinishedLoading
{
    if(!self.unsafeToScroll){
        [self.webView.scrollView setContentOffset:self.scrollOffset animated:NO];
    }
    [self.webView reveal];
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
        if (f < -55 && !self.navigationController.navigationBarHidden) {
            [self.navigationController setNavigationBarHidden:YES animated:YES];
            //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        }else if (f > 55 && self.navigationController.navigationBarHidden) {
            [self.navigationController setNavigationBarHidden:NO animated:YES];
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
        [self.searchNavController resignSearchFieldFirstResponder];
        //NSLog(@"Keyboard Hidden!");
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    scrollViewDragBeganVerticalOffset_ = scrollView.contentOffset.y;
}

#pragma Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSString *)cleanTitle:(NSString *)title
{
    return [title stringByReplacingOccurrencesOfString:@"_" withString:@" "];
}

#pragma mark Article loading ops

- (void)navigateToPage:(NSString *)title discoveryMethod:(NSString *)discoveryMethod
{
    static BOOL isFirstArticle = YES;

    NSString *cleanTitle = [self cleanTitle:title];
    
    // Don't try to load nothing. Core data takes exception with such nonsense.
    if (cleanTitle == nil) return;
    if (cleanTitle.length == 0) return;
    
    // Hide the keyboard.
    [self.searchNavController resignSearchFieldFirstResponder];
    
    // Don't reload an article if it's already showing! The exception is if the article
    // being shown is the first article being shown. In that case, lastViewedArticleTitle
    // isn't currently onscreen so it doesn't matter (and won't flicker).
    if ([cleanTitle isEqualToString:[self getLastViewedArticleTitle]] && !isFirstArticle) return;
    
    // Fade the web view out so there's not a flickery transition between old and new html.
//TODO: Fix this. It causes fade out even when no connection, which blanks out current article.
    //[self.webView fade];
    
    [self setCurrentArticleTitle:cleanTitle];
    isFirstArticle = NO;
    [self setLastViewedArticleTitle:cleanTitle];
    
    // Show loading message
    self.alertLabel.text = SEARCH_LOADING_MSG_SECTION_ZERO;
    
    [self retrieveArticleForPageTitle:cleanTitle discoveryMethod:discoveryMethod];
    
    // Update the back and forward buttons enabled state.
    [self updateBottomBarButtonsEnabledState];
}

- (void)retrieveArticleForPageTitle:(NSString *)pageTitle discoveryMethod:(NSString *)discoveryMethod
{
    NSManagedObjectID *articleID = [articleDataContext_.mainContext getArticleIDForTitle:pageTitle];
    Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];

    // If article with sections just show them
    if (article.section.count > 0) {
        [self displayArticle:article];
        return;
    }

    // Associate thumbnail with article.
    // If search result for this pageTitle had a thumbnail url associated with it, see if
    // a core data image object exists with a matching sourceURL. If so make the article
    // thumbnailImage property point to that core data image object. This associates the
    // search result thumbnail with the article.
    NSArray *result = [self.searchResultsController.searchResultsOrdered filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(title == %@) AND (thumbnail.source.length > 0)", pageTitle]];
    if (result.count == 1) {
        NSString *thumbURL = result[0][@"thumbnail"][@"source"];
        thumbURL = [thumbURL getUrlWithoutScheme];

        Image *thumb = (Image *)[articleDataContext_.mainContext getEntityForName: @"Image" withPredicateFormat:@"sourceUrl == %@", thumbURL];

        if (thumb) article.thumbnailImage = thumb;
    }

    // If no sections core data article may have been created when thumbnails were retrieved (before any sections are fetched)
    // or may not have had any sections last time we checked. So check now.

    // Cancel any in-progress article retrieval operations
    [[QueuesSingleton sharedInstance].articleRetrievalQ cancelAllOperations];
    
    [[QueuesSingleton sharedInstance].searchQ cancelAllOperations];
    [[QueuesSingleton sharedInstance].thumbnailQ cancelAllOperations];

    // Retrieve first section op
    
    MWNetworkOp *firstSectionOp = [[MWNetworkOp alloc] init];
    firstSectionOp.delegate = self;
    firstSectionOp.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:[SessionSingleton sharedInstance].searchApiUrl]
                                       parameters: @{
                                                     @"action": @"mobileview",
                                                     @"prop": @"sections|text",
                                                     @"sections": @"0",
                                                     @"onlyrequestedsections": @"1",
                                                     @"sectionprop": @"toclevel|line|anchor",
                                                     @"page": pageTitle,
                                                     @"format": @"json"
                                                     }
                  ];
    __weak MWNetworkOp *weakOp = firstSectionOp;
    firstSectionOp.aboutToStart = ^{
        //NSLog(@"aboutToStart for %@", pageTitle);
        [self networkActivityIndicatorPush];
    };
    firstSectionOp.completionBlock = ^(){
        [self networkActivityIndicatorPop];
        // The completion block happens on non-main thread, so must get article from articleID again.
        // Because "you can only use a context on a thread when the context was created on that thread"
        // this must happen on workerContext as well (see: http://stackoverflow.com/a/6356201/135557)
        Article *article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];

        if (weakOp.error) {
            // Show error message.
            // (need to extract msg from error *before* main q block - the error is dealloc'ed by
            // the time the block is dequeued)
            NSString *errorMsg = weakOp.error.localizedDescription;
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
                self.alertLabel.text = errorMsg;
            }];

            // Remove the article so it doesn't get saved.
            [articleDataContext_.workerContext deleteObject:article];
            
            return;
        }

        if(weakOp.isCancelled){
            //NSLog(@"completionBlock bailed (because op was cancelled) for %@", pageTitle);
            
            // Remove the article so it doesn't get saved.
            [articleDataContext_.workerContext deleteObject:article];

            return;
        }
        //NSLog(@"completionBlock for %@", pageTitle);

        // Check for error retrieving section zero data.
        if(weakOp.jsonRetrieved[@"error"]){
            NSDictionary *errorDict = weakOp.jsonRetrieved[@"error"];
            //NSLog(@"errorDict = %@", errorDict);
            
            // Set error condition so dependent remaining sections op doesn't even start.
            weakOp.error = [NSError errorWithDomain:@"Section Zero Op" code:001 userInfo:errorDict];
            
            // Remove the article so it doesn't get saved.
            [articleDataContext_.workerContext deleteObject:article];
            
            // Send html across bridge to web view
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
                // Show the api's "Page not found" message as first element of cleared page.
                self.alertLabel.text = errorDict[@"info"];
            }];
            
            return;
        }

        article.lastScrollX = @0.0f;
        article.lastScrollY = @0.0f;

        // Get article section zero html
        NSArray *sections = weakOp.jsonRetrieved[@"mobileview"][@"sections"];
        NSDictionary *section0Dict = (sections.count == 1) ? sections[0] : nil;

        NSString *section0HTML = @"";
        if (section0Dict && [section0Dict[@"id"] isEqual: @0] && section0Dict[@"text"]) {
            section0HTML = section0Dict[@"text"];
        }

        // Add sections for article
        Section *section0 = [NSEntityDescription insertNewObjectForEntityForName:@"Section" inManagedObjectContext:articleDataContext_.workerContext];
        section0.index = @0;
        section0.title = @"";
        section0.dateRetrieved = [NSDate date];
        section0.html = section0HTML;
        section0.anchor = @"";
        article.section = [NSSet setWithObjects:section0, nil];
        
        // Add history for article
        History *history0 = [NSEntityDescription insertNewObjectForEntityForName:@"History" inManagedObjectContext:articleDataContext_.workerContext];
        history0.dateVisited = [NSDate date];
        //history0.dateVisited = [NSDate dateWithDaysBeforeNow:31];
        history0.discoveryMethod = discoveryMethod;
        [article addHistoryObject:history0];

        article.site = [SessionSingleton sharedInstance].site;   //self.currentSite;
        article.domain = [SessionSingleton sharedInstance].domain; //self.currentDomain;
        article.domainName = [SessionSingleton sharedInstance].domainName;

        // Add saved for article
        //Saved *saved0 = [NSEntityDescription insertNewObjectForEntityForName:@"Saved" inManagedObjectContext:dataContext_];
        //saved0.dateSaved = [NSDate date];
        //[article addSavedObject:saved0];
        
        // Save the article!
        NSError *error = nil;
        [articleDataContext_.workerContext save:&error];

        // Update the back and forward buttons enabled state now that there's a new history entry.
        [self updateBottomBarButtonsEnabledState];

        [self createSectionImageRecordsForSectionHtml:section0.objectID onContext:articleDataContext_.workerContext];

        if (error) {
            NSLog(@"error = %@", error);
            NSLog(@"error = %@", error.localizedDescription);
        }

        // Send html across bridge to web view
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {

            // See comments inside resetBridge.
            [self resetBridge];

            NSString *section0HTMLWithTitle = [self addTitle:article.title toHTML:section0HTML];
            NSString *section0HTMLWithID = [self surroundHTML:section0HTMLWithTitle withDivForSection:@(0)];

            // Add the first section html
            [self.bridge sendMessage:@"append" withPayload:@{@"html": section0HTMLWithID}];

            // Show the web view again. (Had faded it out to prevent flickery transition to new html.)
//TODO: Fix this. It causes fade out even when no connection, which blanks out current article.
//            [self.webView reveal];

            // Show loading more sections message so user can see more is on the way
            self.alertLabel.text = SEARCH_LOADING_MSG_SECTION_REMAINING;
        }];
    };
    
    // Retrieve remaining sections op (dependent on first section op)
    
    MWNetworkOp *remainingSectionsOp = [[MWNetworkOp alloc] init];
    remainingSectionsOp.delegate = self;
    
    // Retrieval of remaining sections depends on retrieving first section
    [remainingSectionsOp addDependency:firstSectionOp];

    remainingSectionsOp.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:[SessionSingleton sharedInstance].searchApiUrl]
                                       parameters: @{
                                                     @"action": @"mobileview",
                                                     @"prop": @"sections|text",
                                                     @"sections": @"1-",
                                                     @"onlyrequestedsections": @"1",
                                                     @"sectionprop": @"toclevel|line|anchor",
                                                     @"page": pageTitle,
                                                     @"format": @"json"
                                                     }
                  ];
    __weak MWNetworkOp *weakRemainingSectionsOp = remainingSectionsOp;
    remainingSectionsOp.aboutToStart = ^{
        //NSLog(@"aboutToStart for %@", pageTitle);
        [self networkActivityIndicatorPush];
    };
    remainingSectionsOp.completionBlock = ^(){
        [self networkActivityIndicatorPop];
        if(weakRemainingSectionsOp.isCancelled){
            //NSLog(@"completionBlock bailed (because op was cancelled) for %@", pageTitle);
            self.alertLabel.hidden = YES;
            return;
        }

        // The completion block happens on non-main thread, so must get article from articleID again.
        // Because "you can only use a context on a thread when the context was created on that thread"
        // this must happen on workerContext as well (see: http://stackoverflow.com/a/6356201/135557)
        Article *article = (Article *)[articleDataContext_.workerContext objectWithID:articleID];

        // Get article sections text (faster joining array elements than appending a string)
        NSDictionary *sections = weakRemainingSectionsOp.jsonRetrieved[@"mobileview"][@"sections"];

        NSMutableArray *sectionText = [@[] mutableCopy];
        for (NSDictionary *section in sections) {
            if (![section[@"id"] isEqual: @0]) {

                NSString *sectionHTMLWithID = [self surroundHTML:section[@"text"] withDivForSection:section[@"id"]];

                [sectionText addObject:sectionHTMLWithID];

                // Add sections for article
                Section *thisSection = [NSEntityDescription insertNewObjectForEntityForName:@"Section" inManagedObjectContext:articleDataContext_.workerContext];
                thisSection.index = section[@"id"];
                thisSection.title = section[@"line"];
                thisSection.html = section[@"text"];
                thisSection.tocLevel = section[@"toclevel"];
                thisSection.dateRetrieved = [NSDate date];
                thisSection.anchor = (section[@"anchor"]) ? section[@"anchor"] : @"";
                [article addSectionObject:thisSection];
            }
        }

        NSError *error = nil;
        [articleDataContext_.workerContext save:&error];

        for (Section *section in article.section) {
            if (![section.index isEqual: @0]) {
                [self createSectionImageRecordsForSectionHtml:section.objectID onContext:articleDataContext_.workerContext];
            }
        }

        // Join article sections text
        NSString *joint = @""; //@"<div style=\"background-color:#ffffff;height:55px;\"></div>";
        NSString *htmlStr = [sectionText componentsJoinedByString:joint];
        
        // Send html across bridge to web view
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
            // Show article loaded message
            self.alertLabel.text = SEARCH_LOADING_MSG_ARTICLE_LOADED;
            // Then hide the message (hidden has been overriden to fade out slowly)
            self.alertLabel.hidden = YES;
            
            // Add the remaining sections beneath the first section
            [self.bridge sendMessage:@"append" withPayload:@{@"html": htmlStr}];
        }];
    };
    
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

#pragma mark HTML added just before display

-(NSString *)surroundHTML:(NSString *)html withDivForSection:(NSNumber *)sectionIndex
{
    // Just before section html is sent across the bridge to the web view, add section identifiers around
    // each section. This will make it easy to identify section offsets for the purpose of scrolling the
    // web view to a given section. Do not save this html to the core data store - this way it can be changed
    // later if needed (to a div etc).
    
    return [NSString stringWithFormat:
        @"<div class='content_block' id='content_block_%@'>\
            <div class='edit_section' id='edit_section_%d'>\
            </div>\
            %@\
        </div>\
        ", sectionIndex, sectionIndex.integerValue, html];
}

-(NSString *)addTitle:(NSString *)title toHTML:(NSString *)html
{
    // Add title just before section html is sent across the bridge to the web view.
    // Do not save this html to the core data store.
    return [NSString stringWithFormat:@"<h1 id=\"title\">%@</h1>%@", title, html];
}

#pragma mark Display article from core data

- (void)displayArticle:(Article *)article
{
    // Get sorted sections for this article (sorts the article.section NSSet into sortedSections)
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
    NSArray *sortedSections = [article.section sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    NSMutableArray *sectionText = [@[] mutableCopy];
    
    for (Section *section in sortedSections) {
        if (section.html){

            [self createSectionImageRecordsForSectionHtml:section.objectID onContext:articleDataContext_.mainContext];

            NSString *sectionHTML = section.html;
            if ([section.index isEqualToNumber:@(0)]) {
                sectionHTML = [self addTitle:article.title toHTML:sectionHTML];
            }

            NSString *sectionHTMLWithID = [self surroundHTML:sectionHTML withDivForSection:section.index];

            [sectionText addObject:sectionHTMLWithID];
        }
    }

    // See comments inside resetBridge.
    [self resetBridge];

    self.scrollOffset = CGPointMake(article.lastScrollX.floatValue, article.lastScrollY.floatValue);

    // Join article sections text
    NSString *joint = @""; //@"<div style=\"background-color:#ffffff;height:55px;\"></div>";
    NSString *htmlStr = [sectionText componentsJoinedByString:joint];

    // Send html across bridge to web view
    // Show article loaded message
    self.alertLabel.text = SEARCH_LOADING_MSG_ARTICLE_LOADED;
    // Then hide the message (hidden has been overriden to fade out slowly)
    self.alertLabel.hidden = YES;

    // Display all sections
    [self.bridge sendMessage:@"append" withPayload:@{@"html": htmlStr}];        
}

#pragma mark Bottom bar button methods

//TODO: Pull bottomBarView and into own object (and its subviews - the back and forward view/buttons/methods, etc).

- (IBAction)backButtonPushed:(id)sender
{
    NSString *title = self.adjacentHistoryArticleTitles[@"before"];
    if (title.length > 0) [self navigateToPage:title discoveryMethod:DISCOVERY_METHOD_SEARCH];
}

- (IBAction)forwardButtonPushed:(id)sender
{
    NSString *title = self.adjacentHistoryArticleTitles[@"after"];
    if (title.length > 0) [self navigateToPage:title discoveryMethod:DISCOVERY_METHOD_SEARCH];
}

-(NSDictionary *)getTitlesForAdjacentHistoryArticles
{
    NSMutableDictionary *result = [@{} mutableCopy];
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"History"
                                              inManagedObjectContext: articleDataContext_.mainContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"dateVisited" ascending:YES selector:nil];
    
    [fetchRequest setSortDescriptors:@[dateSort]];
    
    error = nil;
    NSArray *historyEntities = [articleDataContext_.mainContext executeFetchRequest:fetchRequest error:&error];
    
    NSString *titleOfArticleBeforeCurrentOne = @"";
    NSString *titleOfArticleAfterCurrentOne = @"";
    NSString *currentArticleTitle = [self getCurrentArticleTitle];
    NSString *lastTitle = @"";
    for (History *history in historyEntities) {
        NSString *thisTitle = history.article.title;
        if ([thisTitle isEqualToString:currentArticleTitle]) {
            titleOfArticleBeforeCurrentOne = lastTitle;
        }else if ([lastTitle isEqualToString:currentArticleTitle]) {
            titleOfArticleAfterCurrentOne = thisTitle;
        }
        lastTitle = thisTitle;
    }
    if(titleOfArticleBeforeCurrentOne.length > 0) result[@"before"] = titleOfArticleBeforeCurrentOne;
    if(currentArticleTitle.length > 0) result[@"current"] = currentArticleTitle;
    if(titleOfArticleAfterCurrentOne.length > 0) result[@"after"] = titleOfArticleAfterCurrentOne;
    return result;
}

-(void)updateBottomBarButtonsEnabledState
{
    self.adjacentHistoryArticleTitles = [self getTitlesForAdjacentHistoryArticles];
    self.forwardButton.enabled = (self.adjacentHistoryArticleTitles[@"after"]) ? YES : NO;
    self.backButton.enabled = (self.adjacentHistoryArticleTitles[@"before"]) ? YES : NO;
    NSString *currentArticleTitle = [self getCurrentArticleTitle];
    self.tocButton.enabled = (currentArticleTitle && (currentArticleTitle.length > 0)) ? YES : NO;
}

- (IBAction)tocButtonPushed:(id)sender
{
    [self tocToggle];
}

#pragma mark Other action button methods (placeholders)

- (IBAction)languageButtonPushed:(id)sender {
}

- (IBAction)actionButtonPushed:(id)sender {
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc]
                                                        initWithActivityItems:@[self.webView.request.URL]
                                                        applicationActivities:@[]];
    
    [self presentViewController:activityViewController animated:YES completion:^{
        // Whee!
    }];
}

- (IBAction)bookmarkButtonPushed:(id)sender {
}

- (IBAction)menuButtonPushed:(id)sender {
}

#pragma mark Scroll to last section after rotate

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    NSManagedObjectID *articleID = [articleDataContext_.mainContext getArticleIDForTitle:[self getCurrentArticleTitle]];
    Article *article = (Article *)[articleDataContext_.mainContext objectWithID:articleID];

    self.indexOfFirstOnscreenSectionBeforeRotate = [self.webView getIndexOfTopOnScreenElementWithPrefix:@"content_block_" count:article.section.count];
    //self.view.alpha = 0.0f;

    self.tocVisible = NO;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self performSelector:@selector(scrollToIndexOfFirstOnscreenSectionBeforeRotate) withObject:nil afterDelay:0.15f];
}

-(void)scrollToIndexOfFirstOnscreenSectionBeforeRotate{
    if(self.indexOfFirstOnscreenSectionBeforeRotate == -1)return;
    NSString *elementId = [NSString stringWithFormat:@"content_block_%ld", (long)self.indexOfFirstOnscreenSectionBeforeRotate];
    CGPoint p = [self.webView getWebViewRectForHtmlElementWithId:elementId].origin;
    p.x = self.webView.scrollView.contentOffset.x;
    [self.webView.scrollView setContentOffset:p animated:YES];
    //[UIView animateWithDuration:0.05f animations:^{
    //    self.view.alpha = 1.0f;
    //}];
}

@end
