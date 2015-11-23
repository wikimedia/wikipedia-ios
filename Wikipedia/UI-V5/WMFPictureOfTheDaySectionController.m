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
#import "MWKImageInfoFetcher.h"
#import "WMFPicOfTheDayTableViewCell.h"
#import "UIView+WMFDefaultNib.h"

NS_ASSUME_NONNULL_BEGIN

static NSString* WMFPlaceholderImageInfoTitle = @"WMFPlaceholderImageInfoTitle";

@interface MWKSite (CommonsFactory)

+ (instancetype)wikimediaCommons;

@end

@interface MWKImageInfo (Feed)

+ (instancetype)feedPlaceholder;

- (BOOL)isFeedPlaceholder;

@end

@interface WMFPictureOfTheDaySectionController ()

@property (nonatomic, strong) MWKImageInfoFetcher* fetcher;

@property (nonatomic, strong) MWKImageInfo* imageInfo;

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
    @weakify(self);
    [self.fetcher fetchInfoForPageTitles:@[] fromSite:[MWKSite wikimediaCommons] success:^(NSArray *infoObjects) {
        @strongify(self);
        self.imageInfo = infoObjects.firstObject;
        [self.delegate controller:self didSetItems:self.items];
    } failure:^(NSError *error) {
        @strongify(self);
        [self.delegate controller:self didFailToUpdateWithError:error];
    }];
}

#pragma mark - WMFHomeSectionController

- (void)registerCellsInTableView:(UITableView *)tableView {
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

- (UITableViewCell*)dequeueCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    return [tableView dequeueReusableCellWithIdentifier:[WMFPicOfTheDayTableViewCell wmf_nibName]];
}

- (BOOL)shouldSelectItemAtIndex:(NSUInteger)index {
    // TODO: return NO for placeholder
    return NO;// self.imageInfo.canonicalPageTitle == WMFPlaceholderImageInfoTitle;
}

- (void)configureCell:(WMFPicOfTheDayTableViewCell *)cell
           withObject:(MWKImageInfo*)info
          inTableView:(UITableView *)tableView
          atIndexPath:(NSIndexPath *)indexPath {
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

- (nullable MWKTitle*)titleForItemAtIndex:(NSUInteger)index {
    // no titles here...
    return nil;
}

@end

@implementation MWKSite (CommonsFactory)

+ (instancetype)wikimediaCommons {
    return [[self alloc] initWithDomain:@"wikimedia.org" language:@"commons"];
}

@end

@implementation MWKImageInfo (Feed)

+ (instancetype)feedPlaceholder {
    return [[MWKImageInfo alloc] initWithCanonicalPageTitle:WMFPlaceholderImageInfoTitle
                                           canonicalFileURL:nil
                                           imageDescription:nil
                                                    license:nil
                                                filePageURL:nil
                                                   imageURL:nil
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

