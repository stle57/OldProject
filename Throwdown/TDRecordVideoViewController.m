//
//  TDRecordVideoViewController.m
//  Throwdown
//
//  Created by Andrew C on 1/16/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDRecordVideoViewController.h"
#import "TDEditVideoViewController.h"
#import "GPUImage.h"

#define MOVIE_FILE_PATH @"Documents/WorkingMovie.m4v"

@interface TDRecordVideoViewController ()
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet GPUImageView *previewLayer;

@property GPUImageCropFilter<GPUImageInput> *filter;
@property GPUImageMovieWriter *movieWriter;
@property GPUImageVideoCamera *videoCamera;
@property BOOL isRecording;

- (IBAction)recordButtonPressed:(UIButton *)sender;
- (IBAction)closeButtonPressed:(UIButton *)sender;
@end

@implementation TDRecordVideoViewController

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];


    self.isRecording = NO;

    self.videoCamera = [[GPUImageVideoCamera alloc]
                        initWithSessionPreset:AVCaptureSessionPreset640x480
                        cameraPosition:AVCaptureDevicePositionBack];

    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;

    self.filter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, 0.125f, 1.f, .75f)];
    [self.filter addTarget:self.previewLayer];

    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:MOVIE_FILE_PATH];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];

    int videoSize = 640;

    NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
    [settings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
    [settings setObject:[NSNumber numberWithInt:videoSize] forKey:AVVideoWidthKey];
    [settings setObject:[NSNumber numberWithInt:videoSize] forKey:AVVideoHeightKey];

    NSDictionary *videoCleanApertureSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithInt:videoSize], AVVideoCleanApertureWidthKey,
                                                [NSNumber numberWithInt:videoSize], AVVideoCleanApertureHeightKey,
                                                [NSNumber numberWithInt:0], AVVideoCleanApertureHorizontalOffsetKey,
                                                [NSNumber numberWithInt:0], AVVideoCleanApertureVerticalOffsetKey,
                                                nil];

    NSDictionary *videoAspectRatioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInt:3], AVVideoPixelAspectRatioHorizontalSpacingKey,
                                              [NSNumber numberWithInt:3], AVVideoPixelAspectRatioVerticalSpacingKey,
                                              nil];

    NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] init];
    [compressionProperties setObject:videoCleanApertureSettings forKey:AVVideoCleanApertureKey];
    [compressionProperties setObject:videoAspectRatioSettings forKey:AVVideoPixelAspectRatioKey];
    [compressionProperties setObject:[NSNumber numberWithInt: 1000000] forKey:AVVideoAverageBitRateKey];
    [compressionProperties setObject:[NSNumber numberWithInt: 16] forKey:AVVideoMaxKeyFrameIntervalKey];
    [compressionProperties setObject:AVVideoProfileLevelH264BaselineAutoLevel forKey:AVVideoProfileLevelKey];

    [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];

    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(videoSize, videoSize) fileType:AVFileTypeMPEG4 outputSettings:settings];
    [self.filter addTarget:self.movieWriter];

    self.videoCamera.audioEncodingTarget = self.movieWriter;

    [self.videoCamera addTarget:self.filter];
    [self.videoCamera startCameraCapture];
}

//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//
//    UITouch *touch = [touches anyObject];
//    CGPoint touchPoint = [touch locationInView:self.view];
//
//    if([videoCamera.inputCamera isFocusPointOfInterestSupported]&&[videoCamera.inputCamera isFocusModeSupported:AVCaptureFocusModeAutoFocus])
//    {
//
//        if([videoCamera.inputCamera lockForConfiguration :nil])
//        {
//            [videoCamera.inputCamera setFocusPointOfInterest :touchPoint];
//            [videoCamera.inputCamera setFocusMode :AVCaptureFocusModeLocked];
//
//            if([videoCamera.inputCamera isExposurePointOfInterestSupported])
//            {
//                [videoCamera.inputCamera setExposurePointOfInterest:touchPoint];
//                [videoCamera.inputCamera setExposureMode:AVCaptureExposureModeLocked];
//            }
//            [videoCamera.inputCamera unlockForConfiguration];
//        }
//    }
//    
//}

- (void)stopRecording {
    [self.button setTitle:@"Start" forState:UIControlStateNormal];
    [self.button setBackgroundColor:[UIColor greenColor]];
    self.button.enabled = NO; // Avoids any future clicking before moving into edit mode

    self.videoCamera.audioEncodingTarget = nil;
    [self.filter removeTarget:self.movieWriter];
    [self.movieWriter finishRecording];
    [self.videoCamera stopCameraCapture];

    [self performSegueWithIdentifier:@"editVideoView" sender:nil];
    self.movieWriter = nil;

    //            [videoCamera.inputCamera lockForConfiguration:nil];
    //            [videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
    //            [videoCamera.inputCamera unlockForConfiguration];
}

- (void)startRecording {
    [self.movieWriter startRecording];
    [self.button setTitle:@"Stop" forState:UIControlStateNormal];
    [self.button setBackgroundColor:[UIColor redColor]];

//    double delayInSeconds = 30.0;
//    dispatch_time_t stopTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//    dispatch_after(stopTime, dispatch_get_main_queue(), ^(void){
//        [self stopRecording];
//    });
}

- (IBAction)recordButtonPressed:(UIButton *)button {
    if (self.isRecording) {
        self.isRecording = NO;
        [self stopRecording];
    } else {
        self.isRecording = YES;
        [self startRecording];
    }
}

- (IBAction)closeButtonPressed:(UIButton *)button {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"editVideoView"]) {
        TDEditVideoViewController *vc = [segue destinationViewController];
        NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/WorkingMovie.m4v"];
        [vc editVideoAt:pathToMovie];
    }
}

@end
