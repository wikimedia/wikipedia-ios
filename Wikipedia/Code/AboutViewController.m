#import "AboutViewController.h"
#import <WMF/WikipediaAppUtils.h>
#import <WMF/NSString+WMFExtras.h>
#import <WMF/NSBundle+WMFInfoUtils.h>
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "Wikipedia-Swift.h"

static NSString *const kWMFAboutHTMLFile = @"about.html";
static NSString *const kWMFAboutPlistName = @"AboutViewController";

static NSString *const kWMFURLsKey = @"urls";
static NSString *const kWMFURLsFeedbackKey = @"feedback";
static NSString *const kWMFURLsTranslateWikiKey = @"twn";
static NSString *const kWMFURLsWikimediaKey = @"wmf";
static NSString *const kWMFURLsSpecialistGuildKey = @"tsg";
static NSString *const kWMFURLsMITKey = @"mit";
static NSString *const kWMFURLsShareAlikeKey = @"sharealike";
static NSString *const kWMFURLsAppleMapsKey = @"applemaps";

static NSString *const kWMFRepositoriesKey = @"repositories";

static NSString *const kWMFLibrariesKey = @"libraries";
static NSString *const kWMFLibraryNameKey = @"Name";
static NSString *const kWMFLibraryURLKey = @"Source URL";
static NSString *const kWMFLibraryLicenseTextKey = @"License Text";

static NSString *const kWMFLicenseScheme = @"wmflicense";
static NSString *const kWMFLicenseRedirectScheme = @"about";
static NSString *const kWMFLicenseRedirectResourceIdentifier = @"blank";

static NSString *const kWMFContributorsKey = @"contributors";

@interface WKWebView (AboutViewControllerJavascript)

@end

@implementation WKWebView (AboutViewControllerJavascript)

- (void)wmf_setInnerHTML:(NSString *)html ofElementId:(NSString *)elementId {
    // Valid JSON object needs to be an array or dictionary.
    NSArray *arrayForEncoding = @[html];
    // Rely on NSJSONSerialization for string escaping: http://stackoverflow.com/a/13569786
    NSString *jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:arrayForEncoding options:0 error:nil] encoding:NSUTF8StringEncoding];
    NSString *escapedString = [jsonString substringWithRange:NSMakeRange(2, jsonString.length - 4)];

    [self evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('%@').innerHTML = \"%@\";", elementId, escapedString] completionHandler:NULL];
};

- (void)wmf_setTextDirection {
    NSString *textDirection = ([[UIApplication sharedApplication] wmf_isRTL] ? @"rtl" : @"ltr");
    NSString *textDirectionJS = [NSString stringWithFormat:@"document.body.style.direction = '%@'", textDirection];
    [self evaluateJavaScript:textDirectionJS completionHandler:nil];
}

- (void)wmf_setTextFontSize {
    NSString *fontSizeJS = [NSString stringWithFormat:@"document.body.style.fontSize = '%f%%'", 100.0f];
    [self evaluateJavaScript:fontSizeJS completionHandler:nil];
}

- (void)wmf_setTextFontColor:(WMFTheme *)theme {
    NSString *fontColorJS = [NSString stringWithFormat:@""
                                                        "function styleWithSelector (selector, styleSheetID) {"
                                                        "  function ruleWithSelector(rule) {"
                                                        "     return (rule.selectorText === selector)"
                                                        "  }"
                                                        "  return Array.from(document.getElementById(styleSheetID).sheet.rules)"
                                                        "  .find(ruleWithSelector)"
                                                        "  .style"
                                                        "}"
                                                        "styleWithSelector('body', 'styles').color = '#%@';"
                                                        "styleWithSelector('.heading', 'styles').color = '#%@';"
                                                        "styleWithSelector('.title', 'styles').color = '#%@';"
                                                        "styleWithSelector('A', 'styles').color = '#%@';",
                                                       theme.colors.primaryText.wmf_hexString,
                                                       theme.colors.primaryText.wmf_hexString,
                                                       theme.colors.secondaryText.wmf_hexString,
                                                       theme.colors.link.wmf_hexString];

    [self evaluateJavaScript:fontColorJS completionHandler:nil];
}

- (void)wmf_setLogoStyleWithTheme:(WMFTheme *)theme {
    // White logo on Dark mode
    // Black logo on Default and Sepia modes
    if (theme.isDark) {
        [self evaluateJavaScript:[NSString stringWithFormat:@"wmf.applyDarkThemeLogo()"]
               completionHandler:nil];
    } else {
        [self evaluateJavaScript:[NSString stringWithFormat:@"wmf.applyLightThemeLogo()"]
               completionHandler:nil];
    }
}

