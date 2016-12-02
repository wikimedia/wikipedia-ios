//
//  SSBaseTableCell.h
//  SSDataSources
//
//  Created by Jonathan Hersh on 1/5/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * A simple base table cell. Subclass me and override configureCell
 * to add custom one-time logic (e.g. creating subviews).
 * Override cellStyle to use a different style.
 * You probably don't need to override identifier.
 */

@interface SSBaseTableCell : UITableViewCell

/**
 * Dequeues a table cell from tableView, or if there are no cells of the
 * receiver's type in the queue, creates a new cell and calls -configureCell.
 */
+ (instancetype) cellForTableView:(UITableView *)tableView;

/**
 *  Cell's identifier. You probably don't need to override me.
 *
 *  @return an identifier for this cell class
 */
+ (NSString *) identifier;

/**
 *  Cell style to use. Override me in a subclass and return a different style.
 *
 *  @return cell style to use for this class
 */
+ (UITableViewCellStyle) cellStyle;

/**
 *  Called once for each cell after initial creation.
 *  Subclass me for one-time logic, like creating subviews.
 */
- (void) configureCell;

@end
