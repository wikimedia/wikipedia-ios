//
//  WMFKVOUpdatableListView.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/22/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WMFKVOUpdatableList <NSObject>

- (void)wmf_updateIndexes:(NSIndexSet*)indexes
                inSection:(NSInteger)section
            forChangeKind:(NSKeyValueChange)changeKind;

@end

NS_ASSUME_NONNULL_END
