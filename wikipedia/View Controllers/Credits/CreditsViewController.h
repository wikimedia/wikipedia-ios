//  Created by Monte Hurd on 4/18/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface CreditsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *wikimediaReposLabel;
@property (weak, nonatomic) IBOutlet UILabel *externalLibrariesLabel;
@property (weak, nonatomic) IBOutlet UILabel *githubLabel;
@property (weak, nonatomic) IBOutlet UILabel *gerritLabel;

@property (weak, nonatomic) IBOutlet UILabel *wikiFontLabel;
@property (weak, nonatomic) IBOutlet UILabel *hppleLabel;
@property (weak, nonatomic) IBOutlet UILabel *nsdateLabel;

@end
