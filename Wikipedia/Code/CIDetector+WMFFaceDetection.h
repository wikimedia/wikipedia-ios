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
 * @return `Promise<[CIFeature]>`
 */
- (AnyPromise*)wmf_detectFeaturelessFacesInImage:(UIImage*)image;

/// Perform `featuresInImage:options:` on a background queue, and resolve a promise with the response.
- (AnyPromise*)wmf_detectFeaturesInImage:(UIImage*)image options:(NSDictionary*)options on:(dispatch_queue_t)queue;

@end

NS_ASSUME_NONNULL_END
