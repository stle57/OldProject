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
#import <QuartzCore/CAAnimation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "TDFileSystemHelper.h"
#import "TDConstants.h"

@interface TDRecordVideoViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property GPUImageCropFilter<GPUImageInput> *filter;
@property GPUImageMovieWriter *movieWriter;
@property GPUImageVideoCamera *videoCamera;
@property GPUImageStillCamera *stillCamera;

@property BOOL isRecording;
@property BOOL torchIsOn;
@property BOOL photoMode;
@property BOOL albumPickerOpen;
@property int secondsRecorded;
@property NSTimer *timeLabelTimer;
@property (nonatomic) UITapGestureRecognizer *tapToFocusGesture;
@property (nonatomic) NSURL *recordedURL;
@property (nonatomic) NSURL *croppedURL;
@property (nonatomic) NSURL *assetURL;
@property (nonatomic) AVAssetExportSession *exportSession;
@property (nonatomic) NSDictionary *currentCaptureMetadata;
@property (nonatomic) UIImage *assetImage;

@property (weak, nonatomic) IBOutlet UIButton *albumButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *photoButton;
@property (weak, nonatomic) IBOutlet UIButton *videoButton;
@property (weak, nonatomic) IBOutlet GPUImageView *previewLayer;
@property (weak, nonatomic) IBOutlet UIView *videoContainerView;
@property (weak, nonatomic) IBOutlet UIView *coverView;
@property (weak, nonatomic) IBOutlet UIButton *switchCamerabutton;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (weak, nonatomic) IBOutlet UIView *progressBarView;
@property (weak, nonatomic) IBOutlet UIView *controlsView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *modeIndicator;
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
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.photoMode) {
        [self.stillCamera resumeCameraCapture];
    } else {
        [self.videoCamera resumeCameraCapture];
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    if (self.photoMode) {
        [self.stillCamera pauseCameraCapture];
    } else {
        if (self.isRecording) {
            [self stopRecording];
        } else {
            [self.videoCamera pauseCameraCapture];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];

    self.recordButton.enabled = NO;
    self.photoMode = YES;
    self.albumPickerOpen = NO;

    // Fix buttons for 3.5" screens
    if ([UIScreen mainScreen].bounds.size.height == 480.0) {
        self.controlsView.center = CGPointMake(self.controlsView.center.x, 430);
        self.videoContainerView.center = CGPointMake(self.videoContainerView.center.x, 212);
        self.coverView.center = CGPointMake(self.coverView.center.x, 212);
    }
    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:UIStatusBarAnimationFade];
}

- (void)viewWillDisappear:(BOOL)animated {
    if (self.photoMode) {
        [self stopPhotoCamera];
    } else {
        [self stopVideoCamera];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.albumPickerOpen) {
        self.albumPickerOpen = NO;
        return;
    }

    self.croppedURL = nil;
    self.assetImage = nil;

    self.closeButton.enabled = YES;
    self.closeButton.hidden = NO;

    self.timeLabel.hidden = YES;
    self.timeLabel.text = @"00:00";
    CGRect progressBarFrame = self.progressBarView.frame;
    progressBarFrame.origin.x = -320;
    self.progressBarView.frame = progressBarFrame;

    // This is to allow transitions to finish before starting the camera which slows the animation down
    double delayInSeconds = 0.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.photoMode) {
            [self startPhotoCamera];
        } else {
            [self startVideoCamera];
        }
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

- (void)showPreviewCover {
    self.recordButton.enabled = NO;
    self.switchCamerabutton.enabled = NO;
    self.flashButton.enabled = NO;

    [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveLinear animations:^{
        self.coverView.alpha = 1.0;
    } completion:nil];
}

- (void)hidePreviewCover {
    // skip animation if we opened the album picker really quickly
    if (!self.albumPickerOpen) {
        [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveLinear animations:^{
            self.coverView.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (finished) {
                [self enableControls];
            }
        }];
    }
}

- (void)enableControls {
    self.recordButton.enabled = YES;
    self.switchCamerabutton.enabled = YES;
    self.flashButton.enabled = YES;
}