- (void)wmf_preventTextFromExpandingOnRotation {
    [self evaluateJavaScript:@"document.body.style['-webkit-text-size-adjust'] = 'none';" completionHandler:nil];
}

@end

@interface AboutViewController ()

@property (strong, nonatomic) WKWebView *webView;
@property (nonatomic, strong) UIBarButtonItem *buttonX;
@property (nonatomic, strong) UIBarButtonItem *buttonCaretLeft;

@end

@implementation AboutViewController

#pragma mark - UIViewController

- (instancetype)initWithTheme:(WMFTheme *)theme {
    self = [super init];
    if (self) {
        self.theme = theme;
    }
    return self;
}

- (UIScrollView *)scrollView {
    return self.webView.scrollView;
}

- (void)viewDidLoad {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKWebView *wv = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    [super viewDidLoad];
    [self.view wmf_addSubviewWithConstraintsToEdges:wv];

    wv.navigationDelegate = self;

    self.webView = wv;
    
    [self loadAboutHTML];
    
    self.webView.opaque = NO;
    [self applyTheme:self.theme];

    self.buttonX = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX target:self action:@selector(closeButtonPressed)];

    self.buttonCaretLeft = [UIBarButtonItem wmf_buttonType:WMFButtonTypeCaretLeft target:self action:@selector(leftButtonPressed)];

    self.buttonX.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"menu-cancel-accessibility-label", nil, nil, @"Cancel", @"Accessible label text for toolbar cancel button {{Identical|Cancel}}");
    self.buttonCaretLeft.accessibilityLabel = WMFCommonStrings.accessibilityBackTitle;

    [self updateNavigationBar];
}

- (void)loadAboutHTML {
    NSURL *assetsFolderURL = [[NSBundle wmf] wmf_assetsFolderURL];
    NSURL *aboutFileURL = [assetsFolderURL URLByAppendingPathComponent:@"about.html" isDirectory:NO];
    [self.webView loadFileURL:aboutFileURL allowingReadAccessToURL:assetsFolderURL];
}
- (void)closeButtonPressed {
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:nil];
}

