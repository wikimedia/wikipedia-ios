//  Created by Monte Hurd on 10/24/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "AboutViewController.h"
#import "WikipediaAppUtils.h"
#import "UIWebView+LoadAssetsHtml.h"
#import "Defines.h"
#import "NSString+WMFExtras.h"
#import <BlocksKit/BlocksKit.h>
#import "NSBundle+WMFInfoUtils.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIView+WMFRTLMirroring.h"
#import "UIViewController+WMFOpenExternalUrl.h"

static NSString* const kWMFAboutHTMLFile  = @"about.html";
static NSString* const kWMFAboutPlistName = @"AboutViewController";

static NSString* const kWMFPodsPlistName         = @"Pods-acknowledgements";
static NSString* const kWMFPodsLibraryArray      = @"PreferenceSpecifiers";
static NSString* const kWMFPodsLibraryNameKey    = @"Title";
static NSString* const kWMFPodsLibraryLicenseKey = @"FooterText";

static NSString* const kWMFURLsKey                = @"urls";
static NSString* const kWMFURLsFeedbackKey        = @"feedback";
static NSString* const kWMFURLsTranslateWikiKey   = @"twn";
static NSString* const kWMFURLsWikimediaKey       = @"wmf";
static NSString* const kWMFURLsSpecialistGuildKey = @"tsg";

static NSString* const kWMFRepositoriesKey = @"repositories";

static NSString* const kWMFLibrariesKey          = @"libraries";
static NSString* const kWMFLibraryNameKey        = @"Name";
static NSString* const kWMFLibraryURLKey         = @"Source URL";
static NSString* const kWMFLibraryLicenseTextKey = @"License Text";

static NSString* const kWMFLicenseScheme                     = @"wmflicense";
static NSString* const kWMFLicenseRedirectScheme             = @"about";
static NSString* const kWMFLicenseRedirectResourceIdentifier = @"blank";

static NSString* const kWMFContributorsKey = @"contributors";

@interface AboutViewController ()

@property (nonatomic, strong) UIBarButtonItem* buttonX;
@property (nonatomic, strong) UIBarButtonItem* buttonCaretLeft;

@end

@implementation AboutViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.navigationController.navigationBar wmf_mirrorIfDeviceRTL];

    self.webView.delegate = self;
    [self.webView loadHTMLFromAssetsFile:kWMFAboutHTMLFile];

    @weakify(self)
    self.buttonX = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX handler:^(id sender){
        @strongify(self)
        [self dismissViewControllerAnimated : YES completion : nil];
    }];

    self.buttonCaretLeft = [UIBarButtonItem wmf_buttonType:WMFButtonTypeCaretLeft handler:^(id sender){
        @strongify(self)
        [self.webView loadHTMLFromAssetsFile : kWMFAboutHTMLFile];
    }];

    [self updateNavigationBar];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - Navigation Bar Configuration

- (void)updateNavigationBar {
    self.title                            = self.title;
    self.navigationItem.leftBarButtonItem = [self isDisplayingLicense] ? self.buttonCaretLeft : self.buttonX;
}

- (NSString*)title {
    if ([self isDisplayingLicense]) {
        return MWLocalizedString(@"about-libraries-license", nil);
    }
    return MWLocalizedString(@"about-title", nil);
}

#pragma mark - Accessors

