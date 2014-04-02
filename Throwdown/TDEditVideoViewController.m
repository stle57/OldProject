//
//  TDEditVideoViewController.m
//  Throwdown
//
//  Created by Andrew C on 1/17/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDEditVideoViewController.h"
#import "TDHomeViewController.h"
#import "SAVideoRangeSlider.h"
#import <QuartzCore/QuartzCore.h>
#import "AVFoundation/AVFoundation.h"
#import "AssetsLibrary/ALAssetsLibrary.h"
#import "TDPostAPI.h"
#import "TDSlideLeftSegue.h"
#import "TDShareVideoViewController.h"
#import "TDUnwindSlideLeftSegue.h"
#import "TDConstants.h"
#import "TDFileSystemHelper.h"

#define TEMP_FILE_PATH @"Documents/WorkingMovieTemp.m4v"
#define TEMP_IMG_PATH @"Documents/working_image.jpg"

static const NSString *ItemStatusContext;

@interface TDEditVideoViewController ()<SAVideoRangeSliderDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) SAVideoRangeSlider *slider;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) NSURL *recordedVideoUrl;
@property (strong, nonatomic) NSURL *editingVideoUrl;
@property (strong, nonatomic) AVAssetExportSession *exportSession;
@property (strong, nonatomic) NSString *thumbnailPath;
@property (strong, nonatomic) NSString *filename;
@property (nonatomic) CGFloat startTime;
@property (nonatomic) CGFloat stopTime;
@property (nonatomic) BOOL playing;

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIView *videoContainerView;
@property (weak, nonatomic) IBOutlet UIView *controlsView;
@property (weak, nonatomic) IBOutlet UIView *coverView;


- (IBAction)playButtonPressed:(UIButton *)sender;
- (IBAction)doneButtonPressed:(UIButton *)sender;

@end

@implementation TDEditVideoViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)dealloc {
    [self removePlayerItemObserver];
}

#pragma mark - view lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];

    // Fix buttons for 3.5" screens
    if ([UIScreen mainScreen].bounds.size.height == 480.0) {
        self.controlsView.center = CGPointMake(self.controlsView.center.x, 430);
        self.videoContainerView.center = CGPointMake(self.controlsView.center.x, 212);
        self.coverView.center = CGPointMake(self.coverView.center.x, 212);
    }

    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:UIStatusBarAnimationFade];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.slider = [[SAVideoRangeSlider alloc] initWithFrame:CGRectMake(0, 0, 320, 44) videoUrl:self.recordedVideoUrl];
    self.slider.delegate = self;
    [self.slider setMinGap:.1f];
    [self.slider setMaxGap:30];
    [self.view addSubview:self.slider];

    self.playerLayer = [AVPlayerLayer layer];
    [self.playerLayer setPlayer:self.player];
    [self.playerLayer setFrame:CGRectMake(0, 0, 320, 320)];
    [self.playerLayer setBackgroundColor:[UIColor blackColor].CGColor];
    [self.playerLayer setVideoGravity:AVLayerVideoGravityResize];
    [self.videoContainerView.layer addSublayer:self.playerLayer];

    [self setPlayerAssetFromUrl:self.recordedVideoUrl];

    self.coverView.alpha = 1.0;
    [UIView animateWithDuration:0.2 delay:0.5 options:UIViewAnimationOptionCurveLinear animations:^{
        self.coverView.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.coverView.hidden = YES;
    }];
}

#pragma mark - view actions

- (IBAction)playButtonPressed:(UIButton *)sender {
    [self togglePlay:!self.playing];
}

- (void)togglePlay:(BOOL)play {
    if (play) {
        [self.player play];
    } else {
        [self.player pause];
    }
    [self updatePlayButtonWith:play];
    self.playing = play;
}

- (void)updatePlayButtonWith:(BOOL)playing {
    if (playing) {
        [self.playButton setImage:[UIImage imageNamed:@"v_pausebutton"] forState:UIControlStateNormal];
        [self.playButton setImage:[UIImage imageNamed:@"v_pausebutton_hit"] forState:UIControlStateHighlighted];
    } else {
        [self.playButton setImage:[UIImage imageNamed:@"v_playbutton"] forState:UIControlStateNormal];
        [self.playButton setImage:[UIImage imageNamed:@"v_playbutton_hit"] forState:UIControlStateHighlighted];
    }
}

- (IBAction)cancelButtonPressed:(id)sender {
    UIAlertView *confirm = [[UIAlertView alloc] initWithTitle:@"Delete this video?" message:nil delegate:self cancelButtonTitle:@"Delete Video" otherButtonTitles:@"Keep", nil];
    [confirm show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        [self stopExistingUploads];
        [self performSegueWithIdentifier:@"UnwindSlideLeftSegue" sender:self];
    }
}

# pragma mark - saving

