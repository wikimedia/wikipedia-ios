//
//  WMFRangeUtils.h
//  Wikipedia
//
//  Created by Brian Gerstle on 3/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

extern inline BOOL WMFRangeIsNotFoundOrEmpty(NSRange const range);

extern inline NSRange WMFRangeMakeNotFound();

extern inline NSUInteger WMFRangeGetMaxIndex(NSRange const range);