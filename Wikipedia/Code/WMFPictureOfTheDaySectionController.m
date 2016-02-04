//
//  WMFPictureOfTheDaySectionController.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/23/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFPictureOfTheDaySectionController.h"
#import "MWKSite.h"
#import "MWKImageInfo.h"
#import "MWKImageInfoFetcher+PicOfTheDayInfo.h"
#import "WMFPicOfTheDayTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "NSDateFormatter+WMFExtensions.h"
#import "WMFModalImageGalleryViewController.h"
#import "UIScreen+WMFImageWidth.h"
#import "NSDateFormatter+WMFExtensions.h"

NS_ASSUME_NONNULL_BEGIN

static NSString* WMFPlaceholderImageInfoTitle = @"WMFPlaceholderImageInfoTitle";

@interface WMFPictureOfTheDaySectionController ()

@property (nonatomic, strong) MWKImageInfoFetcher* fetcher;

@property (nonatomic, strong, nullable) MWKImageInfo* imageInfo;

@property (nonatomic, strong) NSDate* fetchedDate;

@end

@implementation WMFPictureOfTheDaySectionController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.fetchedDate = [NSDate date];
    }
    return self;
}

- (MWKImageInfoFetcher*)fetcher {
    if (!_fetcher) {
        _fetcher = [[MWKImageInfoFetcher alloc] init];
    }
    return _fetcher;
}

#pragma mark - WMFBaseExploreSectionController

- (NSString*)sectionIdentifier {
    return NSStringFromClass([self class]);
}

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"potd-mini"];
}

- (UIColor*)headerIconTintColor {
    return [UIColor wmf_exploreSectionHeaderIconTintColor];
}

- (UIColor*)headerIconBackgroundColor {
    return [UIColor wmf_exploreSectionHeaderIconBackgroundColor];
}

- (NSAttributedString*)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-potd-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString*)headerSubTitle {
    return [[NSAttributedString alloc] initWithString:[[NSDateFormatter wmf_dayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.fetchedDate] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
}

- (NSString*)cellIdentifier {
    return [WMFPicOfTheDayTableViewCell wmf_nibName];
}

- (UINib*)cellNib {
    return [WMFPicOfTheDayTableViewCell wmf_classNib];
}

- (NSUInteger)numberOfPlaceholderCells {
    return 1;
}

- (nullable NSString*)placeholderCellIdentifier {
    return [WMFPicOfTheDayTableViewCell wmf_nibName];
}

- (nullable UINib*)placeholderCellNib {
    return [WMFPicOfTheDayTableViewCell wmf_classNib];
}

- (void)configureCell:(WMFPicOfTheDayTableViewCell*)cell withItem:(MWKImageInfo*)item atIndexPath:(NSIndexPath*)indexPath {
    [cell setImageURL:item.imageThumbURL];
    if (item.imageDescription.length) {
        [cell setDisplayTitle:item.imageDescription];
    } else {
        [cell setDisplayTitle:item.canonicalPageTitle];
    }
}

- (NSString*)analyticsName {
    return @"Picture of the Day";
}

- (CGFloat)estimatedRowHeight {
    return [WMFPicOfTheDayTableViewCell estimatedRowHeight];
}

- (AnyPromise*)fetchData {
    @weakify(self);
    return [self.fetcher fetchPicOfTheDaySectionInfoForDate:self.fetchedDate
                                           metadataLanguage:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]].then(^(MWKImageInfo* info) {
        @strongify(self);
        self.imageInfo = info;
        return @[self.imageInfo];
    })
           .catch(^(NSError* error) {
        @strongify(self);
        self.imageInfo = nil;
        return error;
    });
}

#pragma mark - WMFDetailProviding

- (UIViewController*)exploreDetailViewControllerForItemAtIndexPath:(NSIndexPath*)indexPath {
    return [[WMFModalImageGalleryViewController alloc] initWithInfo:self.imageInfo forDate:self.fetchedDate];
}

@end


NS_ASSUME_NONNULL_END

