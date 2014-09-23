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
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CAAnimation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "TDFileSystemHelper.h"
#import "TDConstants.h"
#import "TDAnalytics.h"
#import "TDCameraPreviewView.h"

static void *SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;
static void *RecordingContext = &RecordingContext;


@interface TDRecordVideoViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCaptureFileOutputRecordingDelegate>

@property BOOL torchIsOn;
@property BOOL photoMode;
@property BOOL albumPickerOpen;
@property int secondsRecorded;
@property NSTimer *timeLabelTimer;
@property (nonatomic) UITapGestureRecognizer *tapToFocusGesture;
@property (nonatomic) NSURL *recordedURL;
@property (nonatomic) NSURL *croppedURL;
@property (nonatomic) NSURL *assetURL;
@property (nonatomic) NSDictionary *currentCaptureMetadata;
@property (nonatomic) UIImage *assetImage;

// Device handling
@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureDevice *videoDevice;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic) BOOL lockInterfaceRotation;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;

@property (weak, nonatomic) IBOutlet TDCameraPreviewView *cameraPreview;
@property (weak, nonatomic) IBOutlet UIButton *albumButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *photoButton;
@property (weak, nonatomic) IBOutlet UIButton *videoButton;
@property (weak, nonatomic) IBOutlet UIView *coverView;
@property (weak, nonatomic) IBOutlet UIButton *switchCamerabutton;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (weak, nonatomic) IBOutlet UIView *progressBarView;
@property (weak, nonatomic) IBOutlet UIView *controlsView;
@property (weak, nonatomic) IBOutlet UIView *indicatorBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *modeIndicator;
- (IBAction)recordButtonPressed:(UIButton *)sender;

@end

@implementation TDRecordVideoViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault; // only used in the camera picker ui
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)shouldAutorotate {
    // Disable autorotation of the interface when recording is in progress.
    return ![self lockInterfaceRotation];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [[(AVCaptureVideoPreviewLayer *)[[self cameraPreview] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)toInterfaceOrientation];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    [[TDAnalytics sharedInstance] logEvent:@"camera_opened"];

    self.recordButton.enabled = NO;
    self.photoMode = YES;
    self.albumPickerOpen = NO;


    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat height = (bounds.size.height - 320) / 2.;
    NSLog(@"%f, %@", height, NSStringFromCGRect(bounds));
    self.indicatorBackgroundView.frame = CGRectMake(0, 0, bounds.size.width, height);
    self.controlsView.frame = CGRectMake(0, bounds.size.height - height, bounds.size.width, height);
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];

    self.tapToFocusGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapToFocus:)];
    [self.cameraPreview addGestureRecognizer:self.tapToFocusGesture];

    // New camera capture stuff
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [self setSession:session];
    [[self cameraPreview] setSession:session];

    [self checkDeviceAuthorizationStatus];
    // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
    // Why not do all of this on the main queue?
    // -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue so that the main queue isn't blocked (which keeps the UI responsive).

    dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    [self setSessionQueue:sessionQueue];

    dispatch_async(sessionQueue, ^{
        [self setBackgroundRecordingID:UIBackgroundTaskInvalid];

        NSError *error = nil;

        AVCaptureDevice *videoDevice = [[self class] deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];

        if (error) {
            NSLog(@"%@", error);
        }

        [[self session] beginConfiguration];

        if ([session canAddInput:videoDeviceInput]) {
            [session addInput:videoDeviceInput];
            [self setVideoDeviceInput:videoDeviceInput];
            [self setVideoDevice:videoDeviceInput.device];
            [[self class] setCameraValuesForDevice:self.videoDevice];

            dispatch_async(dispatch_get_main_queue(), ^{
                // Why are we dispatching this to the main queue?
                // Because AVCaptureVideoPreviewLayer is the backing layer for our preview view and UIView can only be manipulated on main thread.
                // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.

                [[(AVCaptureVideoPreviewLayer *)[[self cameraPreview] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)[self interfaceOrientation]];
            });
        }

        AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
        AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];

        if (error) {
            NSLog(@"%@", error);
        }

        if ([session canAddInput:audioDeviceInput]) {
            [session addInput:audioDeviceInput];
        }

        AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        if ([session canAddOutput:movieFileOutput]) {
            [session addOutput:movieFileOutput];
            AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];

            if ([connection isVideoStabilizationSupported]) {
                if ([connection respondsToSelector:@selector(setPreferredVideoStabilizationMode:)]) {
                    // ios8
                    [connection setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
                } else {
                    // ios6/7
                    [connection setEnablesVideoStabilizationWhenAvailable:YES];
                }
            }
            [self setMovieFileOutput:movieFileOutput];
        }

        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        if ([session canAddOutput:stillImageOutput]) {
            [stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
            [session addOutput:stillImageOutput];
            [self setStillImageOutput:stillImageOutput];
        }

        [[self session] commitConfiguration];
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [self disableControls];
    dispatch_async([self sessionQueue], ^{
        [[self session] stopRunning];
        [self removeObservers];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.coverView.hidden = YES;
    if (self.albumPickerOpen) {
        self.albumPickerOpen = NO;
        [self setNeedsStatusBarAppearanceUpdate];
    } else {
        self.croppedURL = nil;
        self.assetImage = nil;
    }

    self.closeButton.enabled = YES;
    self.closeButton.hidden = NO;

    self.timeLabel.hidden = YES;
    self.timeLabel.text = @"00:00";
    CGRect progressBarFrame = self.progressBarView.frame;
    progressBarFrame.origin.x = -320;
    self.progressBarView.frame = progressBarFrame;

    dispatch_async([self sessionQueue], ^{
        [self addObservers];
        [[self session] startRunning];
    });
}

- (void)configureCameraUI {
    [self enableControls];
    if ([[self class] isBackFacingCameraPresent] && [[self class] isFrontFacingCameraPresent]) {
        [self updateSwitchCameraButton:YES];
    } else {
        [self updateSwitchCameraButton:NO];
    }
    [self updateFlashState];
}

#pragma mark - permissions

- (void)checkDeviceAuthorizationStatus {
    NSString *mediaType = AVMediaTypeVideo;
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if (granted) {
            NSLog(@"Video enabled");
            [self setDeviceAuthorized:YES];
            //            dispatch_async(dispatch_get_main_queue(), ^{
            //                [self startVideoCamera];
            //            });
        } else {
            NSLog(@"Video disabled");
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:nil
                                            message:@"Please enable camera permissions for Throwdown in iOS Settings"
                                           delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
                [self setDeviceAuthorized:NO];
            });
        }
    }];
}

