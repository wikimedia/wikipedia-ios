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

@interface WebViewController (){

}

@property (strong, nonatomic) SearchResultsController *searchResultsController;
@property (strong, nonatomic) MainMenuTableViewController *mainMenuTableViewController;
@property (strong, nonatomic) CommunicationBridge *bridge;
@property (weak, nonatomic) SearchNavController *searchNavController;
@property (nonatomic) CGPoint scrollOffset;
@property (nonatomic) BOOL unsafeToScroll;

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

    self.searchNavController = (SearchNavController *)self.navigationController;

    self.searchResultsController = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"SearchResultsController"];
    self.searchResultsController.webViewController = self;
    self.searchResultsController.searchNavController = self.searchNavController;

    self.mainMenuTableViewController = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"MainMenuTableViewController"];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webViewFinishedLoading) name:@"WebViewFinishedLoading" object:nil];
    self.unsafeToScroll = NO;
    self.scrollOffset = CGPointZero;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainMenuToggle) name:@"MainMenuToggle" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(historyToggle) name:@"HistoryToggle" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveCurrentPage) name:@"SavePage" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(savedPagesToggle) name:@"SavedPagesToggle" object:nil];

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
        if ([href hasPrefix:@"/wiki/"]) {
            NSString *title = [href substringWithRange:NSMakeRange(6, href.length - 6)];
            [weakSelf navigateToPage:title discoveryMethod:DISCOVERY_METHOD_LINK];
        }else if ([href hasPrefix:@"//"]) {
            href = [@"http:" stringByAppendingString:href];
            
NSString *msg = [NSString stringWithFormat:@"To do: add code for navigating to external link: %@", href];
[weakSelf.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"alert('%@')", msg]];

        }
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
        return;
    }
    if(topVC != self){
        [self.navigationController popToViewController:self animated:NO];
    }
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
    [articleDataContext_.workerContext performBlock:^(){
        Article *article = [articleDataContext_.workerContext getArticleForTitle:[self getCurrentArticleTitle]];
        Saved *alreadySaved = (Saved *)[articleDataContext_.workerContext getEntityForName: @"Saved" withPredicateFormat: @"article == %@", article];
        NSLog(@"SAVE PAGE FOR %@, alreadySaved = %@", article.title, alreadySaved);
        if (article && !alreadySaved) {
            NSLog(@"SAVED PAGE %@", article.title);
            // Save!
            Saved *saved = [NSEntityDescription insertNewObjectForEntityForName:@"Saved" inManagedObjectContext:articleDataContext_.workerContext];
            saved.dateSaved = [NSDate date];
            [article addSavedObject:saved];
            
            NSError *error = nil;
            [articleDataContext_.workerContext save:&error];
            NSLog(@"SAVE PAGE ERROR = %@", error);
        }
    }];
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

        // Save scroll location
        Article *article = [articleDataContext_.mainContext getArticleForTitle:[self getCurrentArticleTitle]];
        article.lastScrollX = @(scrollView.contentOffset.x);
        article.lastScrollY = @(scrollView.contentOffset.y);
        NSError *error = nil;
        [articleDataContext_.mainContext save:&error];
    }
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
    CGFloat distanceScrolled = fabs(scrollViewDragBeganVerticalOffset_ - scrollView.contentOffset.y);
    
    if (distanceScrolled > HIDE_KEYBOARD_ON_SCROLL_THRESHOLD) {
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

    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
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
    }];
}

