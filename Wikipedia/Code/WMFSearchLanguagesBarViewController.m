#import "WMFSearchLanguagesBarViewController.h"
#import "UIFont+WMFStyle.h"

@interface WMFSearchLanguagesBarViewController ()

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

    [self updateLanguageBarLanguages];
    
    self.hidden = YES;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
self.hidden = !self.hidden;
    
}

@end
