#import "WMFSearchLanguagesBarViewController.h"
#import "UIFont+WMFStyle.h"
#import "WMFLanguagesViewController.h"

@interface WMFSearchLanguagesBarViewController () <WMFLanguagesViewControllerDelegate>

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *heightContraint;
@property (strong, nonatomic) IBOutlet UIButton *languageOneButton;
@property (strong, nonatomic) IBOutlet UIButton *languageTwoButton;
@property (strong, nonatomic) IBOutlet UIButton *languageThreeButton;
@property (strong, nonatomic) IBOutlet UIButton *otherLanguagesButton;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *languageButtons;
@property (strong, nonatomic) MWKLanguageLink *previousFirstLanguage;
@property (strong, nonatomic) MWKLanguageLink* currentlySelectedSearchLanguage;
@property (nonatomic) BOOL hidden;

@end

@implementation WMFSearchLanguagesBarViewController

@synthesize currentlySelectedSearchLanguage = _currentlySelectedSearchLanguage;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.languageButtons enumerateObjectsUsingBlock:^(UIButton *_Nonnull button, NSUInteger idx, BOOL *_Nonnull stop) {
        button.tintColor = [UIColor wmf_blueTintColor];
    }];
    [self.otherLanguagesButton setBackgroundImage:[UIImage wmf_imageFromColor:[UIColor whiteColor]] forState:UIControlStateNormal];
    [self.otherLanguagesButton setBackgroundImage:[UIImage wmf_imageFromColor:[UIColor colorWithWhite:0.9 alpha:1]] forState:UIControlStateHighlighted];
    [self.otherLanguagesButton setTitle:MWLocalizedString(@"main-menu-title", nil) forState:UIControlStateNormal];
    self.otherLanguagesButton.titleLabel.font = [UIFont wmf_subtitle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateLanguageBarLanguageButtons];
    self.hidden = ![[NSUserDefaults wmf_userDefaults] wmf_showSearchLanguageBar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self selectFirstLanguageIfNoneSelectedOrIfFirstLanguageHasChanged];
    self.previousFirstLanguage = [self.languageBarLanguages firstObject];
}

- (void)selectFirstLanguageIfNoneSelectedOrIfFirstLanguageHasChanged {
    if([self isEveryButtonUnselected] || [self isFirstLanguageDifferentFromLastTime]){
        [self setLanguageWithSender:self.languageButtons.firstObject];
    }
}

- (BOOL)isEveryButtonUnselected{
    for(UIButton *button in self.languageButtons){
        if(button.selected){
            return NO;
        }
    }
    return YES;
}

- (BOOL)isFirstLanguageDifferentFromLastTime {
    return ![self.previousFirstLanguage isEqualToLanguageLink:[self.languageBarLanguages firstObject]];
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
    [self.languageBarLanguages enumerateObjectsUsingBlock:^(MWKLanguageLink *_Nonnull language, NSUInteger idx, BOOL *_Nonnull stop) {
        if (idx >= [self.languageButtons count]) {
            *stop = YES;
        }
        UIButton *button = self.languageButtons[idx];
        [button setTitle:[language localizedName] forState:UIControlStateNormal];
        [button setSelected:[[language siteURL] isEqual:[[self selectedLanguage] siteURL]]];
    }];
    
    [self.languageButtons enumerateObjectsUsingBlock:^(UIButton *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if (idx >= [self.languageBarLanguages count]) {
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
        self.currentlySelectedSearchLanguage = [self.languageBarLanguages wmf_safeObjectAtIndex:index];
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
    return siteURL ? [[MWKLanguageLinkController sharedInstance] languageForSiteURL:siteURL] : [self appLanguage];
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

@end
