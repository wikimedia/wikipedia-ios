//
//  ViewController.m
//  Wikipedia-iOS
//
//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!
//

#import "ViewController.h"

#import "CommunicationBridge.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "MWNetworkActivityIndicatorManager.h"

@interface ViewController ()

@end

@implementation ViewController {
    CommunicationBridge *bridge_;
    NSOperationQueue *articleRetrievalQ_;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    articleRetrievalQ_ = [[NSOperationQueue alloc] init];
    bridge_ = [[CommunicationBridge alloc] initWithWebView:self.webView];
    [bridge_ addListener:@"DOMLoaded" withBlock:^(NSString *messageType, NSDictionary *payload) {
        NSLog(@"QQQ HEY DOMLoaded!");
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self navigateToPage:textField.text];
    [textField resignFirstResponder];
    return NO;
}

#pragma mark action methods

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

#pragma mark local methods

/**
 * this is a temporary hack for demo!
 */
- (void)navigateToPage:(NSString *)pageTitle
{
    // Cancel any in-progress article retrieval operations
    [articleRetrievalQ_ cancelAllOperations];
    
    NSString *underscoreForm = [pageTitle stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    NSString *encTitle = [underscoreForm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    MWNetworkActivityIndicatorManager *activityIndicator = [MWNetworkActivityIndicatorManager sharedManager];
    MWNetworkOp *op = [[MWNetworkOp alloc] init];
    op.delegate = self;
    op.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:@"https://en.m.wikipedia.org/w/api.php"]
                                       parameters: @{
                                                     @"action": @"mobileview",
                                                     @"prop": @"sections|text",
                                                     @"sections": @"all",
                                                     @"page": encTitle,
                                                     @"format": @"json"
                                                     }
                  ];
    __weak MWNetworkOp *weakOp = op;
    op.aboutToStart = ^{
        NSLog(@"aboutToStart for %@", self.searchField.text);
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
            // Show status bar spinner
            [activityIndicator show];
        }];
    };
    op.completionBlock = ^(){
        // Hide status bar spinner
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
            [activityIndicator hide];
        }];
        if(weakOp.isCancelled){
            NSLog(@"completionBlock bailed (because op was cancelled) for %@", self.searchField.text);
            return;
        }
        NSLog(@"completionBlock for %@", self.searchField.text);
        // Ensure web view is scrolled to top of new article
        [self.webView.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        
        // Get article sections text (faster joining array elements than appending a string)
        NSDictionary *sections = weakOp.jsonRetrieved[@"mobileview"][@"sections"];
        NSMutableArray *sectionText = [@[] mutableCopy];
        for (NSDictionary *section in sections) {
            [sectionText addObject:section[@"text"]];
        }
        
        // Join article sections text
        NSString *joint = @""; //@"<div style=\"background-color:#ffffff;height:50px;\"></div>";
        NSString *htmlStr = [sectionText componentsJoinedByString:joint];
        
        // Send html across bridge to web view
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
            [bridge_ sendMessage:@"displayLeadSection" withPayload:@{@"leadSectionHTML": htmlStr}];
        }];
    };
    [articleRetrievalQ_ addOperation:op];
}

-(void)opProgressed:(MWNetworkOp *)op;
{
    NSLog(@"Article retrieval progress: %@ of %@", op.bytesWritten, op.bytesExpectedToWrite);
}

@end