- (BOOL)isSessionRunningAndDeviceAuthorized {
    return [[self session] isRunning] && [self isDeviceAuthorized];
}

#pragma mark - Observers

- (void)addObservers {
    [self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningAndDeviceAuthorizedContext];
    [self addObserver:self forKeyPath:@"movieFileOutput.recording" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:RecordingContext];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusSubjectChanged:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[self videoDevice]];
}

- (void)removeObservers {
    [self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
    [self removeObserver:self forKeyPath:@"movieFileOutput.recording" context:RecordingContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[self videoDevice]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == RecordingContext) {
        BOOL isRecording = [change[NSKeyValueChangeNewKey] boolValue];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (isRecording) {
                self.switchCamerabutton.enabled = NO;
                self.flashButton.enabled = NO;
                self.recordButton.enabled = YES;
            } else {
                [self enableControls];
            }
        });
    } else if (context == SessionRunningAndDeviceAuthorizedContext) {
        BOOL isRunning = [change[NSKeyValueChangeNewKey] boolValue];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (isRunning) {
                [self configureCameraUI];
            } else {
                [self disableControls];
            }
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Recording / Camera capture

- (void)toggleMovieRecording {
    dispatch_async([self sessionQueue], ^{
        if (![[self movieFileOutput] isRecording]) {
            dispatch_async(dispatch_get_main_queue(), ^{

                NSString *extra = [NSString stringWithFormat:@"%@;%@", (self.torchIsOn ? @"1" : @"0"), ([self.videoDevice position] == AVCaptureDevicePositionFront ? @"1" : @"0")];
                [[TDAnalytics sharedInstance] logEvent:@"camera_record_video" withInfo:extra source:nil];

                self.closeButton.enabled = NO;
                self.closeButton.hidden = YES;

                [self.recordButton setImage:[UIImage imageNamed:@"btn_video_on_inner_recording_132x132"] forState:UIControlStateNormal];
                [self.recordButton setImage:[UIImage imageNamed:@"btn_video_on_inner_recording_132x132_hit"] forState:UIControlStateHighlighted];

                [self updateFlashButton:NO];
                [self updateSwitchCameraButton:NO];

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
            });

            [self setLockInterfaceRotation:YES];

            if ([[UIDevice currentDevice] isMultitaskingSupported]) {
                // Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until the app returns to the foreground unless you request background execution time. This also ensures that there will be time to write the file to the assets library when the app is backgrounded. To conclude this background execution, -endBackgroundTask is called in -recorder:recordingDidFinishToOutputFileURL:error: after the recorded file has been saved.
                [self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil]];
            }

            // Update the orientation on the movie file output video connection before starting recording.
            [[[self movieFileOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[[self cameraPreview] layer] connection] videoOrientation]];

            // Turn OFF flash for video recording (note this does NOT affect Torch which is something different)
            [[self class] setFlashMode:AVCaptureFlashModeOff forDevice:self.videoDevice];

            // Start recording to file
            NSString *recordPath = [NSHomeDirectory() stringByAppendingPathComponent:kRecordedMovieFilePath];
            [TDFileSystemHelper removeFileAt:recordPath];
            self.recordedURL = [NSURL fileURLWithPath:recordPath];
            [[self movieFileOutput] startRecordingToOutputFileURL:self.recordedURL recordingDelegate:self];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.coverView.hidden = NO;
                [self.recordButton setImage:[UIImage imageNamed:@"btn_video_on_inner_132x132"] forState:UIControlStateNormal];
                [self.recordButton setImage:[UIImage imageNamed:@"btn_video_on_inner_132x132_hit"] forState:UIControlStateHighlighted];

                [self.timeLabelTimer invalidate];

                CALayer *currentLayer = self.progressBarView.layer.presentationLayer;
                [self.progressBarView.layer removeAllAnimations];
                self.progressBarView.layer.frame = currentLayer.frame;
            });

            [[self movieFileOutput] stopRecording];
        }
    });
}

