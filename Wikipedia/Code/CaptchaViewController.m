#import "CaptchaViewController.h"

@interface CaptchaViewController ()

@property (weak, nonatomic) IBOutlet UIButton *reloadCaptchaButton;

@end

@implementation CaptchaViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self.reloadCaptchaButton setTitle:MWLocalizedString(@"captcha-reload", nil) forState:UIControlStateNormal];

    [self.captchaTextBox setPlaceholder:MWLocalizedString(@"captcha-prompt", nil)];

    [self.reloadCaptchaButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateDisabled];
    [self.reloadCaptchaButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];

    self.captchaTextBox.textAlignment = NSTextAlignmentNatural;

    self.reloadCaptchaButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
    self.captchaTextBox.font = [UIFont systemFontOfSize:15.0];
}

- (void)reloadCaptchaPushed:(id)sender {
    if ([self.parentViewController respondsToSelector:@selector(reloadCaptchaPushed:)]) {
        [self.parentViewController performSelectorOnMainThread:@selector(reloadCaptchaPushed:) withObject:nil waitUntilDone:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.reloadCaptchaButton addTarget:self
                                 action:@selector(reloadCaptchaPushed:)
                       forControlEvents:UIControlEventTouchUpInside];

    // Allow whatever view controller is using this captcha view controller
    // to monitor changes to captchaTextBox and also when its keyboard done/next
    // buttons are tapped.
    if ([self.parentViewController conformsToProtocol:@protocol(UITextFieldDelegate)]) {
        self.captchaTextBox.delegate = (id<UITextFieldDelegate>)self.parentViewController;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    self.captchaTextBox.delegate = nil;

    [self.reloadCaptchaButton removeTarget:nil
                                    action:NULL
                          forControlEvents:UIControlEventAllEvents];

    [super viewWillDisappear:animated];
}

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
