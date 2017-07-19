#import "WMFExploreCollectionViewCell.h"
@import WMF.Swift;

@class WMFAnnouncementCollectionViewCell;

@protocol WMFAnnouncementCollectionViewCellDelegate <NSObject>

- (void)announcementCellDidTapDismiss:(WMFAnnouncementCollectionViewCell *)cell;
- (void)announcementCellDidTapActionButton:(WMFAnnouncementCollectionViewCell *)cell;
- (void)announcementCell:(WMFAnnouncementCollectionViewCell *)cell didTapLinkURL:(NSURL *)url;

@end

@interface WMFAnnouncementCollectionViewCell : WMFExploreCollectionViewCell <WMFThemeable>

@property (nonatomic, weak) id<WMFAnnouncementCollectionViewCellDelegate> delegate;

- (void)setImageURL:(NSURL *)imageURL;
- (void)setMessageText:(NSString *)text;
- (void)setActionText:(NSString *)text;

@property (nonatomic, copy) NSAttributedString *caption;

+ (CGFloat)estimatedRowHeightWithImage:(BOOL)withImage;

@end