- (void)leftButtonPressed {
    [self loadAboutHTML];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - Navigation Bar Configuration

- (void)updateNavigationBar {
    self.title = self.title;
    self.navigationItem.leftBarButtonItem = [self isDisplayingLicense] ? self.buttonCaretLeft : nil;
}

- (NSString *)title {
    if ([self isDisplayingLicense]) {
        return WMFLocalizedStringWithDefaultValue(@"about-libraries-license", nil, nil, @"License", @"About page link title that will display a license for a library used in the app {{Identical|License}}");
    }
    return WMFLocalizedStringWithDefaultValue(@"about-title", nil, nil, @"About", @"Title for credits page {{Identical|About}}");
}

#pragma mark - Accessors

- (NSDictionary *)data {
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:kWMFAboutPlistName ofType:@"plist"];
    return [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
}

- (NSString *)contributors {
    return [self.data[kWMFContributorsKey] componentsJoinedByString:@", "];
}

- (NSDictionary *)urls {
    return self.data[kWMFURLsKey];
}

- (NSString *)createRTLCompatibleLicenseLink:(NSString *)licenseLink {
    // See: http://stackoverflow.com/a/7931735
    return [NSString stringWithFormat:@" (%@)&#x200E;", licenseLink];
}

- (NSString *)repositoryLinks {
    NSMutableDictionary *repos = (NSMutableDictionary *)self.data[kWMFRepositoriesKey];

    for (NSString *repo in [repos copy]) {
        repos[repo] = [[self class] linkHTMLForURLString:repos[repo] title:repo];
    }

    NSString *output = [repos.allValues componentsJoinedByString:@", "];
    return output;
}

- (NSString *)feedbackURL {
    NSString *feedbackUrl = self.urls[kWMFURLsFeedbackKey];
    feedbackUrl = [feedbackUrl stringByReplacingOccurrencesOfString:@"$1" withString:[WikipediaAppUtils versionedUserAgent]];

    NSString *encodedUrlString =
        [feedbackUrl stringByRemovingPercentEncoding];

    return encodedUrlString;
}

#pragma mark - HTML Injection

- (void)injectAboutPageContentIntoWebView:(WKWebView *)webView {
    void (^setDivHTML)(NSString *, NSString *) = ^void(NSString *divId, NSString *twnString) {
        [self.webView wmf_setInnerHTML:twnString ofElementId:divId];
    };

    setDivHTML(@"version", [[NSBundle mainBundle] wmf_versionForCurrentBundleIdentifier]);
    setDivHTML(@"wikipedia", WMFCommonStrings.plainWikipediaName);
    setDivHTML(@"contributors_title", WMFLocalizedStringWithDefaultValue(@"about-contributors", nil, nil, @"Contributors", @"Header text for contributors section of the about page. Is not capitalised for aesthetic reasons, but could be capitalised in translations. {{Identical|Contributor}}"));
    setDivHTML(@"contributors_body", self.contributors);
    setDivHTML(@"translators_title", WMFLocalizedStringWithDefaultValue(@"about-translators", nil, nil, @"Translators", @"Header text for translators section of the about page. Is not capitalised for aesthetic reasons, but could be capitalised in translations. {{Identical|Translator}}"));
    setDivHTML(@"testers_title", WMFLocalizedStringWithDefaultValue(@"about-testers", nil, nil, @"Testers", @"Header text for (software) testers section of the about page. Is not capitalised for aesthetic reasons, but could be capitalised in translations."));
    setDivHTML(@"libraries_title", WMFLocalizedStringWithDefaultValue(@"about-libraries", nil, nil, @"Libraries used", @"Header text for libraries section (as in a collection of subprograms used to develop software) of the about page. Is not capitalised for aesthetic reasons, but could be capitalised in translations."));
    setDivHTML(@"libraries_body", [[self class] linkHTMLForURLString:@"wmflicense://licenses" title:WMFLocalizedStringWithDefaultValue(@"about-libraries-complete-list", nil, nil, @"Complete list", @"Title for link to complete list of libraries use by the app")]);
    setDivHTML(@"repositories_title", WMFLocalizedStringWithDefaultValue(@"about-repositories", nil, nil, @"Repositories", @"Header text for repositories section of the about page. Is not capitalised for aesthetic reasons, but could be capitalised in translations.  {{Identical|Repository}}"));
    setDivHTML(@"repositories_body", self.repositoryLinks);

    setDivHTML(@"repositories_subtitle", [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"about-repositories-app-source-license", nil, nil, @"Source code available under the %1$@.", @"Text explaining the app source licensing. %1$@ is the message {{msg-wikimedia|about-repositories-app-source-license-mit}}."), [[self class] linkHTMLForURLString:self.urls[kWMFURLsMITKey] title:WMFLocalizedStringWithDefaultValue(@"about-repositories-app-source-license-mit", nil, nil, @"MIT License", @"Name of the \"MIT\" license")]]);

    setDivHTML(@"feedback_body", [[self class] linkHTMLForURLString:self.feedbackURL title:WMFLocalizedStringWithDefaultValue(@"about-send-feedback", nil, nil, @"Send app feedback", @"Link text for sending app feedback")]);

    setDivHTML(@"places_maps_license_title", WMFLocalizedStringWithDefaultValue(@"about-places-maps-license", nil, nil, @"Places maps license", @"Header text for maps license section"));
    setDivHTML(@"places_maps_license_body", [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"about-places-maps-license-details", nil, nil, @"Places uses maps provided by Apple Maps. %1$@.", @"Text explaining license of maps content. %1$@ is the message {{msg-wikimedia|about-places-maps-license-details-link-text}}."), [[self class] linkHTMLForURLString:self.urls[kWMFURLsAppleMapsKey] title:WMFLocalizedStringWithDefaultValue(@"about-places-maps-license-details-link-text", nil, nil, @"Please see here for license details", @"Text used for link to maps license")]]);

    setDivHTML(@"license_title", WMFLocalizedStringWithDefaultValue(@"about-content-license", nil, nil, @"Content license", @"Header text for content license section"));

    setDivHTML(@"license_body", [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"about-content-license-details", nil, nil, @"Unless otherwise specified, content is available under a %1$@.", @"Text explaining license of app content. %1$@ is the message {{msg-wikimedia|about-content-license-details-share-alike-license}}."), [[self class] linkHTMLForURLString:self.urls[kWMFURLsShareAlikeKey] title:WMFLocalizedStringWithDefaultValue(@"about-content-license-details-share-alike-license", nil, nil, @"Creative Commons Attribution-ShareAlike License", @"Name of the \"Creative Commons Attribution-ShareAlike\" license")]]);

    setDivHTML(@"translators_body", [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"about-translators-details", nil, nil, @"Translated by volunteers at %1$@", @"Description of volunteer translation. %1$@ is translatewiki url."), [[self class] linkHTMLForURLString:self.urls[kWMFURLsTranslateWikiKey] title:[self.urls[kWMFURLsTranslateWikiKey] substringFromIndex:7]]]);
    setDivHTML(@"testers_body", [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"about-testers-details", nil, nil, @"QA tested by %1$@", @"Description of the Quality Assurance (QA) testers. %1$@ is specialistsguild.org, the website of the testing group."), [[self class] linkHTMLForURLString:self.urls[kWMFURLsSpecialistGuildKey] title:[self.urls[kWMFURLsSpecialistGuildKey] substringFromIndex:7]]]);

    setDivHTML(@"footer", [NSString stringWithFormat:WMFLocalizedStringWithDefaultValue(@"about-product-of", nil, nil, @"Made by the %1$@ with the help of volunteers like you", @"Description of who produced the app. %1$@ is the message {{msg-wikimedia|wikipedia-ios-about-wikimedia-foundation}}."), [[self class] linkHTMLForURLString:self.urls[kWMFURLsWikimediaKey] title:WMFLocalizedStringWithDefaultValue(@"about-wikimedia-foundation", nil, nil, @"Wikimedia Foundation", @"Name of the Wikimedia Foundation. Used by the message {{Msg-wikimedia|wikipedia-ios-about-product-of}}.")]]);

    [webView wmf_setTextDirection];
    [webView wmf_setTextFontSize];
    [webView wmf_setTextFontColor:self.theme];
    [webView wmf_setLogoStyleWithTheme:self.theme];
}

