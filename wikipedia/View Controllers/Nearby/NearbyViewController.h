//  Created by Monte Hurd on 8/8/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "TopMenuViewController.h"
#import "FetcherBase.h"

@interface NearbyViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, CLLocationManagerDelegate, UIActionSheetDelegate, FetchFinishedDelegate>

@property (nonatomic) NavBarMode navBarMode;
@property (weak, nonatomic) id truePresentingVC;

@end
