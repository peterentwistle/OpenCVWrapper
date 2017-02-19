//
//  OpenCVWrapper.mm
//  OpenCVTest
//
//  Created by Peter Entwistle on 03/10/2016.
//  Copyright © 2016 Peter Entwistle. All rights reserved.
//

#include "OpenCVWrapper.h"
#import <opencv2/highgui/ios.h>

using namespace cv;
using namespace std;

@implementation OpenCVWrapper : NSObject

static int _color_BGR2GRAY = 6;

CascadeClassifier face_cascade;
CascadeClassifier eyes_cascade;
CascadeClassifier happiness_cascade;

cv::CascadeClassifier cascade;

typedef struct VectorOfCvRects {
	std::vector<cv::Rect> val = *new std::vector<cv::Rect>();
} *VectorOfCvRect;

typedef struct CvMats {
	cv::Mat val;
} *CvMatrix;

- (id)init {
    self = [super init];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *pathFace = [bundle pathForResource:@"haarcascade_frontalface_alt" ofType:@"xml"];
    std::string faceCascadePath = (char *)[pathFace UTF8String];
    
    if (!face_cascade.load(faceCascadePath)) {
        return nil;
    }

    NSString *pathEye = [bundle pathForResource:@"haarcascade_eye_tree_eyeglasses" ofType:@"xml"];
    std::string eyeCascadePath = (char *)[pathEye UTF8String];
    
    if (!eyes_cascade.load(eyeCascadePath)) {
        return nil;
    }
    
    NSString *pathHappiness = [bundle pathForResource:@"happiness" ofType:@"xml"];
    string happinessCascadePath = (char *)[pathHappiness UTF8String];
    
    if (!happiness_cascade.load(happinessCascadePath)) {
        return nil;
    }
    
    return self;
}
/*
 Broken atm
- (UIImage *)detectAndDisplay:(UIImage*)input {
    VectorOfCvRect faces;
    Mat frame_gray;
    Mat frame;
    
    UIImageToMat(input, frame);
    
    cvtColor(frame, frame_gray, COLOR_BGR2GRAY);
    equalizeHist(frame_gray, frame_gray);
	
    //-- Detect faces
    face_cascade.detectMultiScale(frame_gray, faces->val, 1.1, 2, 0|CASCADE_SCALE_IMAGE, cv::Size(30, 30));
    
    for (size_t i = 0; i < faces->val.size(); i++) {
        cv::Point center(faces->val[i].x + faces->val[i].width/2, faces->val[i].y + faces->val[i].height/2);
        ellipse(frame, center, cv::Size(faces->val[i].width/2, faces->val[i].height/2), 0, 0, 360, Scalar(255, 0, 255), 4, 8, 0);
        
        Mat faceROI = frame_gray(faces->val[i]);
        std::vector<cv::Rect> eyes;
        
        //-- In each face, detect eyes
        eyes_cascade.detectMultiScale(faceROI, eyes, 1.1, 2, 0 |CASCADE_SCALE_IMAGE, cv::Size(30, 30));
        
        for (size_t j = 0; j < eyes.size(); j++) {
            cv::Point eye_center(faces->val[i].x + eyes[j].x + eyes[j].width/2, faces->val[i].y + eyes[j].y + eyes[j].height/2);
            int radius = cvRound((eyes[j].width + eyes[j].height)*0.25);
            circle(frame, eye_center, radius, Scalar(255, 0, 0), 4, 8, 0);
        }
    }
    //-- Show what you got
    UIImage *resultImage = MatToUIImage(frame);
    return resultImage;
}
*/
- (DetectedResult *)detectAndDisplay:(UIImage*)input {
    std::vector<cv::Rect> faces;
    Mat frame_gray;
    Mat frame;
    
    UIImageToMat(input, frame);
    
    cvtColor(frame, frame_gray, COLOR_BGR2GRAY);
    equalizeHist(frame_gray, frame_gray);
    
    // Only going to work for one emotion for now
    DetectedEmotion *detectedEmotion;
    
    //-- Detect faces
    face_cascade.detectMultiScale(frame_gray, faces, 1.1, 2, 0|CASCADE_SCALE_IMAGE, cv::Size(30, 30));
    
    for (size_t i = 0; i < faces.size(); i++) {
        cv::Point center(faces[i].x + faces[i].width/2, faces[i].y + faces[i].height/2);
        ellipse(frame, center, cv::Size(faces[i].width/2, faces[i].height/2), 0, 0, 360, Scalar(255, 0, 255), 4, 8, 0);
        
        Mat faceROI = frame_gray(faces[i]);
        std::vector<cv::Rect> eyes;
        
        // Detect emotions
        detectedEmotion = [self detectHappiness:faceROI];
        
        //-- In each face, detect eyes
        eyes_cascade.detectMultiScale(faceROI, eyes, 1.1, 2, 0 |CASCADE_SCALE_IMAGE, cv::Size(30, 30));
        
        for (size_t j = 0; j < eyes.size(); j++) {
            cv::Point eye_center(faces[i].x + eyes[j].x + eyes[j].width/2, faces[i].y + eyes[j].y + eyes[j].height/2);
            int radius = cvRound((eyes[j].width + eyes[j].height)*0.25);
            circle(frame, eye_center, radius, Scalar(255, 0, 0), 4, 8, 0);
        }
    }
    //-- Show what you got
    UIImage *resultImage = MatToUIImage(frame);
    
    DetectedResult *result = [[DetectedResult alloc] initWithDetectedEmotion:(detectedEmotion) frame:resultImage];
    return result;
}

