//
//  SSBaseHeaderFooterView.h
//  ExampleSSDataSources
//
//  Created by Jonathan Hersh on 8/29/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

/**
 * A simple header/footer class for tableviews.
 * Subclass me if necessary.
 */

#import <UIKit/UIKit.h>

@interface SSBaseHeaderFooterView : UITableViewHeaderFooterView

/**
 * Reuse identifier. You probably don't need to override this.
 */
+ (NSString *) identifier;

/**
 * Default constructor. 
 * Automatically uses a reuse identifier as defined in `+identifier`.
 */
- (instancetype) init;

@end
