//  Created by Monte Hurd on 4/18/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "CreditsViewController.h"
#import "WikipediaAppUtils.h"
#import "CenterNavController.h"
#import "RootViewController.h"
#import "TopMenuViewController.h"

@interface CreditsViewController ()

@end

@implementation CreditsViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.title = MWLocalizedString(@"main-menu-credits", nil);
        self.navBarMode = NAVBAR_MODE_X_WITH_LABEL;
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(navItemTappedNotification:)
                                                 name: @"NavItemTapped"
                                               object: nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"NavItemTapped"
                                                  object: nil];

    [super viewWillDisappear:animated];
}

- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_X:
            [self hide];
            
            break;
        default:
            break;
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void)hide
{
    // Hide this view controller.
    if(!(self.isBeingPresented || self.isBeingDismissed)){
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.navigationItem.hidesBackButton = YES;

    self.titleLabel.text = MWLocalizedString(@"credits-title", nil);
    self.wikimediaReposLabel.text = MWLocalizedString(@"credits-wikimedia-repos", nil);
    self.externalLibrariesLabel.text = MWLocalizedString(@"credits-external-libraries", nil);
    self.githubLabel.text = MWLocalizedString(@"credits-github-mirror", nil);
    self.gerritLabel.text = MWLocalizedString(@"credits-gerrit-repo", nil);
    
    [self addTapRecognizerToView:self.githubLabel];
    [self addTapRecognizerToView:self.gerritLabel];
    [self addTapRecognizerToView:self.wikiFontLabel];
    [self addTapRecognizerToView:self.hppleLabel];
    [self addTapRecognizerToView:self.nsdateLabel];
}

-(void)addTapRecognizerToView:(UIView *)view
{
    [view addGestureRecognizer:
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)]
     ];
}

-(void)viewTapped:(UITapGestureRecognizer *)recognizer
{
    NSString *url = nil;
    if (recognizer.view == self.githubLabel) {
        url = @"https://github.com/wikimedia/apps-ios-wikipedia";
    }else if (recognizer.view == self.gerritLabel) {
        url = @"https://gerrit.wikimedia.org/r/#/q/project:apps/ios/wikipedia,n,z";
    }else if (recognizer.view == self.wikiFontLabel) {
        url = @"https://github.com/munmay/WikiFont";
    }else if (recognizer.view == self.hppleLabel) {
        url = @"https://github.com/topfunky/hpple";
    }else if (recognizer.view == self.nsdateLabel) {
        url = @"https://github.com/erica/NSDate-Extensions";
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
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
