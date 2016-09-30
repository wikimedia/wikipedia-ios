#import "WMFSearchLanguagesBarViewController.h"

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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
self.hidden = !self.hidden;
    
}

@end
