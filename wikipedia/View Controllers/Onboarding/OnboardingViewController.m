//  Created by Monte Hurd on 6/20/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "OnboardingViewController.h"
#import "PaddedLabel.h"
#import "WMF_Colors.h"
#import "WikipediaAppUtils.h"
#import "Defines.h"
#import "NSString+FormattedAttributedString.h"
#import "RootViewController.h"
#import "TopMenuViewController.h"
#import "TopMenuContainerView.h"
#import "UIViewController+ModalPresent.h"
#import "UIViewController+Alert.h"

@interface OnboardingViewController ()

@property (weak, nonatomic) IBOutlet PaddedLabel *createAccountButton;
@property (weak, nonatomic) IBOutlet PaddedLabel *loginButton;
@property (weak, nonatomic) IBOutlet PaddedLabel *skipButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spaceBelowLogoConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spaceAboveLogoConstraint;

@end

@implementation OnboardingViewController

- (BOOL)prefersAlertsHidden
{
    return YES;
}

- (BOOL)prefersTopNavigationHidden
{
    return YES;
}

//- (BOOL)prefersStatusBarHidden
//{
//    return YES;
//}

-(void)hide
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = CHROME_COLOR;
    self.createAccountButton.backgroundColor = WMF_COLOR_GREEN;
    self.loginButton.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;
    self.loginButton.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1.0].CGColor;

    self.createAccountButton.padding = UIEdgeInsetsMake(12, 12, 12, 12);
    self.loginButton.padding = UIEdgeInsetsMake(17, 12, 17, 12);
    self.skipButton.padding = UIEdgeInsetsMake(10, 12, 10, 12);

    CGFloat cornerRadius = 3;
    self.loginButton.layer.cornerRadius = cornerRadius;
    self.createAccountButton.layer.cornerRadius = cornerRadius;
    
    [self.skipButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(skipButtonTapped)]];

    [self.createAccountButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(createAccountButtonTapped)]];

    [self.loginButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginButtonTapped)]];

    self.createAccountButton.text = MWLocalizedString(@"onboarding-create-account", nil);
    self.skipButton.text = MWLocalizedString(@"onboarding-skip", nil);

    [self adjustSpacingForVariousScreenSizes];

    [self styleLoginButtonText];
    
    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
}

-(void)adjustSpacingForVariousScreenSizes
{
    CGFloat aboveMultiplier = 1.0;
    CGFloat belowMultiplier = 1.0;
    switch ((int)[UIScreen mainScreen].bounds.size.height) {
        case 480:
            // Make everything fit on 3.5 inch screens.
            aboveMultiplier = 0.2;
            belowMultiplier = 0.0;
            break;
        case 1024:
            // Make everything fit on iPad screens.
            aboveMultiplier = 3.0;
            belowMultiplier = 3.0;
            break;
        default:
            break;
    }

    self.spaceBelowLogoConstraint.constant = roundf(self.spaceBelowLogoConstraint.constant * belowMultiplier);
    self.spaceAboveLogoConstraint.constant = roundf(self.spaceAboveLogoConstraint.constant * aboveMultiplier);

    // Adjust for iOS 6 status bar height.
    //if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
    //    self.spaceAboveLogoConstraint.constant -= 20;
    //}
}

-(void)styleLoginButtonText
{
    NSString *string = MWLocalizedString(@"onboarding-already-have-account", nil);
    NSDictionary *baseAttributes = @{
                                     NSFontAttributeName : [UIFont systemFontOfSize:14],
                                     NSForegroundColorAttributeName : [UIColor darkGrayColor]
                                     };

    self.loginButton.attributedText =
        [string attributedStringWithAttributes: baseAttributes
                           substitutionStrings: @[MWLocalizedString(@"onboarding-login", nil)]
                        substitutionAttributes: @[@{NSForegroundColorAttributeName : WMF_COLOR_BLUE}]];
}

-(void)createAccountButtonTapped
{
    [self performModalSequeWithID: @"modal_segue_show_create_account"
                  transitionStyle: UIModalTransitionStyleCoverVertical
                            block: nil];
}

-(void)loginButtonTapped
{
    [self performModalSequeWithID: @"modal_segue_show_login"
                  transitionStyle: UIModalTransitionStyleCoverVertical
                            block: nil];
}

-(void)skipButtonTapped
{
    [self hide];
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
