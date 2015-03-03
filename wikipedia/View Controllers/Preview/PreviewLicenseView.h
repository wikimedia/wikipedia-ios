//  Created by Monte Hurd on 4/25/14.

#import <UIKit/UIKit.h>

@class PaddedLabel;

@interface PreviewLicenseView : UIView <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet PaddedLabel* licenseCCLabel;
@property (weak, nonatomic) IBOutlet PaddedLabel* licenseTitleLabel;
@property (weak, nonatomic) IBOutlet PaddedLabel* licenseLoginLabel;

@end
