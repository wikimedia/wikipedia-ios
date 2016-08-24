#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

@import WMFModel;

@interface TodayViewController () <NCWidgetProviding>

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    NSURL *lastRead = [[NSUserDefaults wmf_userDefaults] wmf_openArticleURL];
    if (!lastRead) {
        completionHandler(NCUpdateResultNoData);
        return;
    }
    
    //NSDate *resignActiveDate = [[NSUserDefaults wmf_userDefaults] wmf_appResignActiveDate];

    
    completionHandler(NCUpdateResultNewData);
}

@end