- (NSDictionary*)data {
    NSString* plistPath = [[NSBundle mainBundle] pathForResource:kWMFAboutPlistName ofType:@"plist"];
    return [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
}

- (NSArray*)libraries {
    return self.data[kWMFLibrariesKey];
}

- (NSString*)contributors {
    return [self.data[kWMFContributorsKey] componentsJoinedByString:@", "];
}

- (NSDictionary*)urls {
    return self.data[kWMFURLsKey];
}

- (NSDictionary*)podLibraryLicenses {
    NSString* filePath = [[NSBundle mainBundle] pathForResource:kWMFPodsPlistName ofType:@"plist"];

    NSDictionary* plist = [NSDictionary dictionaryWithContentsOfFile:filePath];

    NSArray* pods = plist[kWMFPodsLibraryArray];

    pods = [pods bk_map:^id (NSDictionary* obj) {
        return @{obj[kWMFPodsLibraryNameKey]: obj[kWMFPodsLibraryLicenseKey]};
    }];

    return [pods bk_reduce:[NSMutableDictionary dictionary] withBlock:^id (NSMutableDictionary* sum, NSDictionary* obj) {
        [sum addEntriesFromDictionary:obj];
        return sum;
    }];
}

- (NSString*)libraryLinks {
    NSArray* libraries = [[self libraries] bk_map:^id (NSDictionary* obj) {
        NSString* sourceLink = [[self class] linkHTMLForURLString:obj[kWMFLibraryURLKey] title:obj[kWMFLibraryNameKey]];

        NSString* licenseURLPath = [[self class] licenseURLPathForLibraryName:obj[kWMFLibraryNameKey]];

        NSString* licenseLink = [[self class] linkHTMLForURLString:licenseURLPath title:MWLocalizedString(@"about-libraries-license", nil)];

        return [sourceLink stringByAppendingString:[self createRTLCompatibleLicenseLink:licenseLink]];
    }];

    return [libraries componentsJoinedByString:@", "];
}

- (NSString*)createRTLCompatibleLicenseLink:(NSString*)licenseLink {
    // See: http://stackoverflow.com/a/7931735
    return [NSString stringWithFormat:@" (%@)&#x200E;", licenseLink];
}

- (NSString*)repositoryLinks {
    NSMutableDictionary* repos = (NSMutableDictionary*)self.data[kWMFRepositoriesKey];

    for (NSString* repo in [repos copy]) {
        repos[repo] = [[self class] linkHTMLForURLString:repos[repo] title:repo];
    }

    NSString* output = [repos.allValues componentsJoinedByString:@", "];
    return output;
}

- (NSString*)feedbackURL {
    NSString* feedbackUrl = self.urls[kWMFURLsFeedbackKey];
    feedbackUrl = [feedbackUrl stringByReplacingOccurrencesOfString:@"$1" withString:[WikipediaAppUtils versionedUserAgent]];

    NSString* encodedUrlString =
        [feedbackUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    return encodedUrlString;
}

#pragma mark - License Search

- (NSString*)licenseTextForLicenseURL:(NSURL*)licenseURL {
    return [self licenseTextForLibraryName:[licenseURL host]];
}

- (NSString*)licenseTextForLibraryName:(NSString*)libraryName {
    NSString* license = [self.podLibraryLicenses bk_match:^BOOL (NSString* key, NSString* license) {
        if ([key wmf_caseInsensitiveContainsString:libraryName]) {
            return YES;
        }

        return NO;
    }];

    if (!license) {
        license = [[self libraries] bk_match:^BOOL (NSDictionary* obj) {
            if ([obj[kWMFLibraryNameKey] isEqualToString:libraryName]) {
                return YES;
            }

            return NO;
        }][kWMFLibraryLicenseTextKey];
    }

    return license;
}

#pragma mark - HTML Injection


- (void)injectAboutPageContentIntoWebView:(UIWebView*)webView {
    NSString*(^ stringEscapedForJavasacript)(NSString*) = ^NSString*(NSString* string) {
        // FROM: http://stackoverflow.com/a/13569786
        // valid JSON object need to be an array or dictionary
        NSArray* arrayForEncoding = @[string];
        NSString* jsonString      = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:arrayForEncoding options:0 error:nil] encoding:NSUTF8StringEncoding];
        NSString* escapedString   = [jsonString substringWithRange:NSMakeRange(2, jsonString.length - 4)];
        return escapedString;
    };

    void (^ setDivHTML)(NSString*, NSString*) = ^void (NSString* divId, NSString* twnString) {
        twnString = stringEscapedForJavasacript(twnString);
        [self.webView stringByEvaluatingJavaScriptFromString:
         [NSString stringWithFormat:@"document.getElementById('%@').innerHTML = \"%@\";", divId, twnString]];
    };

    setDivHTML(@"version", [[NSBundle mainBundle] wmf_versionForCurrentBundleIdentifier]);
    setDivHTML(@"wikipedia", MWLocalizedString(@"about-wikipedia", nil));
    setDivHTML(@"contributors_title", MWLocalizedString(@"about-contributors", nil));
    setDivHTML(@"contributors_body", self.contributors);
    setDivHTML(@"translators_title", MWLocalizedString(@"about-translators", nil));
    setDivHTML(@"testers_title", MWLocalizedString(@"about-testers", nil));
    setDivHTML(@"libraries_title", MWLocalizedString(@"about-libraries", nil));
    setDivHTML(@"libraries_body", self.libraryLinks);
    setDivHTML(@"repositories_title", MWLocalizedString(@"about-repositories", nil));
    setDivHTML(@"repositories_body", self.repositoryLinks);
    setDivHTML(@"feedback_body", [[self class] linkHTMLForURLString:self.feedbackURL title:MWLocalizedString(@"about-send-feedback", nil)]);

    NSString* twnUrl            = self.urls[kWMFURLsTranslateWikiKey];
    NSString* translatorsLink   = [[self class] linkHTMLForURLString:twnUrl title:[twnUrl substringFromIndex:7]];
    NSString* translatorDetails =
        [MWLocalizedString(@"about-translators-details", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                        withString:translatorsLink];
    setDivHTML(@"translators_body", translatorDetails);

    NSString* tsgUrl     = self.urls[kWMFURLsSpecialistGuildKey];
    NSString* tsgLink    = [[self class] linkHTMLForURLString:tsgUrl title:[tsgUrl substringFromIndex:7]];
    NSString* tsgDetails =
        [MWLocalizedString(@"about-testers-details", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                    withString:tsgLink];
    setDivHTML(@"testers_body", tsgDetails);

    NSString* wmfUrl     = self.urls[kWMFURLsWikimediaKey];
    NSString* foundation = [[self class] linkHTMLForURLString:wmfUrl title:MWLocalizedString(@"about-wikimedia-foundation", nil)];
    NSString* footer     =
        [MWLocalizedString(@"about-product-of", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                               withString:foundation];
    setDivHTML(@"footer", footer);

    NSString* textDirection   = ([WikipediaAppUtils isDeviceLanguageRTL] ? @"rtl" : @"ltr");
    NSString* textDirectionJS = [NSString stringWithFormat:@"document.body.style.direction = '%@'", textDirection];
    [webView stringByEvaluatingJavaScriptFromString:textDirectionJS];

    NSString* fontSizeJS = [NSString stringWithFormat:@"document.body.style.fontSize = '%f%%'", (MENUS_SCALE_MULTIPLIER * 100.0f)];
    [webView stringByEvaluatingJavaScriptFromString:fontSizeJS];
}

#pragma mark - Introspection

- (BOOL)isDisplayingLicense {
    if ([[[[self.webView request] URL] scheme] isEqualToString:kWMFLicenseRedirectScheme] &&
        [[[[self.webView request] URL] resourceSpecifier] isEqualToString:kWMFLicenseRedirectResourceIdentifier]) {
        return YES;
    }

    return NO;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType;
{
    NSURL* requestURL = [request URL];

    if ([[self class] isLicenseURL:requestURL]) {
        NSString* licenseText = [self licenseTextForLicenseURL:requestURL];
        [self.webView loadHTMLString:licenseText baseURL:nil];

        return NO;
    }

    if (navigationType == UIWebViewNavigationTypeLinkClicked &&
        [[self class] isExternalURL:requestURL]) {
        [self wmf_openExternalUrl:requestURL];
        return NO;
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView*)webView {
    if (!([[self class] isLicenseURL:[webView.request URL]] || [[self class] isLicenseRedirectURL:[webView.request URL]])) {
        [self injectAboutPageContentIntoWebView:webView];
    } else {
        [self preventTextFromExpandingOnRotationInWebView:webView];
    }
    [self updateNavigationBar];
}

- (void)preventTextFromExpandingOnRotationInWebView:(UIWebView*)webView {
    [webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('body')[0].style['-webkit-text-size-adjust'] = 'none';"];
}

#pragma mark - Utility Methods

+ (NSString*)linkHTMLForURLString:(NSString*)url title:(NSString*)title {
    return [NSString stringWithFormat:@"<a href='%@'>%@</a>", url, title];
}

+ (NSString*)licenseURLPathForLibraryName:(NSString*)name {
    return [NSString stringWithFormat:@"%@://%@", kWMFLicenseScheme, name];
}

+ (BOOL)isLicenseURL:(NSURL*)url {
    if ([[url scheme] isEqualToString:kWMFLicenseScheme]) {
        return YES;
    }

    return NO;
}

+ (BOOL)isLicenseRedirectURL:(NSURL*)url {
    if ([[url scheme] isEqualToString:kWMFLicenseRedirectScheme]) {
        return YES;
    }

    return NO;
}

+ (BOOL)isExternalURL:(NSURL*)url {
    if ([[url scheme] isEqualToString:@"http"] ||
        [[url scheme] isEqualToString:@"https"] ||
        [[url scheme] isEqualToString:@"mailto"]) {
        return YES;
    }

    return NO;
}

@end
