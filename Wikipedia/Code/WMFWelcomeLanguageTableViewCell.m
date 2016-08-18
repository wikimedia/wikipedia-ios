#import "WMFWelcomeLanguageTableViewCell.h"

@interface WMFWelcomeLanguageTableViewCell ()

@property (strong, nonatomic) IBOutlet UILabel *languageNameLabel;

@end

@implementation WMFWelcomeLanguageTableViewCell

- (void)setLanguageName:(NSString *)languageName {
    _languageName = languageName;
    self.languageNameLabel.text = languageName;
}

@end
