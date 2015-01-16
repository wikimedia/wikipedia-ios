//
//  ShareFunnel.h
//  Wikipedia
//
//  Created by Adam Baso on 2/3/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "EventLoggingFunnel.h"

@interface WMFShareFunnel : EventLoggingFunnel

@property NSString *shareSessionToken;

-(id)initWithArticle:(MWKArticle*) article;

-(void)logHighlight;
-(void)logShareIntentWithSelection:(NSString*) selection;

/*! Log the final outcome of the share
 * @param selection the textual selection made by the user for sharing
 * @param platformOutcome the success/failure status and, if known, platform.
 * For example, "entered_card" might represent the user tapping on a visually
 * presented card. Next, if the user attempted to share something, it will
 * either succeed (yay) or fail (e.g., if connection didn't work). It's possible
 * to infer from UIActivityViewController's setCompletionHandler block what
 * the outcome was should the user be presented with the official sharing
 * activities list. And in this case it makes sense to concatenate the success
 * or failure status along with the app activity as provided in
 * setCompletionHandler.
 */
-(void)logShareWithSelection:(NSString*) selection platformOutcome: (NSString*) platformOutcome;

@end
