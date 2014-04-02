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
#import "TDFileSystemHelper.h"

static NSString *const kRecordedMovieFilePath = @"Documents/RecordedMovie.m4v";
static NSString *const kCroppedMovieFilePath = @"Documents/CroppedMovie.m4v";
static int const kMaxRecordingSeconds = 30;

@interface TDRecordVideoViewController ()

@property GPUImageCropFilter<GPUImageInput> *filter;
@property GPUImageMovieWriter *movieWriter;
@property GPUImageVideoCamera *videoCamera;
@property BOOL isRecording;
@property BOOL torchIsOn;
@property int secondsRecorded;
@property NSTimer *timeLabelTimer;
@property (nonatomic) UITapGestureRecognizer *tapToFocusGesture;
@property (nonatomic) NSURL *recordedURL;
@property (nonatomic) NSURL *croppedURL;
@property (nonatomic) AVAssetExportSession *exportSession;

@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet GPUImageView *previewLayer;
@property (weak, nonatomic) IBOutlet UIView *videoContainerView;
@property (weak, nonatomic) IBOutlet UIView *coverView;
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
    if (self.isRecording) {
        [self stopRecording];
    } else {
        [self.videoCamera pauseCameraCapture];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    self.recordButton.enabled = NO;

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
        self.recordButton.enabled = YES;
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

    self.tapToFocusGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapToFocus:)];
    [self.previewLayer addGestureRecognizer:self.tapToFocusGesture];

    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:kRecordedMovieFilePath];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    self.recordedURL = [NSURL fileURLWithPath:pathToMovie];

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

    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.recordedURL size:CGSizeMake(videoSize, videoSize) fileType:AVFileTypeMPEG4 outputSettings:settings];
    self.movieWriter.encodingLiveVideo = YES;

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

    self.coverView.alpha = 1.0;
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.coverView.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.coverView.hidden = YES;
    }];
}

- (void)stopCamera {
    if (self.videoCamera) {
        self.recordButton.enabled = NO;
        [self.previewLayer removeGestureRecognizer:self.tapToFocusGesture];
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

- (void)hidePreviewCover {
    self.coverView.alpha = 0.0;
    self.coverView.hidden = NO;
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.coverView.alpha = 1.0;
    } completion:nil];
}

- (void)tapToFocus:(UITapGestureRecognizer *)sender {
    AVCaptureDevice *camera = self.videoCamera.inputCamera;
    CGPoint touchPoint = [sender locationInView:self.previewLayer];
    CGPoint focusTo = CGPointMake(touchPoint.x / 320.0, touchPoint.y / 320.0);

    debug NSLog(@"focus at %f x %f", focusTo.x, focusTo.y);

    if ([camera isFocusPointOfInterestSupported] &&
        [camera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {

        if ([camera lockForConfiguration:nil]) {
            [camera setFocusPointOfInterest:focusTo];
            [camera setFocusMode:AVCaptureFocusModeAutoFocus];
            [camera unlockForConfiguration];
        }
    }
}

- (void)stopRecording {
    [self hidePreviewCover];
    self.isRecording = NO;
    [self.recordButton setImage:[UIImage imageNamed:@"v_recstartbutton"] forState:UIControlStateNormal];
    [self.recordButton setImage:[UIImage imageNamed:@"v_recstartbutton_hit"] forState:UIControlStateHighlighted];

    [self.timeLabelTimer invalidate];

    CALayer *currentLayer = self.progressBarView.layer.presentationLayer;
    [self.progressBarView.layer removeAllAnimations];
    self.progressBarView.layer.frame = currentLayer.frame;

    [self.movieWriter finishRecordingWithCompletionHandler:^{
        [self stopCamera];
        [self.movieWriter endProcessing];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Crop out black frames at start of recording
            NSString *assetPath = [NSHomeDirectory() stringByAppendingPathComponent:kCroppedMovieFilePath];
            unlink([assetPath UTF8String]); // remove file
            self.croppedURL = [NSURL fileURLWithPath:assetPath];

            AVAsset *asset = [[AVURLAsset alloc] initWithURL:self.recordedURL options:nil];
            self.exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetPassthrough];
            self.exportSession.outputURL = self.croppedURL;
            self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;

            CMTime start = CMTimeMakeWithSeconds(0.01, asset.duration.timescale);
//            CGFloat length = (asset.duration.value / asset.duration.timescale) - 0.01;
            CMTime duration = CMTimeMakeWithSeconds(0.99, asset.duration.timescale);
            CMTimeRange range = CMTimeRangeMake(start, duration);
            self.exportSession.timeRange = range;

            [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
                // This is to allow camera to stop properly before running animations
                // Especially lets the microphone usage warning go away in time.
                switch ([self.exportSession status]) {
                    case AVAssetExportSessionStatusFailed:
                    case AVAssetExportSessionStatusCancelled:
                    case AVAssetExportSessionStatusExporting:
                    case AVAssetExportSessionStatusUnknown:
                        debug NSLog(@"Export failed: %@", [[self.exportSession error] localizedDescription]);
                        break;
                    case AVAssetExportSessionStatusCompleted:
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                            [self performSegueWithIdentifier:@"EditVideoSegue" sender:nil];
                        });
                        break;
                }
            }];
        });
    }];
}

- (void)startRecording {
    self.isRecording = YES;
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

# pragma mark - segues

- (IBAction)cancelButtonPressed:(id)sender {
    [self hidePreviewCover];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        [self performSegueWithIdentifier:@"VideoCloseSegue" sender:nil];
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue isKindOfClass:[TDSlideLeftSegue class]]) {
        TDEditVideoViewController *vc = [segue destinationViewController];
        [vc editVideoAt:[self.croppedURL path]];
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