- (IBAction)doneButtonPressed:(UIButton *)sender {
    [self togglePlay:NO];

    ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:(self.editingVideoUrl) completionBlock:nil];

    self.filename = [TDPostAPI createUploadFileNameFor:[TDCurrentUser sharedInstance]];

    self.thumbnailPath = [NSHomeDirectory() stringByAppendingPathComponent:TEMP_IMG_PATH];
    [self saveThumbnailTo:self.thumbnailPath];

    TDPostAPI *api = [TDPostAPI sharedInstance];
    [api uploadVideo:[self.editingVideoUrl path] withThumbnail:self.thumbnailPath withName:self.filename];

    [self performSegueWithIdentifier:@"ShareVideoSegue" sender:self];
}

- (void)saveThumbnailTo:(NSString *)filePath {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:self.editingVideoUrl options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;

    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);

    unlink([filePath UTF8String]); // If a file already exists
    [UIImageJPEGRepresentation(thumb, .97f) writeToFile:filePath atomically:YES];
}

# pragma mark - segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue isKindOfClass:[TDSlideLeftSegue class]]) {
        TDShareVideoViewController *vc = [segue destinationViewController];
        [vc shareVideo:self.filename withThumbnail:self.thumbnailPath];
    }
}

- (IBAction)unwindToEditVideo:(UIStoryboardSegue *)sender {
    // Empty on purpose
}

- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {

    if ([@"UnwindSlideLeftSegue" isEqualToString:identifier]) {
        return [[TDUnwindSlideLeftSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    } else {
        return [super segueForUnwindingToViewController:toViewController
                                     fromViewController:fromViewController
                                             identifier:identifier];
    }
}

#pragma mark - SAVideoRangeSliderDelegate

- (void)videoRange:(SAVideoRangeSlider *)videoRange didChangeLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition {
    self.startTime = leftPosition;
    self.stopTime = rightPosition;
}

- (void)videoRange:(SAVideoRangeSlider *)videoRange didGestureStateEndedLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition {
    [self trimVideo];
}

#pragma mark - video handling / trimming

- (void)stopExistingUploads {
    // Stop any current uploads if user edited the video after starting the upload
    if (self.filename != nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUploadCancelled
                                                            object:nil
                                                          userInfo:@{ @"filename":[self.filename copy] }];
        self.filename = nil;
    }
}

- (void)editVideoAt:(NSString *)videoPath {
    self.recordedVideoUrl = [NSURL fileURLWithPath:videoPath];
    self.editingVideoUrl = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:TEMP_FILE_PATH]];

    [self deleteTmpFile];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if (![fileManager copyItemAtPath:[self.recordedVideoUrl path] toPath:[self.editingVideoUrl path] error:&error]) {
        NSLog(@"Couldn't copy video file to temp file: %@", [error localizedDescription]);
    }

    debug NSLog(@"edit video at %@", videoPath);
}

- (void)trimVideo {
    [self togglePlay:NO];
    [self deleteTmpFile];

    [self stopExistingUploads];

    AVAsset *anAsset = [[AVURLAsset alloc] initWithURL:self.recordedVideoUrl options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:anAsset];
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {

        self.exportSession = [[AVAssetExportSession alloc]
                              initWithAsset:anAsset presetName:AVAssetExportPresetPassthrough];
        self.exportSession.outputURL = self.editingVideoUrl;
        self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;

        CMTime start = CMTimeMakeWithSeconds(self.startTime, anAsset.duration.timescale);
        CMTime duration = CMTimeMakeWithSeconds(self.stopTime - self.startTime, anAsset.duration.timescale);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        self.exportSession.timeRange = range;

        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([self.exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                case AVAssetExportSessionStatusCancelled:
                    debug NSLog(@"Export failed: %@", [[self.exportSession error] localizedDescription]);
                    [self.slider setLeftPosition:0.0];
                    [self.slider setRightPosition:320.0];
                    [self setPlayerAssetFromUrl:self.recordedVideoUrl];
                    break;
                default:
                    [self setPlayerAssetFromUrl:self.editingVideoUrl];
                    break;
            }
        }];
    }
}

- (void)setPlayerAssetFromUrl:(NSURL *)videoUrl {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    NSString *tracksKey = @"tracks";

    [asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error;
            AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];

            if (status == AVKeyValueStatusLoaded) {
                if (self.playerItem == nil) {
                    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
                    [self.playerLayer setPlayer:self.player];
                } else {
                    [self removePlayerItemObserver];
                    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
                }
                [self addPlayerItemObserver];
            } else {
                // TODO: Put up an error state on the view (shouldn't happen with local videos?)
                debug NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
            }
        });
    }];
}

- (void)addPlayerItemObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
}

- (void)removePlayerItemObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.playerItem];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self.player seekToTime:kCMTimeZero];
    [self togglePlay:NO];
}

-(void)deleteTmpFile {
    [TDFileSystemHelper removeFileAt:[self.editingVideoUrl path]];
}

@end
