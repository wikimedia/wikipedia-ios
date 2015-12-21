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

@interface MWKImageInfo (Feed)

+ (instancetype)feedPlaceholder;

- (BOOL)isFeedPlaceholder;

@end

@interface WMFPictureOfTheDaySectionController ()

@property (nonatomic, strong) MWKImageInfoFetcher* fetcher;

@property (nonatomic, strong, nullable) MWKImageInfo* imageInfo;

@property (nonatomic, strong) NSDate* fetchedDate;

@property (nonatomic, strong, nullable) AnyPromise* fetchRequest;

@end

@implementation WMFPictureOfTheDaySectionController
@synthesize delegate = _delegate;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.imageInfo   = [MWKImageInfo feedPlaceholder];
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

#pragma mark - Fetching

- (void)fetchDataIfNeeded {
    if (self.fetchRequest || ![self.imageInfo isFeedPlaceholder]) {
        return;
    }

    @weakify(self);
    self.fetchRequest =
        [self.fetcher fetchPicOfTheDaySectionInfoForDate:self.fetchedDate
                                        metadataLanguage:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]]
        .then(^(MWKImageInfo* info) {
        @strongify(self);
        self.imageInfo = info;
        [self.delegate controller:self didSetItems:self.items];
    })
        .catch(^(NSError* error) {
        @strongify(self);
        self.imageInfo = nil;
        [self.delegate controller:self didFailToUpdateWithError:error];
        WMF_TECH_DEBT_TODO(show empty view)
        [self.delegate controller : self didSetItems : self.items];
        DDLogError(@"POTD error: %@", error);
    })
        .finally(^{
        self.fetchRequest = nil;
    });
}

#pragma mark - WMFHomeSectionController

- (void)registerCellsInTableView:(UITableView*)tableView {
    [tableView registerNib:[WMFPicOfTheDayTableViewCell wmf_classNib]
     forCellReuseIdentifier:[WMFPicOfTheDayTableViewCell wmf_nibName]];
}

- (NSString*)sectionIdentifier {
    return NSStringFromClass([self class]);
}

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"potd-mini"];
}

- (NSAttributedString*)headerText {
    return [[NSAttributedString alloc] initWithString:
            [MWLocalizedString(@"home-potd-heading", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                    withString:[[NSDateFormatter wmf_mediumDateFormatterWithoutTime] stringFromDate:self.fetchedDate]]
                                           attributes:@{NSForegroundColorAttributeName: [UIColor wmf_homeSectionHeaderTextColor]}
    ];
}

- (UITableViewCell*)dequeueCellForTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath {
    return [tableView dequeueReusableCellWithIdentifier:[WMFPicOfTheDayTableViewCell wmf_nibName]];
}

- (BOOL)shouldSelectItemAtIndex:(NSUInteger)index {
    return ![self.imageInfo isFeedPlaceholder];
}

- (void)configureCell:(WMFPicOfTheDayTableViewCell*)cell
           withObject:(MWKImageInfo*)info
          inTableView:(UITableView*)tableView
          atIndexPath:(NSIndexPath*)indexPath {
    if ([info isFeedPlaceholder]) {
        return;
    }
    [cell setImageURL:info.imageThumbURL];
    if (info.imageDescription.length) {
        [cell setDisplayTitle:info.imageDescription];
    } else {
        [cell setDisplayTitle:info.canonicalPageTitle];
    }
}

- (NSArray*)items {
    return @[self.imageInfo];
}

- (UIViewController*)homeDetailViewControllerForItemAtIndex:(NSUInteger)index {
    NSParameterAssert(self.fetchedDate);
    NSParameterAssert(![self.imageInfo isFeedPlaceholder]);
    return [[WMFModalImageGalleryViewController alloc] initWithInfo:self.imageInfo forDate:self.fetchedDate];
}

- (NSString*)analyticsName {
    return @"Picture of the Day";
}

@end

@implementation MWKImageInfo (Feed)

+ (instancetype)feedPlaceholder {
    return [[MWKImageInfo alloc] initWithCanonicalPageTitle:WMFPlaceholderImageInfoTitle
                                           canonicalFileURL:[NSURL URLWithString:[@"/" stringByAppendingString:WMFPlaceholderImageInfoTitle]]
                                           imageDescription:nil
                                                    license:nil
                                                filePageURL:nil
                                              imageThumbURL:nil
                                                      owner:nil
                                                  imageSize:CGSizeZero
                                                  thumbSize:CGSizeZero];
}

- (BOOL)isFeedPlaceholder {
    return self.canonicalPageTitle == WMFPlaceholderImageInfoTitle;
}

@end

NS_ASSUME_NONNULL_END

