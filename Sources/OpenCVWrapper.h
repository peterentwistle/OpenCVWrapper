//
//  OpenCVWrapper.h
//  OpenCVTest
//
//  Created by Peter Entwistle on 03/10/2016.
//  Copyright © 2016 Peter Entwistle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import <opencv2/highgui/cap_ios.h>

#import "opencv2/objdetect.hpp"
#import "opencv2/highgui.hpp"
#import "opencv2/imgproc.hpp"

typedef struct VectorOfCvRects *VectorOfCvRect;
typedef struct CvMats *CvMatrix;

@class DetectedResult;

@interface OpenCVWrapper : NSObject

@property (class, nonatomic, assign, readonly) int color_BGR2GRAY;
//+ (UIImage *)processImageWithOpenCV:(UIImage*)inputImage;

//+ (void)detectFace:(UIImage*)image;

//+ (UIImage *)recognizeFace:(UIImage *)image;



- (DetectedResult *)detectAndDisplay:(UIImage*)input;

+ (void)UIImageToMat:(UIImage*)input frame:(CvMatrix*)frame;

+ (void)cvtColor:(CvMatrix*)input output:(CvMatrix*)output color:(int)color;

+ (void)equalizeHist:(CvMatrix*)input output:(CvMatrix*)output;

@end
