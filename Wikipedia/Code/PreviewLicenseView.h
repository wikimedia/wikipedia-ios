#import "WMFOpenExternalLinkDelegateProtocol.h"

@class PaddedLabel;
@protocol PreviewLicenseViewDelegate;
@interface PreviewLicenseView : UIView

@property (weak, nonatomic) IBOutlet PaddedLabel *licenseCCLabel;
@property (weak, nonatomic) IBOutlet PaddedLabel *licenseTitleLabel;
@property (weak, nonatomic) IBOutlet PaddedLabel *licenseLoginLabel;

@property (nonatomic, weak) id<PreviewLicenseViewDelegate> previewLicenseViewDelegate;

@end

@protocol PreviewLicenseViewDelegate <NSObject>
@required
- (void)previewLicenseViewTermsLicenseLabelWasTapped:(PreviewLicenseView *)previewLicenseview;
@end
