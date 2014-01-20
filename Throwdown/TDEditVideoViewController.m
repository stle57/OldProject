//
//  TDEditVideoViewController.m
//  Throwdown
//
//  Created by Andrew C on 1/17/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDEditVideoViewController.h"
#import "SAVideoRangeSlider.h"
#import <QuartzCore/QuartzCore.h>
#import "AVFoundation/AVFoundation.h"
#import "AssetsLibrary/ALAssetsLibrary.h"


@interface TDEditVideoViewController ()<SAVideoRangeSliderDelegate>

@property (strong, nonatomic) SAVideoRangeSlider *slider;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) NSURL *videoUrl;
@property (strong, nonatomic) NSURL *tmpVideoUrl;
@property (strong, nonatomic) AVAssetExportSession *exportSession;
@property (nonatomic) CGFloat startTime;
@property (nonatomic) CGFloat stopTime;
@property (nonatomic) BOOL hasEdited;

- (IBAction)playButton:(UIButton *)sender;
- (IBAction)doneButton:(id)sender;

@end

@implementation TDEditVideoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/WorkingMovieTemp.m4v"];
    self.tmpVideoUrl = [NSURL fileURLWithPath:pathToMovie];
    [self deleteTmpFile];
    self.hasEdited = NO;
}

- (void) editVideoAt:(NSString *)videoPath {
    self.videoUrl = [NSURL fileURLWithPath:videoPath];

    self.slider = [[SAVideoRangeSlider alloc] initWithFrame:CGRectMake(0, 20, 320, 50) videoUrl:self.videoUrl];
    self.slider.topBorder.backgroundColor = [UIColor colorWithRed: 0.996 green: 0.951 blue: 0.502 alpha: 1];
    self.slider.bottomBorder.backgroundColor = [UIColor colorWithRed: 0.992 green: 0.902 blue: 0.004 alpha: 1];
    self.slider.delegate = self;
    [self.slider setMaxGap:30];

    [self.view addSubview:self.slider];

    self.player = [AVPlayer playerWithURL:self.videoUrl];

    AVPlayerLayer *layer = [AVPlayerLayer layer];
    [layer setPlayer:self.player];
    [layer setFrame:CGRectMake(0, 100, 320, 320)];
    [layer setBackgroundColor:[UIColor redColor].CGColor];
    [layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.view.layer addSublayer:layer];
}

- (void)trimVideo {
    [self deleteTmpFile];
    self.hasEdited = YES;

    AVAsset *anAsset = [[AVURLAsset alloc] initWithURL:self.videoUrl options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:anAsset];
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {

        self.exportSession = [[AVAssetExportSession alloc]
                              initWithAsset:anAsset presetName:AVAssetExportPresetPassthrough];
        self.exportSession.outputURL = self.tmpVideoUrl;
        self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;

        CMTime start = CMTimeMakeWithSeconds(self.startTime, anAsset.duration.timescale);
        CMTime duration = CMTimeMakeWithSeconds(self.stopTime - self.startTime, anAsset.duration.timescale);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        self.exportSession.timeRange = range;

        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([self.exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"Export failed: %@", [[self.exportSession error] localizedDescription]);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"Export canceled");
                    break;
                default:
                    NSLog(@"NONE");
                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [self playMovie];
                    });
                    break;
            }
        }];
    }
}

-(void)playMovie {
    if (self.hasEdited) {
        AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:self.tmpVideoUrl];
        [self.player replaceCurrentItemWithPlayerItem:item];
    }
    [self.player play];
}

- (IBAction)playButton:(UIButton *)sender {
    [self playMovie];
}

- (IBAction)doneButton:(id)sender {
    ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:self.tmpVideoUrl completionBlock:^(NSURL *assetURL, NSError *error1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Saved!"
                                                        message: @"Saved to the camera roll."
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
    }];
}

#pragma mark - Other
-(void)deleteTmpFile {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL exist = [fm fileExistsAtPath:self.tmpVideoUrl.path];
    NSError *err;
    if (exist) {
        [fm removeItemAtURL:self.tmpVideoUrl error:&err];
        if (err) {
            NSLog(@"file remove error, %@", err.localizedDescription );
        }
    }
}

#pragma mark - SAVideoRangeSliderDelegate
- (void)videoRange:(SAVideoRangeSlider *)videoRange didChangeLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition
{
    self.startTime = leftPosition;
    self.stopTime = rightPosition;
}

- (void)videoRange:(SAVideoRangeSlider *)videoRange didGestureStateEndedLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition
{
    [self trimVideo];
}

@end