- (void)snapStillImage {
    self.coverView.hidden = NO;
    [[TDAnalytics sharedInstance] logEvent:@"camera_record_photo"];
    dispatch_async([self sessionQueue], ^{
        // Update the orientation on the still image output video connection before capturing.
        [[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[[self cameraPreview] layer] connection] videoOrientation]];

        // Capture a still image
        [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            if (imageDataSampleBuffer) {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *image = [UIImage imageWithData:imageData];

                UIImage *square = [[self class] squareImageFromImage:image scaledToSize:MIN(image.size.width, image.size.height)];
                imageData = UIImageJPEGRepresentation(square, 0.97);

                NSString *filename = [NSHomeDirectory() stringByAppendingPathComponent:kPhotoFilePath];
                [imageData writeToFile:filename atomically:YES];

                CFDictionaryRef metadata = CMCopyDictionaryOfAttachments(NULL, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate);
                self.currentCaptureMetadata = (NSDictionary *)CFBridgingRelease(metadata);

                [self performSegueWithIdentifier:@"EditVideoSegue" sender:nil];
            }
        }];
    });
}

#pragma mark - Camera switch/flash/focus

- (void)changeCamera {
    [self disableControls];

    dispatch_async([self sessionQueue], ^{
        AVCaptureDevice *currentVideoDevice = [self videoDevice];
        AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
        AVCaptureDevicePosition currentPosition = [currentVideoDevice position];

        switch (currentPosition) {
            case AVCaptureDevicePositionUnspecified:
                preferredPosition = AVCaptureDevicePositionBack;
                break;
            case AVCaptureDevicePositionBack:
                preferredPosition = AVCaptureDevicePositionFront;
                break;
            case AVCaptureDevicePositionFront:
                preferredPosition = AVCaptureDevicePositionBack;
                break;
        }

        AVCaptureDevice *newVideoDevice = [[self class] deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
        AVCaptureDeviceInput *newVideoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newVideoDevice error:nil];

        [[self session] beginConfiguration];
        [[self session] removeInput:[self videoDeviceInput]];

        if ([[self session] canAddInput:newVideoDeviceInput]) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusSubjectChanged:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:newVideoDevice];

            [[self session] addInput:newVideoDeviceInput];
            [self setVideoDeviceInput:newVideoDeviceInput];
            [self setVideoDevice:newVideoDeviceInput.device];
            [[self class] setCameraValuesForDevice:self.videoDevice];
        } else {
            [[self session] addInput:[self videoDeviceInput]];
        }

        [[self session] commitConfiguration];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self enableControls];
            [self updateFlashState];
        });
    });
}

