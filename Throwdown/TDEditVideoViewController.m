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
#import "TDUserAPI.h"

#define TEMP_FILE_PATH @"Documents/WorkingMovieTemp.m4v"
#define TEMP_IMG_PATH @"Documents/working_image.jpg"

@interface TDEditVideoViewController ()<SAVideoRangeSliderDelegate>

@property (strong, nonatomic) SAVideoRangeSlider *slider;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) NSURL *videoUrl;
@property (strong, nonatomic) NSURL *tmpVideoUrl;
@property (strong, nonatomic) AVAssetExportSession *exportSession;
@property (nonatomic) CGFloat startTime;
@property (nonatomic) CGFloat stopTime;
@property (nonatomic) BOOL hasEdited;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;


- (IBAction)playButtonPressed:(UIButton *)sender;
- (IBAction)doneButtonPressed:(UIButton *)sender;
- (IBAction)cancelButtonPressed:(UIButton *)sender;

@end

@implementation TDEditVideoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        debug NSLog(@"edit init with nib");
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];

    // Fix buttons for 3.5" screens
    if ([UIScreen mainScreen].bounds.size.height == 480.0) {
        self.cancelButton.center = CGPointMake(self.cancelButton.center.x, [UIScreen mainScreen].bounds.size.height-(568.0-523.0));
        self.playButton.center = CGPointMake(self.playButton.center.x, [UIScreen mainScreen].bounds.size.height-(568.0-523.0));
        self.doneButton.center = CGPointMake(self.doneButton.center.x, [UIScreen mainScreen].bounds.size.height-(568.0-523.0));
    }

    debug NSLog(@"edit view did load");
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    debug NSLog(@"edit view will appear");
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:TEMP_FILE_PATH];
    self.tmpVideoUrl = [NSURL fileURLWithPath:pathToMovie];
    [self deleteTmpFile];
    self.hasEdited = NO;
}

- (void) editVideoAt:(NSString *)videoPath {
    self.videoUrl = [NSURL fileURLWithPath:videoPath];

    debug NSLog(@"edit video at %@", videoPath);

    self.slider = [[SAVideoRangeSlider alloc] initWithFrame:CGRectMake(0, 20, 320, 50) videoUrl:self.videoUrl];
    self.slider.topBorder.backgroundColor = [UIColor colorWithRed: 0.996 green: 0.951 blue: 0.502 alpha: 1];
    self.slider.bottomBorder.backgroundColor = [UIColor colorWithRed: 0.992 green: 0.902 blue: 0.004 alpha: 1];
    self.slider.delegate = self;
    [self.slider setMinGap:.1f];
    [self.slider setMaxGap:30];

    [self.view addSubview:self.slider];

    self.player = [AVPlayer playerWithURL:self.videoUrl];

    AVPlayerLayer *layer = [AVPlayerLayer layer];
    [layer setPlayer:self.player];
    [layer setFrame:CGRectMake(0, 100, 320, 320)];
    [layer setBackgroundColor:[UIColor blackColor].CGColor];
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
                    debug NSLog(@"Export failed: %@", [[self.exportSession error] localizedDescription]);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    debug NSLog(@"Export canceled");
                    break;
                default:
                    debug NSLog(@"NONE");
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

- (IBAction)playButtonPressed:(UIButton *)sender {
    [self playMovie];
}

- (IBAction)doneButtonPressed:(UIButton *)sender {
    ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:(self.hasEdited ? self.tmpVideoUrl : self.videoUrl) completionBlock:^(NSURL *assetURL, NSError *error1) {
        TDCurrentUser *user = [TDUserAPI sharedInstance].currentUser;
        TDPostAPI *api = [TDPostAPI sharedInstance];

        NSString *thumbnailPath = [self saveThumbnail];
        NSString *newName = [TDPostAPI createUploadFileNameFor:user]; // Will be used doing post to server API
        [api uploadVideo:[(self.hasEdited ? self.tmpVideoUrl : self.videoUrl) path] withThumbnail:thumbnailPath newName:newName];
        [api addPost:newName];
//        [api addPost:[[TDPost alloc]initWithUsername:user.username userId:user.userId filename:newName]];

        [self performSegueWithIdentifier:@"ReturnHomeSegue" sender:self];
    }];
}

- (IBAction)cancelButtonPressed:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (NSString *) saveThumbnail
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:(self.hasEdited ? self.tmpVideoUrl : self.videoUrl) options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;

    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);

    NSString *filePath = [NSHomeDirectory() stringByAppendingPathComponent:TEMP_IMG_PATH];
    unlink([filePath UTF8String]); // If a file already exists
    [UIImageJPEGRepresentation(thumb, .97f) writeToFile:filePath atomically:YES];
    return filePath;
}

#pragma mark - Other
-(void)deleteTmpFile {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL exist = [fm fileExistsAtPath:self.tmpVideoUrl.path];
    NSError *err;
    if (exist) {
        [fm removeItemAtURL:self.tmpVideoUrl error:&err];
        if (err) {
            debug NSLog(@"file remove error, %@", err.localizedDescription );
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
