//
//  TDViewController.m
//  Throwdown
//
//  Created by Andrew C on 1/16/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDViewController.h"
#import "GPUImage.h"
#import "AssetsLibrary/ALAssetsLibrary.h"

@interface TDViewController ()
@property (weak, nonatomic) IBOutlet UIButton *button;
- (IBAction)recordButton:(id)sender;
@property (weak, nonatomic) IBOutlet GPUImageView *previewLayer;

@property GPUImageCropFilter<GPUImageInput> *filter;
@property GPUImageMovieWriter *movieWriter;
@property GPUImageVideoCamera *videoCamera;
@property BOOL isRecording;

@end

@implementation TDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.isRecording = NO;
    self.videoCamera = [[GPUImageVideoCamera alloc]
                        initWithSessionPreset:AVCaptureSessionPreset640x480
                        cameraPosition:AVCaptureDevicePositionBack];

    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;

    self.filter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, 0.125f, 1.f, .75f)];
//    self.filter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.125f, 0.f, 1.f, .75f)];
//    self.filter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, 0.f, 1.f, 1.f)];
    [self.filter addTarget:self.previewLayer];

    [self.videoCamera addTarget:self.filter];
    [self.videoCamera startCameraCapture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)stopRecording {
    [self.button setTitle:@"Start" forState:UIControlStateNormal];
    [self.button setBackgroundColor:[UIColor greenColor]];
//    self.button.enabled = NO; // Avoids any future clicking before moving into edit mode

    [self.filter removeTarget:self.movieWriter];
    self.videoCamera.audioEncodingTarget = nil;
    [self.movieWriter finishRecording];

    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/WorkingMovie.m4v"];
    ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:[NSURL URLWithString:pathToMovie] completionBlock:^(NSURL *assetURL, NSError *error1) {
        self.movieWriter = nil;
        NSLog(@"Movie completed");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Saved!"
                                                        message: @"Saved to the camera roll."
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
    }];


    //            [videoCamera.inputCamera lockForConfiguration:nil];
    //            [videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
    //            [videoCamera.inputCamera unlockForConfiguration];
}

- (void)startRecording {
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/WorkingMovie.m4v"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];

    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(640.0, 640.0)];
    [self.filter addTarget:self.movieWriter];

    [self.button setTitle:@"Stop" forState:UIControlStateNormal];
    [self.button setBackgroundColor:[UIColor redColor]];

    // TODO: microphone should be done on load and unload to avoid the popup
    self.videoCamera.audioEncodingTarget = self.movieWriter;
    [self.movieWriter startRecording];
    NSLog(@"Movie started");

//    double delayInSeconds = 30.0;
//    dispatch_time_t stopTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//    dispatch_after(stopTime, dispatch_get_main_queue(), ^(void){
//        [self stopRecording];
//    });
}

- (IBAction)recordButton:(UIButton *)button {
    if (self.isRecording) {
        self.isRecording = NO;
        [self stopRecording];
    } else {
        self.isRecording = YES;
        [self startRecording];
    }
}

@end
