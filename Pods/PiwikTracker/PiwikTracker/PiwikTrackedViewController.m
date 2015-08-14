//
//  PTViewController.m
//  PiwikTracker
//
//  Created by Mattias Levin on 8/12/13.
//  Copyright (c) 2013 Mattias Levin. All rights reserved.
//

#import "PiwikTrackedViewController.h"
#import "PiwikTracker.h"


@interface PiwikTrackedViewController ()
@end


@implementation PiwikTrackedViewController


-(void)viewDidAppear:(BOOL)animated {
  
  [super viewDidAppear:animated];
  
  // Track as screen view
  NSString *name;
  if (self.trackedViewName) {
    name = self.trackedViewName;
  } else if (self.title) {
    name = self.title;
  }

  if (name) {
    [[PiwikTracker sharedInstance] sendView:name];
  }

}


@end
