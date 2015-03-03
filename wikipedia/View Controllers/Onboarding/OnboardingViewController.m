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
#import "UIView+Debugging.h"

#define TAKE_SPLASH_SCREENSHOT NO

typedef NS_ENUM (NSUInteger, DisplayMode) {
    DISPLAY_MODE_UNDEFINED,
    DISPLAY_MODE_SPLASH,
    DISPLAY_MODE_NORMAL
};

@interface OnboardingViewController ()

@property (weak, nonatomic) IBOutlet PaddedLabel* createAccountButton;
@property (weak, nonatomic) IBOutlet PaddedLabel* loginButton;
@property (weak, nonatomic) IBOutlet PaddedLabel* skipButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint* spaceAboveLogoConstraint;
@property (nonatomic) CGFloat origSpaceAboveLogoConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint* spaceBelowLogoTextImageConstraint;
@property (nonatomic) CGFloat origSpaceBelowLogoTextImageConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint* spaceBetweenLogoImagesConstraint;
@property (nonatomic) CGFloat origSpaceBetweenLogoImagesConstraint;

@property (weak, nonatomic) IBOutlet UIImageView* logoImage;
@property (weak, nonatomic) IBOutlet UIImageView* logoTextImage;

@property (nonatomic) DisplayMode displayMode;

@end

@implementation OnboardingViewController

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    //return UIInterfaceOrientationMaskAll;
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ?
           UIInterfaceOrientationMaskPortrait : UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersAlertsHidden {
    return YES;
}

- (BOOL)prefersTopNavigationHidden {
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return TAKE_SPLASH_SCREENSHOT;
}

- (UIModalTransitionStyle)modalTransitionStyle {
    return UIModalTransitionStyleCrossDissolve;
}

- (void)hide {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    static BOOL once = NO;
    if (once) {
        return;
    }
    once = YES;

    if (!TAKE_SPLASH_SCREENSHOT) {
        [self animateToDisplayMode:DISPLAY_MODE_NORMAL];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.origSpaceAboveLogoConstraint          = self.spaceAboveLogoConstraint.constant;
    self.origSpaceBelowLogoTextImageConstraint = self.spaceBelowLogoTextImageConstraint.constant;
    self.origSpaceBetweenLogoImagesConstraint  = self.spaceBetweenLogoImagesConstraint.constant;

    self.view.backgroundColor                = CHROME_COLOR;
    self.createAccountButton.backgroundColor = WMF_COLOR_GREEN;
    self.loginButton.layer.borderWidth       = 1.0f / [UIScreen mainScreen].scale;
    self.loginButton.layer.borderColor       = [UIColor colorWithWhite:0.88 alpha:1.0].CGColor;

    self.createAccountButton.padding = UIEdgeInsetsMake(12, 12, 12, 12);
    self.loginButton.padding         = UIEdgeInsetsMake(17, 12, 17, 12);
    self.skipButton.padding          = UIEdgeInsetsMake(10, 12, 10, 12);

    CGFloat cornerRadius = 3;
    self.loginButton.layer.cornerRadius         = cornerRadius;
    self.createAccountButton.layer.cornerRadius = cornerRadius;

    [self.skipButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(skipButtonTapped:)]];

    [self.createAccountButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(createAccountButtonTapped:)]];

    [self.loginButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginButtonTapped:)]];

    self.createAccountButton.text = MWLocalizedString(@"onboarding-create-account", nil);
    self.skipButton.text          = MWLocalizedString(@"onboarding-skip", nil);

    [self styleLoginButtonText];

    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    static BOOL once = NO;
    if (once) {
        return;
    }
    once = YES;

    self.displayMode = DISPLAY_MODE_SPLASH;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.displayMode = self.displayMode;
}

