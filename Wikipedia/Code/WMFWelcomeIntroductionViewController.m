//
//  WMFWelcomeIntroductionViewController.m
//  Wikipedia
//
//  Created by Corey Floyd on 11/24/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFWelcomeIntroductionViewController.h"

@interface WMFWelcomeIntroductionViewController ()

@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UIButton* nextStepButton;
@end

@implementation WMFWelcomeIntroductionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
