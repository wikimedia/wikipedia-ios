#import <Foundation/Foundation.h>
#import "WMFAnalyticsLogging.h"

@class MWKSavedPageList, MWKSavedPageList;

@interface WMFSaveButtonController : NSObject

@property(copy, nonatomic) NSURL *url;
@property(strong, nonatomic) UIControl *control;
@property(strong, nonatomic) UIBarButtonItem *barButtonItem;
@property(strong, nonatomic) MWKSavedPageList *savedPageList;

- (instancetype)initWithControl:(UIControl *)button
                  savedPageList:(MWKSavedPageList *)savedPageList
                            url:(NSURL *)url;

- (instancetype)initWithBarButtonItem:(UIBarButtonItem *)barButtonItem
                        savedPageList:(MWKSavedPageList *)savedPageList
                                  url:(NSURL *)url;
/**
 *  Set to provide a source for logging saved pages
 */
@property(weak, nonatomic) id<WMFAnalyticsContextProviding> analyticsContext;
@property(weak, nonatomic) id<WMFAnalyticsContentTypeProviding> analyticsContentType;

@end