- (void)tapToFocus:(UITapGestureRecognizer *)sender {
    CGPoint touchPoint = [sender locationInView:self.cameraPreview];
    CGPoint focusTo = CGPointMake(touchPoint.x / 320., touchPoint.y / 568.);

    debug NSLog(@"focus at %f x %f", focusTo.x, focusTo.y);

    dispatch_async([self sessionQueue], ^{
        [[self class] cameraFocus:self.videoDevice withFocusMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:focusTo monitorSubjectAreaChange:YES];
    });
}

- (void)focusSubjectChanged:(NSNotification *)notification {
    debug NSLog(@"focus reset");
    dispatch_async([self sessionQueue], ^{
        [[self class] cameraFocus:self.videoDevice withFocusMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:CGPointMake(0.5, 0.5) monitorSubjectAreaChange:NO];
    });
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    if (error) {
        NSLog(@"%@", error);
    }

    [self setLockInterfaceRotation:NO];

    // Note the backgroundRecordingID for use in the ALAssetsLibrary completion handler to end the background task associated with this recording. This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's -isRecording is back to NO — which happens sometime after this method returns.
    UIBackgroundTaskIdentifier backgroundRecordingID = [self backgroundRecordingID];
    [self setBackgroundRecordingID:UIBackgroundTaskInvalid];

    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:kRecordedTrimmedMovieFilePath];
    self.croppedURL = [NSURL fileURLWithPath:pathToMovie];
    [TDFileSystemHelper removeFileAt:pathToMovie];
    [TDFileSystemHelper copyFileFrom:[outputFileURL path] to:pathToMovie];
    [TDFileSystemHelper removeFileAt:[outputFileURL path]];

    if (backgroundRecordingID != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
    }

    [self performSegueWithIdentifier:@"EditVideoSegue" sender:nil];
}

#pragma mark - Library picker

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [[TDAnalytics sharedInstance] logEvent:@"camera_picker_select"];
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
}

#pragma mark - UI callbacks and helpers

- (void)disableControls {
    self.recordButton.enabled = NO;
    self.switchCamerabutton.enabled = NO;
    self.flashButton.enabled = NO;
}

- (void)enableControls {
    self.recordButton.enabled = YES;
    self.switchCamerabutton.enabled = YES;
    self.flashButton.enabled = YES;
}

- (void)recordingProgress:(NSTimer *)timer {
    // TODO: we might be able to look at the progress in the movie-writer object instead of just incrementing
    self.secondsRecorded += 1;
    self.timeLabel.text = [NSString stringWithFormat:@"00:%02d", self.secondsRecorded];
    if (self.secondsRecorded == kMaxRecordingSeconds) {
        [self toggleMovieRecording];
    }
}

- (IBAction)recordButtonPressed:(UIButton *)button {
    if (self.photoMode) {
        [self snapStillImage];
    } else {
        [self toggleMovieRecording];
    }
}

- (IBAction)albumButtonPressed:(id)sender {
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
    [[TDAnalytics sharedInstance] logEvent:@"camera_picker_opened"];
}

- (IBAction)switchCameraButtonPressed:(id)sender {
    [self changeCamera];
    [self updateFlashButton:(self.photoMode ? [self.videoDevice hasFlash] : [self.videoDevice hasTorch])];
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
    self.torchIsOn = !self.torchIsOn;
    [self updateFlashState];
    [self updateFlashImage:self.torchIsOn];
    self.flashButton.enabled = YES;
}

- (void)updateFlashState {
    [self updateFlashButton:(self.photoMode ? [self.videoDevice hasFlash] : [self.videoDevice hasTorch])];
    if (self.flashButton.enabled) {
        if (self.photoMode) {
            // Always turn off torch in case it's active (eg while switching from video to photo)
            [[self class] setTorchMode:AVCaptureTorchModeOff forDevice:self.videoDevice];
            [[self class] setFlashMode:(self.torchIsOn ? AVCaptureFlashModeOn : AVCaptureFlashModeOff) forDevice:self.videoDevice];
        } else {
            [[self class] setTorchMode:(self.torchIsOn ? AVCaptureTorchModeOn : AVCaptureTorchModeOff) forDevice:self.videoDevice];
        }
    }
}

