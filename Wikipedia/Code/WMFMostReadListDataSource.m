//
//  WMFMostReadListDataSource.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/16/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFMostReadListDataSource.h"
#import "WMFArticleListTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UITableViewCell+WMFLayout.h"
#import "MWKTitle.h"
#import "MWKSearchResult.h"

@interface WMFMostReadListDataSource ()

@property (nonatomic, strong) MWKSite* site;
@property (nonatomic, strong, readwrite) NSArray<MWKTitle*>* titles;

@end

@implementation WMFMostReadListDataSource

- (instancetype)initWithPreviews:(NSArray<MWKSearchResult*>*)previews fromSite:(MWKSite*)site {
    self = [super initWithItems:previews];
    if (self) {
        self.site = site;

        self.cellClass = [WMFArticleListTableViewCell class];

        @weakify(self);
        self.cellConfigureBlock = ^(WMFArticleListTableViewCell* cell,
                                    MWKSearchResult* preview,
                                    UITableView* tableView,
                                    NSIndexPath* indexPath) {
            @strongify(self);
            MWKTitle* title = [self titleForIndexPath:indexPath];
            NSParameterAssert([title.site isEqualToSite:self.site]);

            cell.titleText       = title.text;
            cell.descriptionText = preview.wikidataDescription;
            [cell setImageURL:preview.thumbnailURL];

            [cell wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0];
        };
    }
    return self;
}

- (void)setTableView:(UITableView*)tableView {
    [tableView registerNib:[WMFArticleListTableViewCell wmf_classNib]
     forCellReuseIdentifier:[WMFArticleListTableViewCell identifier]];
    tableView.estimatedRowHeight = [WMFArticleListTableViewCell estimatedRowHeight];
    [super setTableView:tableView];
}

#pragma mark - Utils

- (MWKTitle*)titleForPreview:(MWKSearchResult*)preview {
    return [[MWKTitle alloc] initWithSite:self.site normalizedTitle:preview.displayTitle fragment:nil];
}

#pragma mark - WMFTitleListDataSource

- (MWKTitle*)titleForIndexPath:(NSIndexPath*)indexPath {
    return [self titleForPreview:[self itemAtIndexPath:indexPath]];
}

- (NSUInteger)titleCount {
    return self.allItems.count;
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath {
    return NO;
}

- (NSArray<MWKTitle*>*)titles {
    if (!_titles) {
        self.titles = [self.allItems bk_map:^MWKTitle*(MWKSearchResult* preview) {
            return [self titleForPreview:preview];
        }];
    }
    return _titles;
}

@end
