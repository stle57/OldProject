//
//  TDRecordVideoViewController.m
//  Throwdown
//
//  Created by Andrew C on 1/16/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDRecordVideoViewController.h"
#import "TDEditVideoViewController.h"
#import "TDEditVideoSegue.h"
#import "GPUImage.h"
#import "VideoCloseSegue.h"

#define MOVIE_FILE_PATH @"Documents/WorkingMovie.m4v"

@interface TDRecordVideoViewController ()
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet GPUImageView *previewLayer;

@property GPUImageCropFilter<GPUImageInput> *filter;
@property GPUImageMovieWriter *movieWriter;
@property GPUImageVideoCamera *videoCamera;
@property BOOL isRecording;
@property BOOL torchIsOn;

@property (weak, nonatomic) IBOutlet UIView *videoContainerView;
@property (weak, nonatomic) IBOutlet UIButton *switchCamerabutton;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (weak, nonatomic) IBOutlet UIView *progressBarView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
- (IBAction)recordButtonPressed:(UIButton *)sender;
- (IBAction)closeButtonPressed:(UIButton *)sender;

@end

@implementation TDRecordVideoViewController

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];

    // Fix buttons for 3.5" screens
    if ([UIScreen mainScreen].bounds.size.height == 480.0) {
        self.recordButton.center = CGPointMake(self.recordButton.center.x, [UIScreen mainScreen].bounds.size.height-(568.0-538.0));
        self.closeButton.center = CGPointMake(self.closeButton.center.x, [UIScreen mainScreen].bounds.size.height-(568.0-538.0));
    }

    debug NSLog(@"record view did load");
    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:UIStatusBarAnimationFade];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    debug NSLog(@"record view will appear");

    // This is to allow transitions to finish before starting the camera which slows the animation down
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self startCamera];
    });
}

- (void)startCamera {
    debug NSLog(@"record view start camera");
    self.isRecording = NO;
    self.previewLayer.hidden = NO;
    self.torchIsOn = NO;
    self.videoCamera = [[GPUImageVideoCamera alloc]
                        initWithSessionPreset:AVCaptureSessionPreset640x480
                               cameraPosition:AVCaptureDevicePositionBack];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;

    if (![self.videoCamera isBackFacingCameraPresent]) {
        [self updateSwitchCameraButton:NO];
        [self updateFlashButton:NO];
    } else if (![self.videoCamera isFrontFacingCameraPresent]) {
        [self updateSwitchCameraButton:NO];
    }

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

- (void)viewWillDisappear:(BOOL)animated {
    [self stopCamera];
}

- (void)stopCamera {
    if (self.videoCamera) {
        [self.videoCamera stopCameraCapture];
        [self.filter removeTarget:self.movieWriter];
        self.previewLayer.hidden = YES;
        self.videoCamera.audioEncodingTarget = nil;
        self.movieWriter = nil;
        self.filter = nil;
        self.videoCamera = nil;
    }
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

//    double delayInSeconds = 30.0;
//    dispatch_time_t stopTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//    dispatch_after(stopTime, dispatch_get_main_queue(), ^(void){
//        [self stopRecording];
//    });


- (void)stopRecording {
    [self.recordButton setImage:[UIImage imageNamed:@"v_recstartbutton"] forState:UIControlStateNormal];
    [self.recordButton setImage:[UIImage imageNamed:@"v_recstartbutton_hit"] forState:UIControlStateHighlighted];

    [self.movieWriter finishRecordingWithCompletionHandler:^{
        [self stopCamera];
        // This is to allow camera to stop properly before running animations
        // Especially lets the microphone usage warning go away in time.
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self performSegueWithIdentifier:@"EditVideoSegue" sender:nil];
        });
    }];
}

- (void)startRecording {
    [self.recordButton setImage:[UIImage imageNamed:@"v_stoprecbutton"] forState:UIControlStateNormal];
    [self.recordButton setImage:[UIImage imageNamed:@"v_stoprecbutton_hit"] forState:UIControlStateHighlighted];

    [self updateFlashButton:NO];
    [self updateSwitchCameraButton:NO];

    [self.movieWriter startRecording];
}

- (IBAction)recordButtonPressed:(UIButton *)button {
    if (self.isRecording) {
        [self stopRecording];
    } else {
        [self startRecording];
    }
    self.isRecording = !self.isRecording;
}

- (IBAction)switchCameraButtonPressed:(id)sender {
    [self.videoCamera rotateCamera];
    [self updateFlashButton:[self.videoCamera.inputCamera position] == AVCaptureDevicePositionBack];
}

- (void)updateSwitchCameraButton:(BOOL)enable {
    self.switchCamerabutton.enabled = enable;
    self.switchCamerabutton.hidden = !enable;
}

- (void)updateFlashButton:(BOOL)enable {
    self.flashButton.enabled = enable;
    self.flashButton.hidden = !enable;
}

- (IBAction)flashButtonPressed:(id)sender {
    [self.videoCamera.inputCamera lockForConfiguration:nil];
    [self.videoCamera.inputCamera setTorchMode:(self.torchIsOn ? AVCaptureTorchModeOff : AVCaptureTorchModeOn)];
    [self.videoCamera.inputCamera unlockForConfiguration];
    self.torchIsOn = !self.torchIsOn;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue isKindOfClass:[TDEditVideoSegue class]]) {
        debug NSLog(@"record prepare for segue");
        TDEditVideoViewController *vc = [segue destinationViewController];
        NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:MOVIE_FILE_PATH];
        [vc editVideoAt:pathToMovie];
    }
}

@end
