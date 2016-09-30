#import "WMFSearchLanguagesBarViewController.h"
#import "UIFont+WMFStyle.h"
#import "WMFLanguagesViewController.h"

@interface WMFSearchLanguagesBarViewController () <WMFLanguagesViewControllerDelegate>

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *heightContraint;
@property (nonatomic) BOOL hidden;

@property (strong, nonatomic) IBOutlet UIButton *languageOneButton;
@property (strong, nonatomic) IBOutlet UIButton *languageTwoButton;
@property (strong, nonatomic) IBOutlet UIButton *languageThreeButton;
@property (strong, nonatomic) IBOutlet UIButton *otherLanguagesButton;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *languageButtons;

@end

@implementation WMFSearchLanguagesBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.languageButtons enumerateObjectsUsingBlock:^(UIButton *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        obj.tintColor = [UIColor wmf_blueTintColor];
    }];
    
    UIImage *buttonBackground = [UIImage wmf_imageFromColor:[UIColor whiteColor]];
    UIImage *highlightedButtonBackground = [UIImage wmf_imageFromColor:[UIColor colorWithWhite:0.9 alpha:1]];
    [self.otherLanguagesButton setBackgroundImage:buttonBackground forState:UIControlStateNormal];
    [self.otherLanguagesButton setBackgroundImage:highlightedButtonBackground forState:UIControlStateHighlighted];
    [self.otherLanguagesButton.layer setCornerRadius:2.0f];
    [self.otherLanguagesButton setClipsToBounds:YES];
    [self.otherLanguagesButton setTitle:MWLocalizedString(@"main-menu-title", nil) forState:UIControlStateNormal];
    self.otherLanguagesButton.titleLabel.font = [UIFont wmf_subtitle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateLanguageBarLanguages];
    [self selectLanguageForURL:[self selectedLanguage].siteURL];

    self.hidden = ![[NSUserDefaults wmf_userDefaults] wmf_showSearchLanguageBar];
}

- (void)setHidden:(BOOL)hidden {
    if(hidden){
        self.heightContraint.constant = 0;
        self.view.hidden = YES;
    }else{
        self.heightContraint.constant = 44;
        self.view.hidden = NO;
    }
    _hidden = hidden;
}

- (NSArray<MWKLanguageLink *> *)languageBarLanguages {
    return [[MWKLanguageLinkController sharedInstance].preferredLanguages wmf_arrayByTrimmingToLength:3];
}

- (void)updateLanguageBarLanguages {
    [[self languageBarLanguages] enumerateObjectsUsingBlock:^(MWKLanguageLink *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if (idx >= [self.languageButtons count]) {
            *stop = YES;
        }
        UIButton *button = self.languageButtons[idx];
        [button setTitle:[obj localizedName] forState:UIControlStateNormal];
    }];
    
    [self.languageButtons enumerateObjectsUsingBlock:^(UIButton *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if (idx >= [[self languageBarLanguages] count]) {
            obj.enabled = NO;
            obj.hidden = YES;
        } else {
            obj.enabled = YES;
            obj.hidden = NO;
        }
    }];
}

- (IBAction)setLanguageWithSender:(UIButton *)sender {
    NSUInteger index = [self.languageButtons indexOfObject:sender];
    NSAssert(index != NSNotFound, @"language button not found for language!");
    if (index != NSNotFound) {
        MWKLanguageLink *lang = [self languageBarLanguages][index];
        [self setSelectedLanguage:lang];
    }
}

- (void)setSelectedLanguage:(MWKLanguageLink *)language {
    [[NSUserDefaults wmf_userDefaults] wmf_setCurrentSearchLanguageDomain:language.siteURL];
    [self updateLanguageBarLanguages];
    [self selectLanguageForURL:language.siteURL];
}

- (void)selectLanguageForURL:(NSURL *)url {
    __block BOOL foundLanguageInBar = NO;
    [[self languageBarLanguages] enumerateObjectsUsingBlock:^(MWKLanguageLink *_Nonnull language, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([[language siteURL] isEqual:url]) {
            UIButton *buttonToSelect = self.languageButtons[idx];
            [self.languageButtons enumerateObjectsUsingBlock:^(UIButton *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                if (obj == buttonToSelect) {
                    [obj setSelected:YES];
                    foundLanguageInBar = YES;
                } else {
                    [obj setSelected:NO];
                }
            }];
        }
    }];
    
    //If we didn't find the last selected Language, jsut select the first one
    if (!foundLanguageInBar) {
        [self setSelectedLanguage:[[self languageBarLanguages] firstObject]];
        return;
    }
    
//TODO:
// - send message that lang changed to delegate (WMFSearchController - will need to actually make and set "delegate" prop) so it can re-call "searchForSearchTerm" with the new lang
// - decide who compares results list url to search site url to see if results need to be refreshed (when new primary lang is set from settings)
// - remove dupe bits from WMFSearchViewController.m (and storyboard!)
//
//    NSString *query = self.searchField.text;
//    if (![url isEqual:[self.resultsListController.dataSource searchSiteURL]] || [query isEqualToString:[self.resultsListController.dataSource searchResults].searchTerm]) {
//        [self searchForSearchTerm:query];
//    }
}

- (MWKLanguageLink *)selectedLanguage {
    NSURL *siteURL = [[NSUserDefaults wmf_userDefaults] wmf_currentSearchLanguageDomain];
    MWKLanguageLink *lang = nil;
    if (siteURL) {
        lang = [[MWKLanguageLinkController sharedInstance] languageForSiteURL:siteURL];
    } else {
        lang = [self appLanguage];
    }
    return lang;
}

- (nullable MWKLanguageLink *)appLanguage {
    MWKLanguageLink *language = [[MWKLanguageLinkController sharedInstance] appLanguage];
    NSAssert(language, @"No app language data found");
    return language;
}

- (IBAction)openLanguagePicker:(id)sender {
    WMFLanguagesViewController *languagesVC = [WMFPreferredLanguagesViewController preferredLanguagesViewController];
    languagesVC.delegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:languagesVC] animated:YES completion:NULL];
}

- (void)languagesController:(WMFPreferredLanguagesViewController *)controller didUpdatePreferredLanguages:(NSArray<MWKLanguageLink *> *)languages {
    [self updateLanguageBarLanguages];
}

@end
