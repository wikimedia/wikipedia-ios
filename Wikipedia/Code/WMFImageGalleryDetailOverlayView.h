@import UIKit;

@class MWKLicense;

@interface WMFImageGalleryDetailOverlayView : UIView
@property (nonatomic, copy) NSString *imageDescription;
@property (nonatomic, assign) BOOL imageDescriptionIsRTL;
@property (nonatomic, copy) dispatch_block_t ownerTapCallback;
@property (nonatomic, copy) dispatch_block_t infoTapCallback;
@property (nonatomic, copy) dispatch_block_t descriptionTapCallback;
@property (nonatomic, assign) CGFloat maximumDescriptionHeight;

- (void)toggleDescriptionOpenState;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (void)setLicense:(MWKLicense *)license owner:(NSString *)owner;

@end