- (DetectedEmotion *)detectHappiness:(Mat)frame {
    std::vector<cv::Rect> happiness_faces;
    
    happiness_cascade.detectMultiScale(frame, happiness_faces, 1.1, 2, 0|CASCADE_SCALE_IMAGE, cv::Size(30, 30));
    
    for (size_t i = 0; i < happiness_faces.size(); i++) {
        printf("Happiness detected! At x: %d, y: %d width: %d height: %d \n", happiness_faces[i].x, happiness_faces[i].y, happiness_faces[i].width, happiness_faces[i].height);
    }
    
    //frame: UIImage, emotion: Emotion, emotionFace: UIImage
    Emotion emotion = EmotionNone;
    
    if (happiness_faces.size() > 0) {
        emotion = EmotionHappiness;
    }
    
    DetectedEmotion *detectedEmotion = [[DetectedEmotion alloc] initWithFrame:MatToUIImage(frame) emotion:emotion];
    return detectedEmotion;
}

/*
- (UIImage *)detectAndDisplay:(UIImage*)input {
    cv::Rect roi = [self detectROI: input];
    cv::Mat image_roi;
    
    std::vector<cv::Rect> faces;
    Mat frame_gray;
    Mat frame;
    
    UIImageToMat(input, frame);

    //video >> frame; // get a new frame from camera
    
    //if (frame.refcount == 0) break;
    
    //cv::Rect roi(458-50, 250-50, 320, 320);
    
    
    image_roi = frame(roi);
    
    cvtColor(image_roi, frame_gray, COLOR_BGR2GRAY);
    equalizeHist(frame_gray, frame_gray);
    
    //-- Detect faces
    face_cascade.detectMultiScale(frame_gray, faces, 1.1, 2, 0|CASCADE_SCALE_IMAGE, cv::Size(30, 30));
    
    for (size_t i = 0; i < faces.size(); i++) {
        
        // print out face location
        printf("Face x: %d, y: %d width: %d height: %d \n", faces[i].x, faces[i].y, faces[i].width, faces[i].height);
        
        // Define ROI
        //cv::Rect roi(faces[i].x, mfaces[i].y, faces[i].width, faces[i].height);
        
        cv::Point center(faces[i].x + faces[i].width/2, faces[i].y + faces[i].height/2);
        ellipse(image_roi, center, cv::Size(faces[i].width/2, faces[i].height/2), 0, 0, 360, Scalar(255, 0, 255), 4, 8, 0);
        //cv::rectangle(image_roi, cv::Point(faces[i].x, faces[i].y), cv::Point(faces[i].width + faces[i].x, faces[i].height + faces[i].y), Scalar(255, 0, 255), 4);
        
        Mat faceROI = frame_gray(faces[i]);
        std::vector<cv::Rect> eyes;
        
        //-- In each face, detect eyes
        eyes_cascade.detectMultiScale(faceROI, eyes, 1.1, 2, 0 |CASCADE_SCALE_IMAGE, cv::Size(30, 30));
        
        // Detect mouth region
        if (eyes.size() == 2) {
            cv::Point firstEyeCenter = [self centerOfEye:faces eyes:eyes faceNumber:i eyeNumber:0]; //(faces[i].x + eyes[0].x + eyes[0].width/2, faces[i].y + eyes[0].y + eyes[0].height/2);
            cv::Point secondEyeCenter = [self centerOfEye:faces eyes:eyes faceNumber:i eyeNumber:1]; //cv::Point secondEyeCenter(faces[i].x + eyes[1].x + eyes[1].width/2, faces[i].y + eyes[1].y + eyes[1].height/2);
            
            int eyeDistance = secondEyeCenter.x - firstEyeCenter.x;
            //printf("Eye distance is: %d", eyeDistance);
            
            int topMouth = 0.85 * eyeDistance;
            int bottomMouth = 0.65 * eyeDistance;
            int topMouthY = firstEyeCenter.y + topMouth;
            int bottomMouthY = firstEyeCenter.y + bottomMouth + topMouth;
            
            cv::rectangle(image_roi, cv::Point(faces[i].x, topMouthY), cv::Point(faces[i].width + faces[i].x, bottomMouthY), Scalar(0, 255, 255), 4);
        }
        
        for (size_t j = 0; j < eyes.size(); j++) {
            cv::Point eye_center(faces[i].x + eyes[j].x + eyes[j].width/2, faces[i].y + eyes[j].y + eyes[j].height/2); // could use centerOfEye
            int radius = cvRound((eyes[j].width + eyes[j].height)*0.25);
            circle(image_roi, eye_center, radius, Scalar(255, 0, 0), 4, 8, 0);
        }
    }
    
    //imshow("Test", image_roi);
    //if(waitKey(30) >= 0) break;
    
    
    //-- Show what you got
    UIImage *resultImage = MatToUIImage(image_roi);
    return resultImage;
}
*/
- (cv::Point)centerOfEye:(std::vector<cv::Rect>)faces eyes:(std::vector<cv::Rect>)eyes faceNumber:(int)faceNumber eyeNumber:(int)eyeNumber {
    return cv::Point (faces[faceNumber].x + eyes[eyeNumber].x + eyes[eyeNumber].width/2, faces[faceNumber].y + eyes[eyeNumber].y + eyes[eyeNumber].height/2);
}

