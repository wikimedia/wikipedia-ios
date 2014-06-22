//  Created by Monte Hurd on 6/20/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "OnboardingViewController.h"
#import "PaddedLabel.h"
#import "WMF_Colors.h"
#import "WikipediaAppUtils.h"
#import "AccountCreationViewController.h"
#import "LoginViewController.h"
#import "Defines.h"
#import "NSString+FormattedAttributedString.h"

@interface OnboardingViewController ()

@property (weak, nonatomic) IBOutlet PaddedLabel *createAccountButton;
@property (weak, nonatomic) IBOutlet PaddedLabel *loginButton;
@property (weak, nonatomic) IBOutlet PaddedLabel *skipButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spaceBelowLogoConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spaceAboveLogoConstraint;

@end

@implementation OnboardingViewController

//- (BOOL)prefersStatusBarHidden
//{
//    return YES;
//}

-(void)hide
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
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
}

-(void)adjustSpacingForVariousScreenSizes
{
    CGFloat multiplier = 1.0;
    switch ((int)[UIScreen mainScreen].bounds.size.height) {
        case 480:
            // Make everything fit on 3.5 inch screens.
            multiplier = 0.2;
            break;
        case 1024:
            // Make everything fit on iPad screens.
            multiplier = 3.0;
            break;
        default:
            break;
    }
    self.spaceBelowLogoConstraint.constant *= multiplier;
    self.spaceAboveLogoConstraint.constant *= multiplier;

    // Adjust for iOS 6 status bar height.
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.spaceAboveLogoConstraint.constant -= 20;
    }
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
    [ROOT popToRootViewControllerAnimated:NO];

    AccountCreationViewController *createAcctVC = [NAV.storyboard instantiateViewControllerWithIdentifier:@"AccountCreationViewController"];

    [ROOT pushViewController:createAcctVC animated:NO];

    [self hide];
}

-(void)loginButtonTapped
{
    [ROOT popToRootViewControllerAnimated:NO];

    LoginViewController *loginVC = [NAV.storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];

    [ROOT pushViewController:loginVC animated:NO];

    [self hide];
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
