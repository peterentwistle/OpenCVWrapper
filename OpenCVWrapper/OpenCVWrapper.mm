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
CascadeClassifier anger_cascade;
CascadeClassifier contempt_cascade;
CascadeClassifier fear_cascade;
CascadeClassifier neutral_cascade;
CascadeClassifier sadness_cascade;
CascadeClassifier surprise_cascade;

//cv::CascadeClassifier cascade;

typedef struct VectorOfCvRects {
	std::vector<cv::Rect> val = *new std::vector<cv::Rect>();
} *VectorOfCvRect;

typedef struct CvMats {
	cv::Mat val;
} *CvMatrix;

- (id)init {
    self = [super init];
    
    // Load face cascade
    [self loadCascadeClassifier: face_cascade fileName:@"haarcascade_frontalface_alt"];

    // Load eye cascade
    [self loadCascadeClassifier: eyes_cascade fileName:@"haarcascade_eye_tree_eyeglasses"];
    
    // Load Emotion classifiers
    
    // Happiness
    [self loadCascadeClassifier: happiness_cascade fileName:@"happiness"];
    
    // Anger
    [self loadCascadeClassifier: anger_cascade fileName:@"anger"];
    
    // Contempt
    [self loadCascadeClassifier: contempt_cascade fileName:@"contempt"];
    
    //  Fear
    [self loadCascadeClassifier: fear_cascade fileName:@"fear"];
    
    // Neutral
    [self loadCascadeClassifier: neutral_cascade fileName:@"neutral"];
    
    // Sadness
    [self loadCascadeClassifier: sadness_cascade fileName:@"sadness"];

    // Surprise
    [self loadCascadeClassifier: surprise_cascade fileName:@"surprise"];
    
    return self;
}

void rotate90(cv::Mat &mat) {
    // Rotate matrix 90 degrees clockwise
    transpose(mat, mat);
    flip(mat, mat, 1);
}

- (void)loadCascadeClassifier:(CascadeClassifier&)cascade fileName:(NSString*)fileName {
    NSBundle *bundle = [NSBundle mainBundle];
    
    NSString *path = [bundle pathForResource:fileName ofType:@"xml"];
    string cascadePath = (char *)[path UTF8String];
    
    if (!cascade.load(cascadePath)) {
        return nil;
    }
}

- (DetectedResult *)detectAndDisplay:(UIImage*)input {
    std::vector<cv::Rect> faces;
    Mat frame_gray;
    Mat frame;
    
    UIImageToMat(input, frame);
    
    //rotate90(frame);
    
    cvtColor(frame, frame_gray, COLOR_BGR2GRAY);
    equalizeHist(frame_gray, frame_gray);
    
    // Only going to work for one emotion for now
    DetectedEmotion *detectedEmotion;
    
    // Detect faces
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
    // Convert the matrix to a UIImage
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

@end
