//  Created by Monte Hurd on 10/24/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "AboutViewController.h"
#import "WikipediaAppUtils.h"
#import "UIViewController+ModalPop.h"
#import "UIWebView+LoadAssetsHtml.h"
#import "Defines.h"

@interface AboutViewController ()

@property (nonatomic, retain) NSDictionary *data;
@property (nonatomic, retain, readonly) NSString *contributors;
@property (nonatomic, retain, readonly) NSString *repositoryLinks;
@property (nonatomic, retain, readonly) NSString *libraryLinks;
@property (nonatomic, retain, readonly) NSDictionary *urls;
@property (nonatomic, retain, readonly) NSString *feedbackURL;

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"AboutViewController" ofType:@"plist"];
    self.data = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    self.webView.delegate = self;
    [self.webView loadHTMLFromAssetsFile:@"about.html"];
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
            [self popModal];
            break;
        default:
            break;
    }
}

-(NavBarMode)navBarMode
{
    return NAVBAR_MODE_X_WITH_LABEL;
}

-(NSString *)title
{
    return MWLocalizedString(@"about-title", nil);
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

-(NSString *)contributors
{
    return [self.data[@"contributors"] componentsJoinedByString:@", "];
}

-(NSDictionary *)urls
{
    return self.data[@"urls"];
}

-(NSString *)libraryLinks
{
    NSMutableDictionary *libraries = (NSMutableDictionary *)self.data[@"libraries"];
    
    for (NSString *library in libraries.copy) {
        libraries[library] = [self getLinkHTMLForURL:libraries[library] title:library];
    }
    
    NSString *output = [libraries.allValues componentsJoinedByString:@", "];
    return output;
}

-(NSString *)repositoryLinks
{
    NSMutableDictionary *repos = (NSMutableDictionary *)self.data[@"repositories"];
    
    for (NSString *repo in repos.copy) {
        repos[repo] = [self getLinkHTMLForURL:repos[repo] title:repo];
    }
    
    NSString *output = [repos.allValues componentsJoinedByString:@", "];
    return output;
}

-(NSString *)feedbackUrl
{
    NSString *feedbackUrl = self.urls[@"feedback"];
    feedbackUrl = [feedbackUrl stringByReplacingOccurrencesOfString:@"$1" withString:[WikipediaAppUtils versionedUserAgent]];

    NSString *encodedUrlString =
    [feedbackUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    return encodedUrlString;
}

-(NSString *)getLinkHTMLForURL:(NSString *)url title:(NSString *)title
{
    return [NSString stringWithFormat:@"<a href='%@'>%@</a>", url, title];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString*(^stringEscapedForJavasacript)(NSString*) = ^ NSString*(NSString *string) {
        // FROM: http://stackoverflow.com/a/13569786
        // valid JSON object need to be an array or dictionary
        NSArray *arrayForEncoding = @[string];
        NSString *jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:arrayForEncoding options:0 error:nil] encoding:NSUTF8StringEncoding];
        NSString *escapedString = [jsonString substringWithRange:NSMakeRange(2, jsonString.length - 4)];
        return escapedString;
    };
    
    void (^setDivHTML)(NSString*, NSString*) = ^ void(NSString *divId, NSString *twnString) {
        twnString = stringEscapedForJavasacript(twnString);
        [self.webView stringByEvaluatingJavaScriptFromString:
         [NSString stringWithFormat:@"document.getElementById('%@').innerHTML = \"%@\";", divId, twnString]];
    };
    
    NSDictionary *appInfo = [[NSBundle mainBundle] infoDictionary];
    NSString *version = appInfo[@"CFBundleVersion"] ? appInfo[@"CFBundleVersion"] : @"Unknown version";
    
    setDivHTML(@"version", version);
    setDivHTML(@"wikipedia", MWLocalizedString(@"about-wikipedia", nil));
    setDivHTML(@"contributors_title", MWLocalizedString(@"about-contributors", nil));
    setDivHTML(@"contributors_body", self.contributors);
    setDivHTML(@"translators_title", MWLocalizedString(@"about-translators", nil));
    setDivHTML(@"libraries_title", MWLocalizedString(@"about-libraries", nil));
    setDivHTML(@"libraries_body", self.libraryLinks);
    setDivHTML(@"repositories_title", MWLocalizedString(@"about-repositories", nil));
    setDivHTML(@"repositories_body", self.repositoryLinks);
    setDivHTML(@"feedback_body", [self getLinkHTMLForURL:self.feedbackURL title:MWLocalizedString(@"about-send-feedback", nil)]);
    
    NSString *twnUrl = self.urls[@"twn"];
    NSString *translatorsLink = [self getLinkHTMLForURL:twnUrl title:[twnUrl substringFromIndex:7]];
    NSString *translatorDetails =
    [MWLocalizedString(@"about-translators-details", nil) stringByReplacingOccurrencesOfString: @"$1"
                                                                                    withString: translatorsLink];
    setDivHTML(@"translators_body", translatorDetails);
    
    NSString *wmfUrl = self.urls[@"wmf"];
    NSString *foundation = [self getLinkHTMLForURL:wmfUrl title:MWLocalizedString(@"about-wikimedia-foundation", nil)];
    NSString *footer =
    [MWLocalizedString(@"about-product-of", nil) stringByReplacingOccurrencesOfString: @"$1"
                                                                           withString: foundation];
    setDivHTML(@"footer", footer);
    
    NSString *textDirection = ([WikipediaAppUtils isDeviceLanguageRTL] ? @"rtl" : @"ltr");
    NSString *textDirectionJS = [NSString stringWithFormat:@"document.body.style.direction = '%@'", textDirection];
    [self.webView stringByEvaluatingJavaScriptFromString:textDirectionJS];

    NSString *fontSizeJS = [NSString stringWithFormat:@"document.body.style.fontSize = '%f%%'", (MENUS_SCALE_MULTIPLIER * 100.0f)];
    [self.webView stringByEvaluatingJavaScriptFromString:fontSizeJS];
}

// Force web view links to open in Safari.
// From: http://stackoverflow.com/a/2532884
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    NSURL *requestURL = [request URL];
    if (
        (
         [[requestURL scheme] isEqualToString:@"http"]
         ||
         [[requestURL scheme] isEqualToString:@"https"]
         ||
         [[requestURL scheme] isEqualToString:@"mailto"])
        && (navigationType == UIWebViewNavigationTypeLinkClicked)
        ) {
        return ![[UIApplication sharedApplication] openURL:requestURL];
    }
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
