//
//  ShareOptionsViewController.h
//  Wikipedia
//
//  Created by Adam Baso on 2/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WMFShareOptionsViewControllerDelegate

-(void) didShowSharePreviewForMWKArticle: (MWKArticle*) article withText: (NSString*) text;
-(void) tappedBackgroundToAbandonWithText: (NSString*) text;
-(void) tappedShareCardWithText: (NSString*) text;
-(void) tappedShareTextWithText: (NSString*) text;
-(void) finishShareWithActivityItems: (NSArray*) activityItems text: (NSString*) text;
@end

@interface WMFShareOptionsViewController : UIViewController

@property (readonly) MWKArticle *article;
@property (readonly) NSString *snippet;
@property (readonly) UIView *backgroundView;
@property (readonly) id<WMFShareOptionsViewControllerDelegate> delegate;

- (instancetype)initWithMWKArticle: (MWKArticle*) article snippet: (NSString *) snippet backgroundView: (UIView*) backgroundView delegate: (id) delegate;
@end