- (void)updateFlashImage:(BOOL)mode {
    [self.flashButton setImage:[UIImage imageNamed:(mode ? @"v_flash_on_66x40" : @"v_flash_off_66x40")] forState:UIControlStateNormal];
    [self.flashButton setImage:[UIImage imageNamed:(mode ? @"v_flash_on_66x40_hit" : @"v_flash_off_66x40_hit")] forState:UIControlStateHighlighted];
    [self.flashButton setImage:[UIImage imageNamed:(mode ? @"v_flash_on_66x40_hit" : @"v_flash_off_66x40_hit")] forState:UIControlStateDisabled];
}

- (IBAction)photoButtonPressed:(id)sender {
    [self switchInputModeToPhoto:YES];
    [[TDAnalytics sharedInstance] logEvent:@"camera_photo"];
}

- (IBAction)videoButtonPressed:(id)sender {
    [self switchInputModeToPhoto:NO];
    [[TDAnalytics sharedInstance] logEvent:@"camera_video"];
}

#pragma mark - Switch input mode

- (void)switchInputModeToPhoto:(BOOL)photo {
    if ((photo && self.photoMode) || (!photo && !self.photoMode)) {
        return;
    }

    [self disableControls];
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

    self.photoMode = !self.photoMode;
    [self updateFlashState];
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
    [self enableControls];
}


# pragma mark - segues

- (IBAction)cancelButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"MediaCloseSegue" sender:nil];
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

#pragma mark - helpers

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = [devices firstObject];

    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}

+ (BOOL)isBackFacingCameraPresent {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];

    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack)
            return YES;
    }

    return NO;
}

+ (BOOL)isFrontFacingCameraPresent {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];

    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront)
            return YES;
    }
    return NO;
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device {
    if ([device hasFlash] && [device isFlashModeSupported:flashMode]) {
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
            [device setFlashMode:flashMode];
            [device unlockForConfiguration];
        } else {
            NSLog(@"Flash error: %@", error);
        }
    }
}

+ (void)setTorchMode:(AVCaptureTorchMode)torchMode forDevice:(AVCaptureDevice *)device {
    if ([device hasTorch] && [device isTorchModeSupported:torchMode]) {
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
            [device setTorchMode:torchMode];
            [device unlockForConfiguration];
        } else {
            NSLog(@"Torch error: %@", error);
        }
    }
}

+ (void)setCameraValuesForDevice:(AVCaptureDevice *)camera {
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

+ (void)cameraFocus:(AVCaptureDevice *)device withFocusMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
        if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode]) {
            [device setFocusMode:focusMode];
            [device setFocusPointOfInterest:point];
        }
        if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode]) {
            [device setExposureMode:exposureMode];
            [device setExposurePointOfInterest:point];
        }
        [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
        [device unlockForConfiguration];
    } else {
        NSLog(@"%@", error);
    }
}

+ (NSSet *)keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized {
    return [NSSet setWithObjects:@"session.running", @"deviceAuthorized", nil];
}

// Found at http://stackoverflow.com/questions/23438442/making-square-crop-of-uiimage-causing-image-to-stretch
+ (UIImage *)squareImageFromImage:(UIImage *)image scaledToSize:(CGFloat)newSize {
    CGAffineTransform scaleTransform;
    CGPoint origin;

    if (image.size.width > image.size.height) {
        CGFloat scaleRatio = newSize / image.size.height;
        scaleTransform = CGAffineTransformMakeScale(scaleRatio, scaleRatio);

        origin = CGPointMake(-(image.size.width - image.size.height) / 2.0f, 0);
    } else {
        CGFloat scaleRatio = newSize / image.size.width;
        scaleTransform = CGAffineTransformMakeScale(scaleRatio, scaleRatio);

        origin = CGPointMake(0, -(image.size.height - image.size.width) / 2.0f);
    }

    CGSize size = CGSizeMake(newSize, newSize);
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    } else {
        UIGraphicsBeginImageContext(size);
    }

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextConcatCTM(context, scaleTransform);

    [image drawAtPoint:origin];

    image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return image;
}

@end
