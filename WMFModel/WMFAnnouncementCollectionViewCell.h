#import "WMFExploreCollectionViewCell.h"

@class WMFAnnouncementCollectionViewCell;

@protocol WMFAnnouncementCollectionViewCellDelegate <NSObject>

- (void)announcementCellDidTapDismiss:(WMFAnnouncementCollectionViewCell *)cell;
- (void)announcementCellDidTapActionButton:(WMFAnnouncementCollectionViewCell *)cell;
- (void)announcementCell:(WMFAnnouncementCollectionViewCell *)cell didTapLinkURL:(NSURL *)url;

@end

@interface WMFAnnouncementCollectionViewCell : WMFExploreCollectionViewCell

@property (nonatomic, weak) id<WMFAnnouncementCollectionViewCellDelegate> delegate;

- (void)setImageURL:(NSURL *)imageURL;
- (void)setMessageText:(NSString *)text;
- (void)setActionText:(NSString *)text;
- (void)setCaptionHTML:(NSString *)text;

+ (CGFloat)estimatedRowHeightWithImage:(BOOL)withImage;

@end