#pragma mark - Introspection

- (BOOL)isDisplayingLicense {
    if ([[[self.webView URL] scheme] isEqualToString:kWMFLicenseRedirectScheme] &&
        [[[self.webView URL] resourceSpecifier] isEqualToString:kWMFLicenseRedirectResourceIdentifier]) {
        return YES;
    }

    return NO;
}

#pragma mark - WKWebViewDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    WKNavigationType navigationType = navigationAction.navigationType;
    NSURL *requestURL = navigationAction.request.URL;

    if ([[self class] isLicenseURL:requestURL]) {

        LibrariesUsedViewController *vc = [LibrariesUsedViewController wmf_viewControllerFromStoryboardNamed:LibrariesUsedViewController.storyboardName];
        [vc applyTheme:self.theme];
        vc.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];

        WMFThemeableNavigationController *nc = [[WMFThemeableNavigationController alloc] initWithRootViewController:vc theme:self.theme];
        [self presentViewController:nc animated:YES completion:nil];

        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

    if (navigationType == WKNavigationTypeLinkActivated &&
        [[self class] isExternalURL:requestURL]) {
        [self wmf_navigateToURL:requestURL];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    if (!([[self class] isLicenseURL:[webView URL]] || [[self class] isLicenseRedirectURL:[webView URL]])) {
        [self injectAboutPageContentIntoWebView:webView];
    } else {
        [webView wmf_preventTextFromExpandingOnRotation];
    }
    [self updateNavigationBar];
}

#pragma mark - Utility Methods

+ (NSString *)linkHTMLForURLString:(NSString *)url title:(NSString *)title {
    return [NSString stringWithFormat:@"<a href='%@'>%@</a>", url, title];
}

+ (NSString *)licenseURLPathForLibraryName:(NSString *)name {
    return [NSString stringWithFormat:@"%@://%@", kWMFLicenseScheme, name];
}

+ (BOOL)isLicenseURL:(NSURL *)url {
    if ([[url scheme] isEqualToString:kWMFLicenseScheme]) {
        return YES;
    }

    return NO;
}

+ (BOOL)isLicenseRedirectURL:(NSURL *)url {
    if ([[url scheme] isEqualToString:kWMFLicenseRedirectScheme]) {
        return YES;
    }

    return NO;
}

+ (BOOL)isExternalURL:(NSURL *)url {
    if ([[url scheme] isEqualToString:@"http"] ||
        [[url scheme] isEqualToString:@"https"] ||
        [[url scheme] isEqualToString:@"mailto"]) {
        return YES;
    }

    return NO;
}

#pragma mark - WMFThemeable

- (void)applyTheme:(WMFTheme *)theme {
    [super applyTheme:theme];
    if (self.viewIfLoaded == nil) {
        return;
    }
    self.view.backgroundColor = theme.colors.paperBackground;
    [self.webView wmf_setTextFontColor:theme];
    [self.webView wmf_setLogoStyleWithTheme:theme];
}

@end
