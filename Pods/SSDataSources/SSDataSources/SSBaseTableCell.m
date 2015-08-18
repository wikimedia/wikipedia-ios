//
//  SSBaseTableCell.m
//  SSDataSources
//
//  Created by Jonathan Hersh on 1/5/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSBaseTableCell.h"

@implementation SSBaseTableCell

+ (NSString *)identifier {
    return NSStringFromClass(self);
}

+ (UITableViewCellStyle)cellStyle {
    return UITableViewCellStyleDefault;
}

+ (instancetype)cellForTableView:(UITableView *)tableView {
    SSBaseTableCell *cell = (SSBaseTableCell *)[tableView dequeueReusableCellWithIdentifier:[self identifier]];
    
    if (!cell) {
        cell = [[self alloc] initWithStyle:[self cellStyle]
                           reuseIdentifier:[self identifier]];
        
        [cell configureCell];
    }
    
    return cell;
}

- (void) configureCell {
    // override me!
}

@end