- (cv::Rect)detectROI:(UIImage*)input {
    cv::Rect roi;
    
    std::vector<cv::Rect> faces;
    Mat frame_gray;
    Mat frame;
    
    UIImageToMat(input, frame);

    //if (frame.refcount == 0) break;
    
    cvtColor(frame, frame_gray, COLOR_BGR2GRAY);
    equalizeHist(frame_gray, frame_gray);
    
    //-- Detect faces
    face_cascade.detectMultiScale(frame_gray, faces, 1.1, 2, 0|CASCADE_SCALE_IMAGE, cv::Size(30, 30));
    
    for (size_t i = 0; i < faces.size(); i++) {
        
        // print out face location
        //printf("Face x: %d, y: %d width: %d height: %d \n", faces[i].x, faces[i].y, faces[i].width, faces[i].height);
        
        int padCoord = 50;
        int padWH = 100;
        
        // Define ROI
        cv::Rect roi(faces[i].x - padCoord, faces[i].y - padCoord, faces[i].width + padWH, faces[i].height + padWH);
        return roi;
    }
    
    return roi;
}


+ (void)UIImageToMat:(UIImage*)input frame:(CvMats*)frame {
	UIImageToMat(input, frame->val);
}

+ (void)cvtColor:(CvMats*)input output:(CvMats*)output color:(int)color {
	cvtColor(input->val, output->val, color);
}

+ (void)equalizeHist:(CvMats*)input output:(CvMats*)output {
	equalizeHist(input->val, output->val);
}


/*
// WORKING VERSION

 - (UIImage *)detectAndDisplay:(UIImage*)input {
     std::vector<cv::Rect> faces;
     Mat frame_gray;
     Mat frame;
     
     UIImageToMat(input, frame);
     
     cvtColor(frame, frame_gray, COLOR_BGR2GRAY);
     equalizeHist(frame_gray, frame_gray);
     
     //-- Detect faces
     face_cascade.detectMultiScale(frame_gray, faces, 1.1, 2, 0|CASCADE_SCALE_IMAGE, cv::Size(30, 30));
     
     for (size_t i = 0; i < faces.size(); i++) {
         cv::Point center(faces[i].x + faces[i].width/2, faces[i].y + faces[i].height/2);
         ellipse(frame, center, cv::Size(faces[i].width/2, faces[i].height/2), 0, 0, 360, Scalar(255, 0, 255), 4, 8, 0);
         
         Mat faceROI = frame_gray(faces[i]);
         std::vector<cv::Rect> eyes;
         
         //-- In each face, detect eyes
         eyes_cascade.detectMultiScale(faceROI, eyes, 1.1, 2, 0 |CASCADE_SCALE_IMAGE, cv::Size(30, 30));
         
         for (size_t j = 0; j < eyes.size(); j++) {
             cv::Point eye_center(faces[i].x + eyes[j].x + eyes[j].width/2, faces[i].y + eyes[j].y + eyes[j].height/2);
             int radius = cvRound((eyes[j].width + eyes[j].height)*0.25);
             circle(frame, eye_center, radius, Scalar(255, 0, 0), 4, 8, 0);
         }
     }
     //-- Show what you got
     UIImage *resultImage = MatToUIImage(frame);
     return resultImage;
 }
*/
/*
+ (UIImage *)recognizeFace:(UIImage *)image {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat mat(rows, cols, CV_8UC4);
    
    CGContextRef contextRef = CGBitmapContextCreate(mat.data,
                                                    cols,
                                                    rows,
                                                    8,
                                                    mat.step[0],
                                                    colorSpace,
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    
    std::vector<cv::Rect> faces;
    cascade.detectMultiScale(mat, faces,
                             1.1, 2,
                             CV_HAAR_SCALE_IMAGE,
                             cv::Size(30, 30));

    std::vector<cv::Rect>::const_iterator r = faces.begin();
    for(; r != faces.end(); ++r) {
        cv::Point center;
        int radius;
        center.x = cv::saturate_cast<int>((r->x + r->width*0.5));
        center.y = cv::saturate_cast<int>((r->y + r->height*0.5));
        radius = cv::saturate_cast<int>((r->width + r->height) / 2);
        cv::circle(mat, center, radius, cv::Scalar(80,80,255), 3, 8, 0 );
    }
    
    UIImage *resultImage = MatToUIImage(mat);
    
    return resultImage;
}
*/

@end