- (void)tapToFocus:(UITapGestureRecognizer *)sender {
    AVCaptureDevice *camera;
    if (self.photoMode) {
        camera = self.stillCamera.inputCamera;
    } else  {
        camera = self.videoCamera.inputCamera;
    }
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

#pragma mark - Photo Capture

- (void)startPhotoCamera {
    self.torchIsOn = NO;
    [self updateFlashImage:NO];
    self.filter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, 0.125f, 1.f, .75f)];
    [self setupCameraCommons];
    self.stillCamera = [[GPUImageStillCamera alloc] init];
    self.stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.stillCamera.horizontallyMirrorFrontFacingCamera = YES;
    [self.stillCamera addTarget:self.filter];
    [self.stillCamera startCameraCapture];
    [self setCameraValues:self.stillCamera.inputCamera];
    [self updateFlashButton:[self.stillCamera.inputCamera hasFlash]];
    [self hidePreviewCover];
}

- (void)stopPhotoCamera {
    [self.stillCamera stopCameraCapture];
    [self.stillCamera removeAllTargets];
    [self.filter removeAllTargets];
    self.filter = nil;
    self.stillCamera = nil;
}

- (void)takePhoto {
    self.recordButton.enabled = NO;
    [self.stillCamera capturePhotoAsJPEGProcessedUpToFilter:self.filter withCompletionHandler:^(NSData *processedJPEG, NSError *error){
        [self showPreviewCover];
        [self stopVideoCamera];
        NSString *filename = [NSHomeDirectory() stringByAppendingPathComponent:kPhotoFilePath];
        [processedJPEG writeToFile:filename atomically:YES];
        self.currentCaptureMetadata = self.stillCamera.currentCaptureMetadata;
        [self performSegueWithIdentifier:@"EditVideoSegue" sender:nil];
    }];
}

#pragma mark - Shared Video and Photo

- (void)setupCameraCommons {
    [self.filter addTarget:self.previewLayer];
    self.tapToFocusGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapToFocus:)];
    [self.previewLayer addGestureRecognizer:self.tapToFocusGesture];
}

- (void)setCameraValues:(AVCaptureDevice *)camera {
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

#pragma mark - Video Recording

- (void)startVideoCamera {
    self.isRecording = NO;
    self.torchIsOn = NO;
    [self updateFlashImage:NO];
    self.videoCamera = [[GPUImageVideoCamera alloc]
                        initWithSessionPreset:AVCaptureSessionPreset1280x720
                               cameraPosition:AVCaptureDevicePositionBack];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;

    if ([self.videoCamera isBackFacingCameraPresent] && [self.videoCamera isFrontFacingCameraPresent]) {
        [self updateSwitchCameraButton:YES];
    } else {
        [self updateSwitchCameraButton:NO];
    }
    [self updateFlashButton:[self.videoCamera.inputCamera hasTorch]];


    CGFloat size = .565;
    self.filter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0., (1 - size)/2, 1., size)];
    [self setupCameraCommons];

    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:kRecordedMovieFilePath];
    [TDFileSystemHelper removeFileAt:pathToMovie];
    self.recordedURL = [NSURL fileURLWithPath:pathToMovie];
    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.recordedURL size:CGSizeMake(640, 640) fileType:AVFileTypeMPEG4 outputSettings:[TDConstants defaultVideoCompressionSettings]];
    self.movieWriter.encodingLiveVideo = YES;

    [self.filter addTarget:self.movieWriter];
    self.videoCamera.audioEncodingTarget = self.movieWriter;
    [self.videoCamera addTarget:self.filter];
    [self.videoCamera startCameraCapture];
    [self setCameraValues:self.videoCamera.inputCamera];

    [self hidePreviewCover];
}

- (void)stopVideoCamera {
    if (self.videoCamera) {
        [self.previewLayer removeGestureRecognizer:self.tapToFocusGesture];
        [self removeObservers];
        [self.videoCamera stopCameraCapture];
        [self.filter removeAllTargets];
        self.videoCamera.audioEncodingTarget = nil;
        [self.videoCamera removeAllTargets];
        self.movieWriter = nil;
        self.filter = nil;
        self.videoCamera = nil;
    }
}