- (void)retrieveArticleForPageTitle:(NSString *)pageTitle discoveryMethod:(NSString *)discoveryMethod
{
    Article *article = [articleDataContext_.mainContext getArticleForTitle:pageTitle];

    // If article with sections just show them
    if (article.section.count > 0) {
        [self displayArticle:article];

//TODO: add code here attempting to downloading thumbnail for article if article.thumbnailImage is unset at this point.

// Note: If no thumb is able to be downloaded even after this, the history controller,
// upon confirming that article.thumbnailImage remains unset, could be made to
// show a section image from the article instead (would just show it, *not* save
// any association).

        return;
    }else{
        // Discard the empty article created in mainContext by getArticleForTitle.
        [articleDataContext_.mainContext deleteObject:article];

        // Needed is an article created in the *worker* context since that's what's updated below.
        article = [articleDataContext_.workerContext getArticleForTitle:pageTitle];
    }

    // Associate thumbnail with article.
    // If search result for this pageTitle had a thumbnail url associated with it, see if
    // a core data image object exists with a matching sourceURL. If so make the article
    // thumbnailImage property point to that core data image object. This associates the
    // search result thumbnail with the article.
    NSArray *result = [self.searchResultsController.searchResultsOrdered filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(title == %@) AND (thumbnail.source.length > 0)", pageTitle]];
    if (result.count == 1) {
        NSString *thumbURL = result[0][@"thumbnail"][@"source"];
        Image *thumb = (Image *)[articleDataContext_.workerContext getEntityForName: @"Image" withPredicateFormat:@"sourceUrl == %@", thumbURL];
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
    firstSectionOp.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:SEARCH_API_URL]
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

        article.site = [[SessionSingleton sharedInstance] site];   //self.currentSite;
        article.domain = [[SessionSingleton sharedInstance] domain]; //self.currentDomain;

        // Add saved for article
        //Saved *saved0 = [NSEntityDescription insertNewObjectForEntityForName:@"Saved" inManagedObjectContext:dataContext_];
        //saved0.dateSaved = [NSDate date];
        //[article addSavedObject:saved0];
        
        // Save the article!
        NSError *error = nil;
        [articleDataContext_.workerContext save:&error];

        if (error) {
            NSLog(@"error = %@", error);
            NSLog(@"error = %@", error.localizedDescription);
        }

        // Send html across bridge to web view
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {

            // See comments inside resetBridge.
            [self resetBridge];

            // Add the first section html
            [self.bridge sendMessage:@"append" withPayload:@{@"html": section0HTML}];

            // Show the web view again. (Had faded it out to prevent flickery transition to new html.)
//TODO: Fix this. It causes fade out even when no connection, which blanks out current article.
//            [self.webView reveal];

            if(sections.count > 1){
                // Show loading more sections message so user can see more is on the way
                self.alertLabel.text = SEARCH_LOADING_MSG_SECTION_REMAINING;
            }else{
                // Show article loaded message
                self.alertLabel.text = SEARCH_LOADING_MSG_ARTICLE_LOADED;
                // Then hide the message (hidden has been overriden to fade out slowly)
                self.alertLabel.hidden = YES;
            }
        }];
    };
    
    // Retrieve remaining sections op (dependent on first section op)
    
    MWNetworkOp *remainingSectionsOp = [[MWNetworkOp alloc] init];
    remainingSectionsOp.delegate = self;
    
    // Retrieval of remaining sections depends on retrieving first section
    [remainingSectionsOp addDependency:firstSectionOp];

    remainingSectionsOp.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:SEARCH_API_URL]
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
            return;
        }
        
        // Get article sections text (faster joining array elements than appending a string)
        NSDictionary *sections = weakRemainingSectionsOp.jsonRetrieved[@"mobileview"][@"sections"];
        NSMutableArray *sectionText = [@[] mutableCopy];
        for (NSDictionary *section in sections) {
            if (![section[@"id"] isEqual: @0]) {
                [sectionText addObject:section[@"text"]];

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

#pragma mark Display article from core data

- (void)displayArticle:(Article *)article
{
    // Get sorted sections for this article (sorts the article.section NSSet into sortedSections)
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
    NSArray *sortedSections = [article.section sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    NSMutableArray *sectionText = [@[] mutableCopy];
    
    for (Section *section in sortedSections) {
        if (section.html){
            [sectionText addObject:section.html];
        }
    }

    // See comments inside resetBridge.
    [self resetBridge];

    self.scrollOffset = CGPointMake(article.lastScrollX.floatValue, article.lastScrollY.floatValue);

    // Join article sections text
    NSString *joint = @""; //@"<div style=\"background-color:#ffffff;height:55px;\"></div>";
    NSString *htmlStr = [sectionText componentsJoinedByString:joint];

    // Send html across bridge to web view
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        // Show article loaded message
        self.alertLabel.text = SEARCH_LOADING_MSG_ARTICLE_LOADED;
        // Then hide the message (hidden has been overriden to fade out slowly)
        self.alertLabel.hidden = YES;

        // Display all sections
        [self.bridge sendMessage:@"append" withPayload:@{@"html": htmlStr}];        
    }];
}

#pragma mark Action methods

- (IBAction)backButtonPushed:(id)sender {
    [self.webView goBack];
}

- (IBAction)forwardButtonPushed:(id)sender {
    [self.webView goForward];
}

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

@end
