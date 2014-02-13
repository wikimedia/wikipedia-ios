//  Created by Monte Hurd on 2/10/14.

#import "LoginViewController.h"
#import "NavController.h"
#import "QueuesSingleton.h"
#import "LoginTokenOp.h"
#import "LoginOp.h"
#import "SessionSingleton.h"
#import "UIViewController+Alert.h"
#import "NSHTTPCookieStorage+CloneCookie.h"

#define NAV ((NavController *)self.navigationController)

@interface LoginViewController (){

}

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.navigationItem.hidesBackButton = YES;

    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress)];
    longPressRecognizer.minimumPressDuration = 1.0f;
    [self.view addGestureRecognizer:longPressRecognizer];

    if ([self.scrollView respondsToSelector:@selector(keyboardDismissMode)]) {
        self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    }
}

-(void)handleLongPress
{
    // Uncomment for presentation username/pwd auto entry
    // self.usernameField.text = @"montehurd";
    // self.passwordField.text = @"";
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self configureNavBar];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.usernameField becomeFirstResponder];
}

-(void)configureNavBar
{
    NAV.navBarMode = NAVBAR_MODE_LOGIN;
    
    [[NAV getNavBarItem:NAVBAR_BUTTON_CHECK] addTarget: self
                                                action: @selector(save)
                                      forControlEvents: UIControlEventTouchUpInside];
    
    [[NAV getNavBarItem:NAVBAR_BUTTON_X] addTarget: self
                                            action: @selector(hide)
                                  forControlEvents: UIControlEventTouchUpInside];
    
    ((UILabel *)[NAV getNavBarItem:NAVBAR_LABEL]).text = @"Sign In";
}

-(void)save
{
    [self login];
}

-(void)hide
{
    // Remove these listeners before popping the VC or you get sadness and crashes.
    [[NAV getNavBarItem:NAVBAR_BUTTON_CHECK] removeTarget: self
                                                   action: @selector(save)
                                         forControlEvents: UIControlEventTouchUpInside];
    
    [[NAV getNavBarItem:NAVBAR_BUTTON_X] removeTarget: self
                                               action: @selector(cancel)
                                     forControlEvents: UIControlEventTouchUpInside];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    NAV.navBarMode = NAVBAR_MODE_SEARCH;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)login
{
    [self showAlert:@""];

    /*
    void (^printCookies)() =  ^void(){
        NSLog(@"\n\n\n\n\n\n\n\n\n\n");
        for (NSHTTPCookie *cookie in [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies) {
            NSLog(@"cookies = %@", cookie.properties);
        }
        NSLog(@"\n\n\n\n\n\n\n\n\n\n");
    };
     */
    
    //[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    
    NSString *userName = self.usernameField.text;
    NSString *password = self.passwordField.text;
    
    LoginOp *loginOp = [[LoginOp alloc] initWithUsername: userName
                                                password: password
                                                  domain: [SessionSingleton sharedInstance].domain
                                         completionBlock: ^(NSString *loginResult){
                                             
                                             // Login credentials should only be placed in the keychain if they've been authenticated.
                                             [SessionSingleton sharedInstance].keychainCredentials.userName = userName;
                                             [SessionSingleton sharedInstance].keychainCredentials.password = password;
                                             
                                             //NSString *result = loginResult[@"login"][@"result"];
                                             [self showAlert:loginResult];
                                             
                                             [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                 
                                                 [self performSelector:@selector(hide) withObject:nil afterDelay:1.25f];
                                                 
                                             }];
                                             
                                             [self cloneSessionCookies];
                                             //printCookies();
                                             
                                         } cancelledBlock: ^(NSError *error){
                                             
                                             [self showAlert:error.localizedDescription];
                                             
                                         } errorBlock: ^(NSError *error){
                                             
                                             [self showAlert:error.localizedDescription];
                                             
                                         }];
    
    LoginTokenOp *loginTokenOp = [[LoginTokenOp alloc] initWithUsername: userName
                                                               password: password
                                                                 domain: [SessionSingleton sharedInstance].domain
                                                        completionBlock: ^(NSString *tokenRetrieved){
                                                            
                                                            NSLog(@"loginTokenOp token = %@", tokenRetrieved);
                                                            loginOp.token = tokenRetrieved;
                                                            
                                                        } cancelledBlock: ^(NSError *error){
                                                            
                                                            [self showAlert:@""];
                                                            
                                                        } errorBlock: ^(NSError *error){
                                                            
                                                            [self showAlert:error.localizedDescription];
                                                            
                                                        }];
    
    loginTokenOp.delegate = self;
    loginOp.delegate = self;
    
    // The loginTokenOp needs to succeed before the loginOp can begin.
    [loginOp addDependency:loginTokenOp];
    
    [[QueuesSingleton sharedInstance].loginQ cancelAllOperations];
    [QueuesSingleton sharedInstance].loginQ.suspended = YES;
    [[QueuesSingleton sharedInstance].loginQ addOperation:loginTokenOp];
    [[QueuesSingleton sharedInstance].loginQ addOperation:loginOp];
    [QueuesSingleton sharedInstance].loginQ.suspended = NO;
}

-(void)cloneSessionCookies
{
    // Make the session cookies expire at same time user cookies. Just remember they still can't be
    // necessarily assumed to be valid as the server may expire them, but at least make them last as
    // long as we can to lessen number of server requests. Uses user tokens as templates for copying
    // session tokens. See "recreateCookie:usingCookieAsTemplate:" for details.

    NSString *domain = [SessionSingleton sharedInstance].domain;

    NSString *cookie1Name = [NSString stringWithFormat:@"%@wikiSession", domain];
    NSString *cookie2Name = [NSString stringWithFormat:@"%@wikiUserID", domain];
    
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] recreateCookie: cookie1Name
                                            usingCookieAsTemplate: cookie2Name
     ];
    
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] recreateCookie: @"centralauth_Session"
                                            usingCookieAsTemplate: @"centralauth_User"
     ];
}

@end
