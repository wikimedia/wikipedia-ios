//  Created by Monte Hurd on 12/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface WMFFaceDetector : NSObject

@property (nonatomic, strong) UIImage* image;

/*
   "detectFace" returns rect for largest face in "self.image".

   Subsequent calls to "detectFace" return next largest face rect,
   rolling back to first face after last face.

   It only actually runs face detection on the first call.
   Internally cached results are returned on subsequent calls.
 */
- (CGRect)detectFace;

@end
