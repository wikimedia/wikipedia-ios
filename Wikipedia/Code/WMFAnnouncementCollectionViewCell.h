#import "WMFExploreCollectionViewCell.h"
@import WMF.Swift;

NS_ASSUME_NONNULL_BEGIN

@class WMFAnnouncementCollectionViewCell;

@protocol WMFAnnouncementCollectionViewCellDelegate <NSObject>

- (void)announcementCellDidTapDismiss:(WMFAnnouncementCollectionViewCell *)cell;
- (void)announcementCellDidTapActionButton:(WMFAnnouncementCollectionViewCell *)cell;
- (void)announcementCell:(WMFAnnouncementCollectionViewCell *)cell didTapLinkURL:(NSURL *)url;

@end

@interface WMFAnnouncementCollectionViewCell : WMFExploreCollectionViewCell <WMFThemeable>

@property (nonatomic, weak) id<WMFAnnouncementCollectionViewCellDelegate> delegate;

- (void)setImageURL:(NSURL *)imageURL;
- (void)setImage:(UIImage *)image;
- (void)setMessageText:(NSString *)text;
- (void)setActionText:(NSString *)text;

@property (nonatomic, readonly) IBOutlet UIButton *actionButton;
@property (nonatomic, copy, nullable) NSAttributedString *caption;

+ (CGFloat)estimatedRowHeightWithImage:(BOOL)withImage;

@end

NS_ASSUME_NONNULL_END
