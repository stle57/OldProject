//
//  TDRecordVideoViewController.m
//  Throwdown
//
//  Created by Andrew C on 1/16/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDRecordVideoViewController.h"
#import "TDEditVideoViewController.h"
#import "TDSlideLeftSegue.h"
#import "TDUnwindSlideLeftSegue.h"
#import "GPUImage.h"
#import "VideoCloseSegue.h"
#import <QuartzCore/QuartzCore.h>

static NSString *const kMovieFilePath = @"Documents/WorkingMovie.m4v";
static int const kMaxRecordingSeconds = 30;

@interface TDRecordVideoViewController ()

@property GPUImageCropFilter<GPUImageInput> *filter;
@property GPUImageMovieWriter *movieWriter;
@property GPUImageVideoCamera *videoCamera;
@property BOOL isRecording;
@property BOOL torchIsOn;
@property int secondsRecorded;
@property NSTimer *timeLabelTimer;

@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet GPUImageView *previewLayer;
@property (weak, nonatomic) IBOutlet UIView *videoContainerView;
@property (weak, nonatomic) IBOutlet UIButton *switchCamerabutton;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (weak, nonatomic) IBOutlet UIView *progressBarView;
@property (weak, nonatomic) IBOutlet UIView *controlsView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
- (IBAction)recordButtonPressed:(UIButton *)sender;

@end

@implementation TDRecordVideoViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)dealloc {
    [self removeObservers];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:UIApplicationDidEnterBackgroundNotification
                                                 object:nil];

    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:UIApplicationDidBecomeActiveNotification
                                                 object:nil];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self.videoCamera resumeCameraCapture];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self.videoCamera pauseCameraCapture];
    // TODO: stop recording if active
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];

    // Fix buttons for 3.5" screens
    if ([UIScreen mainScreen].bounds.size.height == 480.0) {
        self.controlsView.center = CGPointMake(self.controlsView.center.x, 430);
        self.videoContainerView.center = CGPointMake(self.videoContainerView.center.x, 212);
    }
    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:UIStatusBarAnimationFade];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self stopCamera];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.timeLabel.text = @"00:00";
    CGRect progressBarFrame = self.progressBarView.frame;
    progressBarFrame.origin.x = -320;
    self.progressBarView.frame = progressBarFrame;

    // This is to allow transitions to finish before starting the camera which slows the animation down
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self startCamera];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(applicationDidEnterBackground:)
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];

        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(applicationDidBecomeActive:)
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    });
}

- (void)startCamera {
    self.isRecording = NO;
    self.torchIsOn = NO;
    self.videoCamera = [[GPUImageVideoCamera alloc]
                        initWithSessionPreset:AVCaptureSessionPreset640x480
                               cameraPosition:AVCaptureDevicePositionBack];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;

    if ([self.videoCamera isBackFacingCameraPresent] && [self.videoCamera isFrontFacingCameraPresent]) {
        [self updateSwitchCameraButton:YES];
    } else {
        [self updateSwitchCameraButton:NO];
    }
    [self updateFlashButton:[self.videoCamera.inputCamera hasTorch]];

    self.filter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, 0.125f, 1.f, .75f)];
    [self.filter addTarget:self.previewLayer];

    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:kMovieFilePath];
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

    AVCaptureDevice *camera = self.videoCamera.inputCamera;
    if ([camera lockForConfiguration:nil]) {
        if ([camera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            [camera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        } else if ([camera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [camera setFocusMode:AVCaptureFocusModeAutoFocus];
        }

        if ([camera isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
            [camera setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        }
        [camera unlockForConfiguration];
    }
}

- (void)stopCamera {
    if (self.videoCamera) {
        [self removeObservers];
        [self.videoCamera stopCameraCapture];
        [self.filter removeTarget:self.movieWriter];
        self.videoCamera.audioEncodingTarget = nil;
        [self.videoCamera removeAllTargets];
        self.movieWriter = nil;
        self.filter = nil;
        self.videoCamera = nil;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    AVCaptureDevice *camera = self.videoCamera.inputCamera;
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    CGPoint focusTo = CGPointMake(touchPoint.x / 320.0, touchPoint.y / 320.0);
    debug NSLog(@"focus at %f x %f", focusTo.x, focusTo.y);

    if (touch.view == self.previewLayer &&
        [camera isFocusPointOfInterestSupported] &&
        [camera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {

        if ([camera lockForConfiguration:nil]) {
            [camera setFocusPointOfInterest:focusTo];
            [camera setFocusMode:AVCaptureFocusModeAutoFocus];
            [camera unlockForConfiguration];
        }
    }
}

- (void)stopRecording {
    [self.recordButton setImage:[UIImage imageNamed:@"v_recstartbutton"] forState:UIControlStateNormal];
    [self.recordButton setImage:[UIImage imageNamed:@"v_recstartbutton_hit"] forState:UIControlStateHighlighted];

    [self.timeLabelTimer invalidate];

    CALayer *currentLayer = self.progressBarView.layer.presentationLayer;
    [self.progressBarView.layer removeAllAnimations];
    self.progressBarView.layer.frame = currentLayer.frame;

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

    self.secondsRecorded = 0;
    self.timeLabelTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                           target:self
                                                         selector:@selector(recordingProgress:)
                                                         userInfo:nil
                                                          repeats:YES];

    CGRect progressBarFrame = self.progressBarView.frame;
    progressBarFrame.origin.x = 0;
    [UIView animateWithDuration:kMaxRecordingSeconds
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.progressBarView.frame = progressBarFrame;
                     }
                     completion:NULL];
}

- (void)recordingProgress:(NSTimer *)timer {
    self.secondsRecorded += 1;
    self.timeLabel.text = [NSString stringWithFormat:@"00:%02d", self.secondsRecorded];
    if (self.secondsRecorded == kMaxRecordingSeconds) {
        [self stopRecording];
    }
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
    [self updateFlashButton:[self.videoCamera.inputCamera hasFlash]];
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
    if ([segue isKindOfClass:[TDSlideLeftSegue class]]) {
        TDEditVideoViewController *vc = [segue destinationViewController];
        NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:kMovieFilePath];
        [vc editVideoAt:pathToMovie];
    }
}

- (IBAction)unwindToRecordVideo:(UIStoryboardSegue *)sender {
    // Empty on purpose
}

- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {
    debug NSLog(@"record video segue for unwinding with identifier %@", identifier);

    if ([@"UnwindSlideLeftSegue" isEqualToString:identifier]) {
        return [[TDUnwindSlideLeftSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    } else {
        return [super segueForUnwindingToViewController:toViewController
                                     fromViewController:fromViewController
                                             identifier:identifier];
    }
}

@end
