#import "WMFPictureOfTheDaySectionController.h"
#import "MWKImageInfo.h"
#import "MWKImageInfoFetcher+PicOfTheDayInfo.h"
#import "WMFPicOfTheDayCollectionViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "NSDateFormatter+WMFExtensions.h"
#import "WMFImageGalleryViewController.h"
#import "UIScreen+WMFImageWidth.h"
#import "NSDateFormatter+WMFExtensions.h"
#import "Wikipedia-Swift.h"
#import "NSDate+WMFDateRanges.h"
#import <NSDate-Extensions/NSDate+Utilities.h>

NS_ASSUME_NONNULL_BEGIN

static NSUInteger const WMFDefaultNumberOfPOTDDates = 15;

static NSString *const WMFPlaceholderImageInfoTitle = @"WMFPlaceholderImageInfoTitle";

@interface WMFPictureOfTheDaySectionController () <WMFImageGalleryViewControllerReferenceViewDelegate>

@property(nonatomic, strong) MWKImageInfoFetcher *fetcher;

@property(nonatomic, strong, nullable) MWKImageInfo *imageInfo;

@property(nonatomic, strong) NSDate *fetchedDate;

@property(nonatomic, weak, nullable) UIImageView *referenceImageView;

@end

@implementation WMFPictureOfTheDaySectionController

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore date:(NSDate *)date {
    self = [super initWithDataStore:dataStore];
    if (self) {
        self.fetchedDate = date;
    }
    return self;
}

- (MWKImageInfoFetcher *)fetcher {
    if (!_fetcher) {
        _fetcher = [[MWKImageInfoFetcher alloc] init];
    }
    return _fetcher;
}

#pragma mark - WMFBaseExploreSectionController

- (NSString *)sectionIdentifier {
    return NSStringFromClass([self class]);
}

- (UIImage *)headerIcon {
    return [UIImage imageNamed:@"potd-mini"];
}

- (UIColor *)headerIconTintColor {
    return [UIColor wmf_exploreSectionHeaderIconTintColor];
}

- (UIColor *)headerIconBackgroundColor {
    return [UIColor wmf_exploreSectionHeaderIconBackgroundColor];
}

- (NSAttributedString *)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-potd-heading", nil) attributes:@{NSForegroundColorAttributeName : [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString *)headerSubTitle {
    return [[NSAttributedString alloc] initWithString:[[NSDateFormatter wmf_dayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.fetchedDate] attributes:@{NSForegroundColorAttributeName : [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
}

- (NSString *)cellIdentifier {
    return [WMFPicOfTheDayCollectionViewCell wmf_nibName];
}

- (UINib *)cellNib {
    return [WMFPicOfTheDayCollectionViewCell wmf_classNib];
}

- (NSUInteger)numberOfPlaceholderCells {
    return 1;
}

- (nullable NSString *)placeholderCellIdentifier {
    return [WMFPicOfTheDayCollectionViewCell wmf_nibName];
}

- (nullable UINib *)placeholderCellNib {
    return [WMFPicOfTheDayCollectionViewCell wmf_classNib];
}

- (void)configureCell:(WMFPicOfTheDayCollectionViewCell *)cell withItem:(MWKImageInfo *)item atIndexPath:(NSIndexPath *)indexPath {
    [cell setImageURL:item.imageThumbURL];
    if (item.imageDescription.length) {
        [cell setDisplayTitle:item.imageDescription];
    } else {
        [cell setDisplayTitle:item.canonicalPageTitle];
    }
    self.referenceImageView = cell.potdImageView;
}

- (NSString *)analyticsContentType {
    return @"Picture of the Day";
}

- (CGFloat)estimatedRowHeight {
    return [WMFPicOfTheDayCollectionViewCell estimatedRowHeight];
}

- (void)didEndDisplayingSection {
    self.referenceImageView = nil;
}

- (AnyPromise *)fetchData {
    @weakify(self);
    return [self.fetcher fetchPicOfTheDaySectionInfoForDate:self.fetchedDate
                                           metadataLanguage:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]]
        .then(^(MWKImageInfo *info) {
          @strongify(self);
          if (!self) {
              return (id)[AnyPromise promiseWithValue:[NSError cancelledError]];
          }
          self.imageInfo = info;
          return (id) @[ info ];
        })
        .catch(^(NSError *error) {
          @strongify(self);
          self.imageInfo = nil;
          return error;
        });
}

- (UIViewController *)detailViewControllerForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray<NSDate *> *dates = [[self.fetchedDate dateBySubtractingDays:WMFDefaultNumberOfPOTDDates] wmf_datesUntilDate:self.fetchedDate];
    WMFPOTDImageGalleryViewController *vc = [[WMFPOTDImageGalleryViewController alloc] initWithDates:dates selectedImageInfo:self.imageInfo];
    vc.referenceViewDelegate = self;
    return vc;
}

- (UIImageView *)referenceViewForImageController:(WMFImageGalleryViewController *)controller {
    return self.referenceImageView;
}

- (BOOL)prefersWiderColumn {
    return YES;
}

@end

NS_ASSUME_NONNULL_END