- (void)stopRecording {
    [self showPreviewCover];
    self.isRecording = NO;
    [self.recordButton setImage:[UIImage imageNamed:@"btn_video_on_inner_132x132"] forState:UIControlStateNormal];
    [self.recordButton setImage:[UIImage imageNamed:@"btn_video_on_inner_132x132_hit"] forState:UIControlStateHighlighted];

    [self.timeLabelTimer invalidate];

    CALayer *currentLayer = self.progressBarView.layer.presentationLayer;
    [self.progressBarView.layer removeAllAnimations];
    self.progressBarView.layer.frame = currentLayer.frame;

    [self.movieWriter finishRecordingWithCompletionHandler:^{
        [self stopVideoCamera];
        [self.movieWriter endProcessing];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Crop out black frames at start of recording
            NSString *assetPath = [NSHomeDirectory() stringByAppendingPathComponent:kRecordedTrimmedMovieFilePath];
            [TDFileSystemHelper removeFileAt:assetPath];
            self.croppedURL = [NSURL fileURLWithPath:assetPath];

            AVAsset *asset = [[AVURLAsset alloc] initWithURL:self.recordedURL options:nil];
            self.exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetPassthrough];
            self.exportSession.outputURL = self.croppedURL;
            self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;

            CGFloat durationSeconds = CMTimeGetSeconds([asset duration]);
            CMTime start = CMTimeMakeWithSeconds(0.05, asset.duration.timescale);
            CMTime duration = CMTimeMakeWithSeconds(durationSeconds - 0.05, asset.duration.timescale);
            CMTimeRange range = CMTimeRangeMake(start, duration);
            self.exportSession.timeRange = range;

            [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
                switch ([self.exportSession status]) {
                    case AVAssetExportSessionStatusFailed:
                    case AVAssetExportSessionStatusCancelled:
                    case AVAssetExportSessionStatusExporting:
                    case AVAssetExportSessionStatusUnknown:
                        debug NSLog(@"Export failed: %@", [[self.exportSession error] localizedDescription]);
                        // TODO: show error message here?
                        break;
                    case AVAssetExportSessionStatusCompleted:
                        // This is to allow camera to stop properly before running animations
                        // Especially lets the microphone usage warning go away in time.
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
    [self.recordButton setImage:[UIImage imageNamed:@"btn_video_on_inner_recording_132x132"] forState:UIControlStateNormal];
    [self.recordButton setImage:[UIImage imageNamed:@"btn_video_on_inner_recording_132x132_hit"] forState:UIControlStateHighlighted];

    [self updateFlashButton:NO];
    [self updateSwitchCameraButton:NO];

    [self.movieWriter startRecording];

    self.timeLabel.hidden = NO;
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

#pragma mark - Library picker

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:^{
        if ([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:@"public.image"]) {
            self.assetImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        } else if ([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:@"public.movie"]) {
            self.assetURL = [info objectForKey:UIImagePickerControllerMediaURL];
        }
        [self performSegueWithIdentifier:@"EditVideoSegue" sender:nil];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self enableControls];
    if (self.photoMode) {
        [self startPhotoCamera];
    } else {
        [self startVideoCamera];
    }
}

#pragma mark - UI callbacks

- (IBAction)recordButtonPressed:(UIButton *)button {
    if (self.photoMode) {
        [self takePhoto];
    } else {
        if (self.isRecording) {
            [self stopRecording];
        } else {
            [self startRecording];
            self.closeButton.enabled = NO;
            self.closeButton.hidden = YES;
        }
    }
}

- (IBAction)albumButtonPressed:(id)sender {
    [self showPreviewCover];
    if (self.photoMode) {
        [self stopPhotoCamera];
    } else {
        [self stopVideoCamera];
    }
    self.albumPickerOpen = YES;

    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
    imagePickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
    imagePickerController.delegate = self;

    [self presentViewController:imagePickerController
                       animated:YES
                     completion:nil];
}

- (IBAction)switchCameraButtonPressed:(id)sender {
    self.switchCamerabutton.enabled = NO;
    BOOL hasFlash = NO;
    if (self.photoMode) {
        [self.stillCamera rotateCamera];
        hasFlash = [self.stillCamera.inputCamera hasFlash];
    } else {
        [self.videoCamera rotateCamera];
        hasFlash = [self.videoCamera.inputCamera hasTorch];
    }
    [self updateFlashButton:hasFlash];
    self.switchCamerabutton.enabled = YES;
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
    self.flashButton.enabled = NO;
    if (self.photoMode) {
        [self.stillCamera.inputCamera lockForConfiguration:nil];
        [self.stillCamera.inputCamera setFlashMode:(self.torchIsOn ? AVCaptureFlashModeOff : AVCaptureFlashModeOn)];
        [self.stillCamera.inputCamera unlockForConfiguration];
    } else {
        [self.videoCamera.inputCamera lockForConfiguration:nil];
        [self.videoCamera.inputCamera setTorchMode:(self.torchIsOn ? AVCaptureTorchModeOff : AVCaptureTorchModeOn)];
        [self.videoCamera.inputCamera unlockForConfiguration];
    }
    self.torchIsOn = !self.torchIsOn;
    [self updateFlashImage:self.torchIsOn];
    self.flashButton.enabled = YES;
}

- (void)updateFlashImage:(BOOL)mode {
    [self.flashButton setImage:[UIImage imageNamed:(mode ? @"v_flash_on_66x40" : @"v_flash_off_66x40")] forState:UIControlStateNormal];
    [self.flashButton setImage:[UIImage imageNamed:(mode ? @"v_flash_on_66x40_hit" : @"v_flash_off_66x40_hit")] forState:UIControlStateHighlighted];
    [self.flashButton setImage:[UIImage imageNamed:(mode ? @"v_flash_on_66x40_hit" : @"v_flash_off_66x40_hit")] forState:UIControlStateDisabled];
}

- (IBAction)photoButtonPressed:(id)sender {
    [self switchInputModeToPhoto:YES];
}

- (IBAction)videoButtonPressed:(id)sender {
    [self switchInputModeToPhoto:NO];
}

#pragma mark - Switch input mode

- (void)switchInputModeToPhoto:(BOOL)photo {
    if ((photo && self.photoMode) || (!photo && !self.photoMode)) {
        return;
    }

    self.videoButton.enabled = NO;
    self.photoButton.enabled = NO;

    NSNumber *direction;
    if (photo) {
        direction = [NSNumber numberWithFloat:M_PI];
    } else {
        direction = [NSNumber numberWithFloat:(0 - M_PI)];
    }
    CABasicAnimation* rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = direction;
    rotationAnimation.duration = 0.3;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = 0;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    rotationAnimation.removedOnCompletion = NO;
    rotationAnimation.delegate = self;
    rotationAnimation.fillMode = kCAFillModeForwards;
    [self.modeIndicator.layer addAnimation:rotationAnimation forKey:kSpinningAnimation];

    [self showPreviewCover];

    if (photo) {
        [self stopVideoCamera];
        [self startPhotoCamera];
    } else {
        [self stopPhotoCamera];
        [self startVideoCamera];
    }
    self.photoMode = !self.photoMode;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (self.photoMode) {
        [self.recordButton setImage:[UIImage imageNamed:@"btn_camera_on_inner_132x132"] forState:UIControlStateNormal];
        [self.recordButton setImage:[UIImage imageNamed:@"btn_camera_on_inner_132x132_hit"] forState:UIControlStateHighlighted];
        self.modeIndicator.image = [UIImage imageNamed:@"btn_camera_outerCircle_rightArrow_184x160"];
    } else {
        [self.recordButton setImage:[UIImage imageNamed:@"btn_video_on_inner_132x132"] forState:UIControlStateNormal];
        [self.recordButton setImage:[UIImage imageNamed:@"btn_video_on_inner_132x132_hit"] forState:UIControlStateHighlighted];
        self.modeIndicator.image = [UIImage imageNamed:@"btn_camera_outerCircle_leftArrow_184x160"];
    }
    [self.modeIndicator.layer removeAnimationForKey:kSpinningAnimation];
    self.videoButton.enabled = YES;
    self.photoButton.enabled = YES;
}


# pragma mark - segues

- (IBAction)cancelButtonPressed:(id)sender {
    [self showPreviewCover];
    // This is to allow camera to stop properly before running animations
    // Especially lets the microphone usage warning go away in time.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        [self performSegueWithIdentifier:@"VideoCloseSegue" sender:nil];
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue isKindOfClass:[TDSlideLeftSegue class]]) {
        TDEditVideoViewController *vc = [segue destinationViewController];
        if (self.assetURL) {
            [vc editVideoAt:[self.assetURL path] original:NO];
            self.assetURL = nil;
        } else if (self.croppedURL) {
            [vc editVideoAt:[self.croppedURL path] original:YES];
            self.croppedURL = nil;
        } else if (self.assetImage) {
            [vc editImage:self.assetImage];
            self.assetImage = nil;
        } else {
            NSString *filename = [NSHomeDirectory() stringByAppendingPathComponent:kPhotoFilePath];
            [vc editPhotoAt:filename metadata:self.currentCaptureMetadata];
            self.currentCaptureMetadata = nil;
        }
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
