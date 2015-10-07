//
//  SVModalWebViewController.m
//
//  Created by Oliver Letterer on 13.08.11.
//  Copyright 2011 Home. All rights reserved.
//
//  https://github.com/samvermette/SVWebViewController

#import "SVModalWebViewController.h"
#import "SVWebViewController.h"

@interface SVModalWebViewController ()

@property (nonatomic, strong) SVWebViewController *webViewController;

@end


@implementation SVModalWebViewController

#pragma mark - Initialization


- (id)initWithAddress:(NSString*)urlString {
    return [self initWithURL:[NSURL URLWithString:urlString]];
}

- (id)initWithURL:(NSURL *)URL {
    self.webViewController = [[SVWebViewController alloc] initWithURL:URL];
    if (self = [super initWithRootViewController:self.webViewController]) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self.webViewController
                                                                                    action:@selector(doneButtonClicked:)];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            self.webViewController.navigationItem.leftBarButtonItem = doneButton;
        else
            self.webViewController.navigationItem.rightBarButtonItem = doneButton;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:NO];
    
    self.webViewController.title = self.title;
    self.navigationBar.tintColor = self.barsTintColor;
}

@end
