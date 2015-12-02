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
#import "WMFModalPOTDGalleryViewController.h"
#import "UIScreen+WMFImageWidth.h"

NS_ASSUME_NONNULL_BEGIN

static NSString* WMFPlaceholderImageInfoTitle = @"WMFPlaceholderImageInfoTitle";

@interface MWKImageInfo (Feed)

+ (instancetype)feedPlaceholder;

- (BOOL)isFeedPlaceholder;

@end

@interface WMFPictureOfTheDaySectionController ()

@property (nonatomic, strong) MWKImageInfoFetcher* fetcher;

@property (nonatomic, strong) MWKImageInfo* imageInfo;

@property (nonatomic, strong, nullable) NSDate* fetchedDate;

@end

@implementation WMFPictureOfTheDaySectionController
@synthesize delegate = _delegate;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.imageInfo = [MWKImageInfo feedPlaceholder];
        [self fetchData];
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

- (void)fetchData {
    self.fetchedDate = [NSDate date];

    @weakify(self);
    [self.fetcher fetchPicOfTheDaySectionInfoForDate:self.fetchedDate
                                    metadataLanguage:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]]
    .then(^(NSArray<MWKImageInfo*>* imageInfoObjects) {
        @strongify(self);
        NSParameterAssert(imageInfoObjects.count == 1);
        self.imageInfo = imageInfoObjects.firstObject;
        [self.delegate controller:self didSetItems:self.items];
    })
    .catch(^(NSError* error) {
        @strongify(self);
        [self.delegate controller:self didFailToUpdateWithError:error];
        self.fetchedDate = nil;
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
    // TEMP: need to make some more changes to have a "headerless" section which matches spec
    return [[NSAttributedString alloc] initWithString:@"Today's picture"];
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

- (UIViewController*)homeDetailViewControllerAtIndex:(NSUInteger)index {
    NSParameterAssert(self.fetchedDate);
    NSParameterAssert(![self.imageInfo isFeedPlaceholder]);
    return [[WMFModalPOTDGalleryViewController alloc] initWithInfo:self.imageInfo forDate:self.fetchedDate];
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

