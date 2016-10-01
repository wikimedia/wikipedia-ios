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

@property (strong, nonatomic) MWKLanguageLink *previousFirstLanguage;

@property (nonatomic, strong) MWKLanguageLink* currentlySelectedSearchLanguage;

@end

@implementation WMFSearchLanguagesBarViewController

@synthesize currentlySelectedSearchLanguage = _currentlySelectedSearchLanguage;

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
    
    [self updateLanguageBarLanguageButtons];
    
    self.hidden = ![[NSUserDefaults wmf_userDefaults] wmf_showSearchLanguageBar];
}

- (BOOL)isAnyButtonSelected{
    for(UIButton *button in self.languageButtons){
        if(button.selected){
            return YES;
        }
    }
    return NO;
}

- (void)selectFirstLanguageIfNoneSelectedOrIfFirstLanguageHasChanged {
    if(![self isAnyButtonSelected] || ![self.previousFirstLanguage isEqualToLanguageLink:[[self languageBarLanguages] firstObject]]){
        [self setLanguageWithSender:self.languageButtons.firstObject];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self selectFirstLanguageIfNoneSelectedOrIfFirstLanguageHasChanged];
    self.previousFirstLanguage = [[self languageBarLanguages] firstObject];
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

- (void)updateLanguageBarLanguageButtons {
    [[self languageBarLanguages] enumerateObjectsUsingBlock:^(MWKLanguageLink *_Nonnull language, NSUInteger idx, BOOL *_Nonnull stop) {
        if (idx >= [self.languageButtons count]) {
            *stop = YES;
        }
        UIButton *button = self.languageButtons[idx];
        [button setTitle:[language localizedName] forState:UIControlStateNormal];
        
        [button setSelected:[[language siteURL] isEqual:[[self selectedLanguage] siteURL]]];
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
        self.currentlySelectedSearchLanguage = lang;
    }
}

- (void)setCurrentlySelectedSearchLanguage:(MWKLanguageLink *)currentlySelectedSearchLanguage {
    _currentlySelectedSearchLanguage = currentlySelectedSearchLanguage;
 
    [[NSUserDefaults wmf_userDefaults] wmf_setCurrentSearchLanguageDomain:currentlySelectedSearchLanguage.siteURL];
    
    [self.delegate searchLanguagesBarController:self didChangeCurrentlySelectedSearchLanguage:currentlySelectedSearchLanguage];
    
    [self updateLanguageBarLanguageButtons];
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
    [self updateLanguageBarLanguageButtons];
}

- (NSURL *)currentlySelectedSearchURL {
    return [self selectedLanguage].siteURL;
}

@end