- (void)setDisplayMode:(DisplayMode)displayMode {
    _displayMode = displayMode;
    switch (self.displayMode) {
        case DISPLAY_MODE_SPLASH:
            // Center the globe image vertically.
            self.spaceAboveLogoConstraint.constant =
                (self.view.bounds.size.height / 2.0) - (self.logoImage.bounds.size.height / 2.0);
            self.createAccountButton.alpha = 0.0;
            self.loginButton.alpha         = 0.0;
            self.skipButton.alpha          = 0.0;
            self.logoTextImage.alpha       = 0.0;
            self.logoImage.transform       = CGAffineTransformIdentity;
            break;
        case DISPLAY_MODE_NORMAL:
            self.spaceAboveLogoConstraint.constant          = self.origSpaceAboveLogoConstraint;
            self.spaceBelowLogoTextImageConstraint.constant = self.origSpaceBelowLogoTextImageConstraint;
            self.spaceBetweenLogoImagesConstraint.constant  = self.origSpaceBetweenLogoImagesConstraint;
            self.createAccountButton.alpha                  = 1.0;
            self.loginButton.alpha                          = 1.0;
            self.skipButton.alpha                           = 1.0;
            self.logoTextImage.alpha                        = 1.0;
            [self adjustSpacingForVariousScreenSizes];
            break;
        default:
            break;
    }
    [self.view setNeedsUpdateConstraints];
    [self.view layoutIfNeeded];
}

- (void)adjustSpacingForVariousScreenSizes {
    CGFloat aboveMultiplier   = 1.3;
    CGFloat belowMultiplier   = 1.0;
    CGFloat betweenMultiplier = 1.0;
    //CGFloat imageScale = 1.0;

    switch ((int)[UIScreen mainScreen].bounds.size.height) {
        case 480:
            // Make everything fit on 3.5 inch screens.
            aboveMultiplier   = 0.65;
            betweenMultiplier = 0.35;
            belowMultiplier   = 0.25;
            break;
        case 1024:
            // Make everything fit on iPad screens.
            aboveMultiplier = 3.0;
            break;
        default:
            break;
    }

    //self.logoImage.transform = CGAffineTransformMakeScale(imageScale, imageScale);

    self.spaceAboveLogoConstraint.constant =
        roundf(self.spaceAboveLogoConstraint.constant * aboveMultiplier);

    self.spaceBetweenLogoImagesConstraint.constant =
        roundf(self.spaceBetweenLogoImagesConstraint.constant * betweenMultiplier);

    self.spaceBelowLogoTextImageConstraint.constant =
        roundf(self.spaceBelowLogoTextImageConstraint.constant * belowMultiplier);

    // Adjust for iOS 6 status bar height.
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.spaceAboveLogoConstraint.constant -= 20;
    }
}

- (void)styleLoginButtonText {
    NSString* string             = MWLocalizedString(@"onboarding-already-have-account", nil);
    NSDictionary* baseAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:14],
        NSForegroundColorAttributeName: [UIColor darkGrayColor]
    };

    self.loginButton.attributedText =
        [string attributedStringWithAttributes:baseAttributes
                           substitutionStrings:@[MWLocalizedString(@"onboarding-login", nil)]
                        substitutionAttributes:@[@{NSForegroundColorAttributeName: WMF_COLOR_BLUE}]];
}

- (void)createAccountButtonTapped:(UITapGestureRecognizer*)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self performModalSequeWithID:@"modal_segue_show_create_account"
                      transitionStyle:UIModalTransitionStyleCoverVertical
                                block:nil];
    }
}

- (void)loginButtonTapped:(UITapGestureRecognizer*)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self performModalSequeWithID:@"modal_segue_show_login"
                      transitionStyle:UIModalTransitionStyleCoverVertical
                                block:nil];
    }
}

- (void)skipButtonTapped:(UITapGestureRecognizer*)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self hide];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

    /*
       DisplayMode newDisplayMode = DISPLAY_MODE_UNDEFINED;
       newDisplayMode = (self.displayMode == DISPLAY_MODE_NORMAL) ? DISPLAY_MODE_SPLASH : DISPLAY_MODE_NORMAL;
       [self animateToDisplayMode:newDisplayMode];
     */
}

- (void)animateToDisplayMode:(DisplayMode)displayMode {
    CGFloat delay = 0.5;
    // Reminder: must have small delay to give web view, which is the root view controller, a bit of time to
    // do some of its setup stuff - otherwise the animation here will be choppy (web views use main thread
    // heavily).
    [UIView animateWithDuration:0.5 delay:delay options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.displayMode = displayMode;
    } completion:^(BOOL done){
    }];
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
