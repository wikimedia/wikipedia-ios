//
//  CIDetector+WMFFaceDetection.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/20/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

@class AnyPromise;

NS_ASSUME_NONNULL_BEGIN

@interface CIDetector (WMFFaceDetection)

/**
 * Singleton `CIDetector` configured to detect faces in the background.
 */
+ (instancetype)wmf_sharedBackgroundFaceDetector;

/**
 * Asynchronously detect faces in `image`, without doing extra processing for smiles or eyes.
 */
- (void)wmf_detectFeaturelessFacesInImage:(UIImage*)image failure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success;

/// Perform `featuresInImage:options:` on a background queue
- (void)wmf_detectFeaturesInImage:(UIImage*)image options:(NSDictionary*)options on:(dispatch_queue_t)queue failure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success;

@end

NS_ASSUME_NONNULL_END
