//
//  ShareFunnel.h
//  Wikipedia
//
//  Created by Adam Baso on 2/3/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "EventLoggingFunnel.h"

@interface WMFShareFunnel : EventLoggingFunnel

- (id)initWithArticle:(MWKArticle *)article;

- (void)logHighlight;
- (void)logShareButtonTappedResultingInSelection:(NSString *)selection;
- (void)logAbandonedAfterSeeingShareAFact;
- (void)logShareAsImageTapped;
- (void)logShareAsTextTapped;

/*! Log the final outcome of the share as a failure
 * @param shareMethod System provided share application string if known
 */
- (void)logShareFailedWithShareMethod:(NSString *)shareMethod;

/*! Log the final outcome of the share as a success
 * @param shareMethod System provided share application string if known
 */
- (void)logShareSucceededWithShareMethod:(NSString *)shareMethod;

@end
