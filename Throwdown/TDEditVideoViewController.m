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
#import "TDAnalytics.h"
#import "UIImage+Resizing.h"
#import "UIImage+Rotating.h"
#include <math.h>

static const NSString *ItemStatusContext;

@interface TDEditVideoViewController ()<SAVideoRangeSliderDelegate, UIAlertViewDelegate, UIScrollViewDelegate>

@property (nonatomic) SAVideoRangeSlider *slider;
@property (nonatomic) AVAsset *currentVideoAsset;
@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *playerItem;
@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) NSURL *recordedVideoUrl;
@property (nonatomic) NSURL *editingVideoUrl;
@property (nonatomic) NSURL *exportedVideoUrl;
@property (nonatomic) NSString *thumbnailPath;
@property (nonatomic) NSString *filename;
@property (nonatomic) NSString *photoPath;
@property (nonatomic) NSData *photoData;
@property (nonatomic) NSDictionary *metadata;
@property (nonatomic) CGFloat startTime;
@property (nonatomic) CGFloat stopTime;
@property (nonatomic) BOOL playing;
@property (nonatomic) BOOL reachedEnd;
@property (nonatomic) BOOL isOriginal;
@property (nonatomic) BOOL isSetup;
@property (nonatomic) UIImage *assetImage;

@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIImageView *previewImageView;
@property (nonatomic) UIView *videoContainerView;

// These need to be retained with a strong pointer
@property (nonatomic) AVAssetWriter *videoWriter;
@property (nonatomic) TDPostUpload *currentUpload;

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
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
    self.videoWriter = nil;
    if (self.recordedVideoUrl) {
        [self removePlayerItemObserver];
    }
}

- (BOOL)reachedEnd {
    if (!_reachedEnd) {
        _reachedEnd = NO;
    }
    return _reachedEnd;
}

#pragma mark - view lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    self.isSetup = NO;

    // Fix buttons for 3.5" screens
    if ([UIScreen mainScreen].bounds.size.height == 480.0) {
        self.controlsView.center = CGPointMake(self.controlsView.center.x, 430);
        self.coverView.center = CGPointMake(self.coverView.center.x, 212);
    }

    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:UIStatusBarAnimationFade];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    debug NSLog(@"edit view did appear");
    self.doneButton.enabled = YES;
    self.cancelButton.enabled = YES;
    self.playButton.enabled = YES;

    if (!self.isSetup) {
        if (self.recordedVideoUrl) {
            [self setupVideoEditing];
        } else {
            [self setupPhotoEditing];
        }
        self.isSetup = YES;
    }

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
        if (self.reachedEnd) {
            [self.player seekToTime:kCMTimeZero];
            self.reachedEnd = NO;
        }
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
    if (self.isOriginal) {
        NSString *text = self.recordedVideoUrl ?  @"Delete this video?" : @"Delete this photo?";
        UIAlertView *confirm = [[UIAlertView alloc] initWithTitle:text message:nil delegate:self cancelButtonTitle:@"Keep" otherButtonTitles:@"Delete", nil];
        [confirm show];
    } else {
        [self stopExistingUploads];
        [self performSegueWithIdentifier:@"UnwindSlideLeftSegue" sender:self];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self stopExistingUploads];
        [self performSegueWithIdentifier:@"UnwindSlideLeftSegue" sender:self];
    }
}

- (CGRect)previewRect {
    CGFloat y = [UIScreen mainScreen].bounds.size.height == 480.0 ? 52 : 96;
    return CGRectMake(0, y, 320, 320);
}

# pragma mark - saving

- (void)stopExistingUploads {
    // Stop any current uploads if user edited the video after starting the upload
    if (self.filename != nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUploadCancelled
                                                            object:nil
                                                          userInfo:@{ @"filename":[self.filename copy] }];
        self.filename = nil;
    }
}

- (IBAction)doneButtonPressed:(UIButton *)sender {
    self.doneButton.enabled = NO;
    self.cancelButton.enabled = NO;
    self.playButton.enabled = NO;

    self.filename = [TDPostAPI createUploadFileNameFor:[TDCurrentUser sharedInstance]];
    self.thumbnailPath = [NSHomeDirectory() stringByAppendingPathComponent:kThumbnailExportFilePath];
    debug NSLog(@"Creating filename %@", self.filename);

    if (self.recordedVideoUrl) {
        [self processVideo];
    } else {
        [self processPhoto];
    }
}

# pragma mark - segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MediaCloseSegue"]) {
        TDShareVideoViewController *vc = [segue destinationViewController];
        [vc addMedia:self.filename thumbnail:self.thumbnailPath isOriginal:self.isOriginal];
    }
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

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return self.recordedVideoUrl ? self.videoContainerView : self.previewImageView;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
     [self stopExistingUploads]; // b/c user has changed the crop for photo/video
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [[TDAnalytics sharedInstance] logEvent:@"camera_crop_moved"];
}

#pragma mark - Photo handling

- (void)editPhotoAt:(NSString *)photoPath metadata:(NSDictionary *)metadata {
    self.photoPath = photoPath;
    self.metadata = metadata;
    self.isOriginal = YES;
    debug NSLog(@"image metadata %@", metadata);
}

- (void)editImage:(UIImage *)assetImage {
    self.assetImage = assetImage;
    self.isOriginal = NO;
}

#pragma mark - Photo editing

- (void)processPhoto {
    NSMutableDictionary *metadata;
    if (self.metadata) {
        metadata = [self.metadata mutableCopy];
        // this way it's auto detect. easier than setting each different
        [metadata removeObjectForKey:@"Orientation"];
        debug NSLog(@"metadata %@", metadata);
    }

    UIImage *image;
    if (self.isOriginal) {
        image = [self cropImage:self.previewImageView.image];
        NSData *imageData = UIImageJPEGRepresentation(image, 0.97);
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageDataToSavedPhotosAlbum:imageData metadata:metadata completionBlock:nil];
    } else {
        // Only from album since we ignore orientation on captured photos
        CGFloat deg;
        image = self.previewImageView.image;
        switch (image.imageOrientation) {
            case UIImageOrientationUp: // Home button is on right
            case UIImageOrientationUpMirrored:
                deg = 0;
                break;
            case UIImageOrientationDown: // Home button is on left
            case UIImageOrientationDownMirrored:
                deg = M_PI;
                break;
            case UIImageOrientationLeft: // Phone is upside-down
            case UIImageOrientationLeftMirrored:
                deg = -M_PI_2;
                break;
            case UIImageOrientationRight: // Phone is upright
            case UIImageOrientationRightMirrored:
                deg = M_PI_2;
                break;
        }

        // Upright screenshots are stored with UIImageOrientationUp but width < height so skip rotation step
        if (deg != 0 || image.size.width >= image.size.height) {
            image = [self imageRotatedByRadian:image radian:deg];
        }
        image = [self cropImage:image];
    }

    UIImage *smaller = [image scaleToSize:CGSizeMake(640.0, 640.0) usingMode:NYXResizeModeScaleToFill];
    [TDFileSystemHelper removeFileAt:self.thumbnailPath];
    [UIImageJPEGRepresentation(smaller, 0.97) writeToFile:self.thumbnailPath atomically:YES];
    [[TDPostAPI sharedInstance] uploadPhoto:self.thumbnailPath withName:self.filename];

    [self performSegueWithIdentifier:@"MediaCloseSegue" sender:self];
}

- (UIImage *)imageRotatedByRadian:(UIImage *)image radian:(CGFloat)radian {
    CGFloat shorter = MIN(image.size.width, image.size.height);
    CGFloat longer = MAX(image.size.width, image.size.height);
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0, 0, longer, shorter)];
    CGAffineTransform t = CGAffineTransformMakeRotation(radian);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;

    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();

    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);

    // Rotate the image context
    CGContextRotateCTM(bitmap, radian);

    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-longer / 2, -shorter / 2, longer, shorter), [image CGImage]);

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)cropImage:(UIImage *)image {
	float zoomScale = 1.0 / [self.scrollView zoomScale];

	CGRect rect;
	rect.origin.x = [self.scrollView contentOffset].x * zoomScale;
	rect.origin.y = [self.scrollView contentOffset].y * zoomScale;
	rect.size.width = [self.scrollView bounds].size.width * zoomScale;
	rect.size.height = [self.scrollView bounds].size.height * zoomScale;

	CGImageRef cr = CGImageCreateWithImageInRect([image CGImage], rect);
	UIImage *cropped = [UIImage imageWithCGImage:cr];
	CGImageRelease(cr);
    return cropped;
}

- (void)setupPhotoEditing {
    self.playButton.hidden = YES;
    self.previewImageView = [[UIImageView alloc] initWithFrame:[self previewRect]];
    if (self.assetImage) {
        self.previewImageView.image = self.assetImage;
    } else {
        self.photoData = [NSData dataWithContentsOfFile:self.photoPath];
        self.previewImageView.image = [UIImage imageWithData:self.photoData];
    }

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.previewImageView.frame];
    [self.scrollView setBackgroundColor:[UIColor blackColor]];
    [self.scrollView setDelegate:self];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setShowsVerticalScrollIndicator:NO];
    [self.scrollView setMaximumZoomScale:2.0];

    CGRect rect = CGRectMake(0, 0, self.previewImageView.image.size.width, self.previewImageView.image.size.height);
    CGFloat shorter = MIN(rect.size.width, rect.size.height);

    [self.previewImageView setFrame:rect];

    [self.scrollView setContentSize:self.previewImageView.frame.size];
    [self.scrollView setMinimumZoomScale:self.scrollView.frame.size.width / shorter];
    [self.scrollView setZoomScale:[self.scrollView minimumZoomScale]];
    [self.scrollView addSubview:self.previewImageView];

    [self.view addSubview:self.scrollView];
    [self.view insertSubview:self.scrollView belowSubview:self.coverView];

    debug NSLog(@"photo size %@", NSStringFromCGSize(self.previewImageView.image.size));
    debug NSLog(@"scroll size %@", NSStringFromCGRect(self.scrollView.frame));
    debug NSLog(@"content size %@", NSStringFromCGSize(self.scrollView.contentSize));
}

#pragma mark - Video editing

- (void)editVideoAt:(NSString *)videoPath original:(BOOL)original {
    self.recordedVideoUrl = [NSURL fileURLWithPath:videoPath];
    self.editingVideoUrl = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:kVideoTrimmedFilePath]];
    self.isOriginal = original;

    [self deleteTmpFile];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if (![fileManager copyItemAtPath:[self.recordedVideoUrl path] toPath:[self.editingVideoUrl path] error:&error]) {
        NSLog(@"Couldn't copy video file to temp file: %@", [error localizedDescription]);
    }
    debug NSLog(@"edit video at %@", videoPath);
}

- (void)setupVideoEditing {
    self.playButton.hidden = NO;
    self.slider = [[SAVideoRangeSlider alloc] initWithFrame:CGRectMake(0, 0, 320, 44) videoUrl:self.recordedVideoUrl];
    self.slider.delegate = self;
    [self.slider setMinGap:.1f];
    [self.slider setMaxGap:30];
    [self.view addSubview:self.slider];

    self.currentVideoAsset = [AVURLAsset URLAssetWithURL:self.recordedVideoUrl options:nil];
    NSString *tracksKey = @"tracks";
    [self.currentVideoAsset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:^{
        AVKeyValueStatus status = [self.currentVideoAsset statusOfValueForKey:tracksKey error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == AVKeyValueStatusLoaded) {

                // TODO: What to do when there is no videoTrack?
                AVAssetTrack* videoTrack = [[self.currentVideoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
                CGSize videoSize = videoTrack.naturalSize;

                // Initially trim the video;
                // - This covers a weird case/bug when the end of the video would be erronious
                // - Also covers the case where the video is > 30 seconds
                self.startTime = self.slider.leftPosition;
                self.stopTime = self.slider.rightPosition;
                [self trimVideo];

                self.videoContainerView = [[UIView alloc] initWithFrame:[self previewRect]];

                CGFloat scale = self.videoContainerView.frame.size.width / MIN(videoSize.width, videoSize.height);
                CGRect rect;
                rect.origin.x = 0;
                rect.origin.y = 0;

                UIInterfaceOrientation orientation = [self orientationForTrack:videoTrack];
                if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
                    rect.size.width = videoSize.height * scale;
                    rect.size.height = videoSize.width * scale;
                } else {
                    rect.size.width = videoSize.width * scale;
                    rect.size.height = videoSize.height * scale;
                }

                self.playerItem = [AVPlayerItem playerItemWithAsset:self.currentVideoAsset];
                self.player = [AVPlayer playerWithPlayerItem:self.playerItem];

                self.playerLayer = [AVPlayerLayer layer];
                [self.playerLayer setFrame:rect];
                [self.playerLayer setBackgroundColor:[UIColor blackColor].CGColor];
                [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
                [self.playerLayer setPlayer:self.player];
                [self.videoContainerView.layer addSublayer:self.playerLayer];

                self.scrollView = [[UIScrollView alloc] initWithFrame:self.videoContainerView.frame];
                [self.scrollView setBackgroundColor:[UIColor blackColor]];
                [self.scrollView setDelegate:self];
                [self.scrollView setShowsHorizontalScrollIndicator:NO];
                [self.scrollView setShowsVerticalScrollIndicator:NO];
                // [self.scrollView setMaximumZoomScale:2.0];
                // [self.scrollView setMinimumZoomScale:];
                // [self.scrollView setZoomScale:scale];

                [self.videoContainerView setFrame:rect];

                [self.scrollView setContentSize:CGSizeMake(rect.size.width, rect.size.height)];
                [self.scrollView addSubview:self.videoContainerView];

                [self.view addSubview:self.scrollView];
                [self.view insertSubview:self.scrollView belowSubview:self.coverView];

                [self addPlayerItemObserver];

                debug NSLog(@"video scale %f", scale);
                debug NSLog(@"video size %@", NSStringFromCGSize(videoSize));
                debug NSLog(@"scroll size %@", NSStringFromCGRect(self.scrollView.frame));
                debug NSLog(@"content size %@", NSStringFromCGSize(self.scrollView.contentSize));
                debug NSLog(@"player layer size %@", NSStringFromCGRect(self.playerLayer.frame));
                debug NSLog(@"container size %@", NSStringFromCGRect(self.videoContainerView.frame));
            }
        });
    }];
}

- (UIInterfaceOrientation)orientationForTrack:(AVAssetTrack *)videoTrack {
    CGSize size = [videoTrack naturalSize];
    CGAffineTransform txf = [videoTrack preferredTransform];

    if (size.width == txf.tx && size.height == txf.ty) {
        return UIInterfaceOrientationLandscapeLeft;
    } else if (txf.tx == 0 && txf.ty == 0) {
        return UIInterfaceOrientationLandscapeRight;
    } else if (txf.tx == 0 && txf.ty == size.width) {
        return UIInterfaceOrientationPortraitUpsideDown;
    } else {
        return UIInterfaceOrientationPortrait;
    }
}

- (void)trimVideo {
    [self togglePlay:NO];
    [self deleteTmpFile];

    [self stopExistingUploads];

    AVAsset *asset = [[AVURLAsset alloc] initWithURL:self.recordedVideoUrl options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetPassthrough];
    exportSession.outputURL = self.editingVideoUrl;
    exportSession.outputFileType = AVFileTypeMPEG4;

    CMTime start = CMTimeMakeWithSeconds(self.startTime, asset.duration.timescale);
    CMTime duration = CMTimeMakeWithSeconds(self.stopTime - self.startTime - kGlobalVideoTrimTime, asset.duration.timescale);
    CMTimeRange range = CMTimeRangeMake(start, duration);
    exportSession.timeRange = range;


    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch ([exportSession status]) {
            case AVAssetExportSessionStatusFailed:
            case AVAssetExportSessionStatusCancelled:
                debug NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
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

- (void)processVideo {
    [self togglePlay:NO];

    [self createThumbnail];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.isOriginal) {
            // Save to library
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            [library writeVideoAtPathToSavedPhotosAlbum:self.editingVideoUrl completionBlock:nil];

            // Start upload
            [[TDPostAPI sharedInstance] uploadVideo:[self.editingVideoUrl path] withThumbnail:self.thumbnailPath withName:self.filename];

        } else {

            self.currentUpload = [[TDPostAPI sharedInstance] initializeVideoUploadwithThumnail:self.thumbnailPath withName:self.filename];
            [self compressVideo];
        }
    });

    [self performSegueWithIdentifier:@"MediaCloseSegue" sender:self];
}


- (void)createThumbnail {
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:self.currentVideoAsset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;

    // Get screenshot
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *thumbnail = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);

    // Crop it
    CGFloat zoomScale = 1 / (320 / MIN(thumbnail.size.width, thumbnail.size.height));
	CGRect rect;
	rect.origin.x = [self.scrollView contentOffset].x * zoomScale;
	rect.origin.y = [self.scrollView contentOffset].y * zoomScale;
	rect.size.width = [self.scrollView bounds].size.width * zoomScale;
	rect.size.height = [self.scrollView bounds].size.height * zoomScale;

	CGImageRef cr = CGImageCreateWithImageInRect([thumbnail CGImage], rect);
	thumbnail = [UIImage imageWithCGImage:cr];
	CGImageRelease(cr);

    // Scale it
    thumbnail = [thumbnail scaleToSize:CGSizeMake(640.0, 640.0) usingMode:NYXResizeModeScaleToFill];

    [TDFileSystemHelper removeFileAt:self.thumbnailPath];
    BOOL saved = [UIImageJPEGRepresentation(thumbnail, .97f) writeToFile:self.thumbnailPath atomically:YES];
    debug NSLog(@"created thumbnail success: %@", saved ? @"YES" : @"NO");
}

- (void)compressVideo {
    AVAsset *asset = [AVAsset assetWithURL:self.editingVideoUrl];
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.frameDuration = videoTrack.minFrameDuration;
    videoComposition.renderSize = CGSizeMake(640., 640.);

    CGRect rect;
    rect.origin.x = [self.scrollView contentOffset].x;
	rect.origin.y = [self.scrollView contentOffset].y;
	rect.size.width = [self.scrollView bounds].size.width;
	rect.size.height = [self.scrollView bounds].size.height;

    CGSize videoSize = videoTrack.naturalSize;
    CGFloat shorter = MIN(videoSize.height, videoSize.width);
    CGFloat longer = MAX(videoSize.height, videoSize.width);
    CGFloat rotation, tx, ty;
    UIInterfaceOrientation orientation = [self orientationForTrack:videoTrack];
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            rotation = M_PI_2;
            tx = -(rect.origin.y * videoSize.height / self.scrollView.frame.size.height);
            ty = -shorter;
            break;

        case UIInterfaceOrientationPortraitUpsideDown:
            rotation = -M_PI_2;
            tx = 0 - (longer - (rect.origin.y * videoSize.height / self.scrollView.frame.size.height));
            ty = 0;
            break;

        case UIInterfaceOrientationLandscapeLeft: // home button on the left
            rotation = M_PI;
            tx = 0 - (longer - (rect.origin.x * videoSize.height / self.scrollView.frame.size.height));
            ty = -shorter;
            break;

        case UIInterfaceOrientationLandscapeRight: // home button on the right
            rotation = 0;
            tx = -(rect.origin.x * videoSize.height / self.scrollView.frame.size.height);
            ty = 0;
            break;
    }

    //create a video instruction
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = videoTrack.timeRange;
    AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];

    // correctly orientate first(!)
    CGAffineTransform t1 = CGAffineTransformMakeRotation(rotation);

    // fix the location
    CGAffineTransform t2 = CGAffineTransformTranslate(t1, tx, ty);

    // scale down
    CGFloat scale = 640. / shorter;
    CGAffineTransform t3 = CGAffineTransformConcat(t2, CGAffineTransformMakeScale(scale, scale));

    [transformer setTransform:t3 atTime:kCMTimeZero];

    //add the transformer layer instructions, then add to video composition
    instruction.layerInstructions = @[transformer];
    videoComposition.instructions = @[instruction];

    //Create an Export Path to store the cropped video
    NSString *exportPath = [NSHomeDirectory() stringByAppendingPathComponent:kVideoExportedFilePath];
    self.exportedVideoUrl = [NSURL fileURLWithPath:exportPath];
    [TDFileSystemHelper removeFileAt:exportPath];

    NSError *werror = nil;
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:self.exportedVideoUrl fileType:AVFileTypeMPEG4 error:&werror];

    // Video input
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:[TDConstants defaultVideoCompressionSettings]];
    videoWriterInput.expectsMediaDataInRealTime = YES;
    [self.videoWriter addInput:videoWriterInput];

    NSError *verror = nil;
    AVAssetReader *videoReader = [[AVAssetReader alloc] initWithAsset:asset error:&verror];
    AVAssetReaderVideoCompositionOutput *assetVideoReaderOutput = [AVAssetReaderVideoCompositionOutput assetReaderVideoCompositionOutputWithVideoTracks:@[videoTrack] videoSettings:nil];
    assetVideoReaderOutput.videoComposition = videoComposition;
    [videoReader addOutput:assetVideoReaderOutput];

    // Audio
    NSError *aerror = nil;
    AVAssetWriterInput* audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:nil];
    audioWriterInput.expectsMediaDataInRealTime = YES;
    AVAssetReader *audioReader = [AVAssetReader assetReaderWithAsset:asset error:&aerror];
    AVAssetTrack* audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    AVAssetReaderOutput *readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
    [audioReader addOutput:readerOutput];

    [self.videoWriter addInput:audioWriterInput];
    [self.videoWriter startWriting];
    [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
    [videoReader startReading];
    dispatch_queue_t _processingQueue = dispatch_queue_create("assetAudioWriterQueue", NULL);
    [videoWriterInput requestMediaDataWhenReadyOnQueue:_processingQueue usingBlock:^{
        while ([videoWriterInput isReadyForMoreMediaData]) {

            CMSampleBufferRef sampleBuffer;
            if ([videoReader status] == AVAssetReaderStatusReading &&
                (sampleBuffer = [assetVideoReaderOutput copyNextSampleBuffer])) {

                BOOL result = [videoWriterInput appendSampleBuffer:sampleBuffer];
                CFRelease(sampleBuffer);
                debug NSLog(@"Writing video buffer");

                if (!result) {
                    NSLog(@"Video reading cancelled!");
                    [videoReader cancelReading];
                    break;
                }
            } else {
                [videoWriterInput markAsFinished];
                debug NSLog(@"video writing finished, with start %f duration %f", CMTimeGetSeconds(videoTrack.timeRange.start), CMTimeGetSeconds(videoTrack.timeRange.duration));

                switch ([videoReader status]) {
                    case AVAssetReaderStatusReading:
                        // the reader has more for other tracks, even if this one is done
                        NSLog(@"PROBLEM: AVAssetReaderStatusReading");
                        break;

                    case AVAssetReaderStatusCompleted: {
                        // video compression done
                        // Hook up audio
                        [audioReader startReading];
                        [self.videoWriter startSessionAtSourceTime:kCMTimeZero];

                        while ([audioWriterInput isReadyForMoreMediaData]) {
                            CMSampleBufferRef nextBuffer;
                            if ([audioReader status] == AVAssetReaderStatusReading &&
                                (nextBuffer = [readerOutput copyNextSampleBuffer])) {

                                BOOL result = [audioWriterInput appendSampleBuffer:nextBuffer];
                                CFRelease(nextBuffer);
                                debug NSLog(@"Writing audio buffer");
                                if (!result) {
                                    NSLog(@"Audio reading cancelled!");
                                    [audioReader cancelReading];
                                    break;
                                }

                            } else {
                                debug NSLog(@"audio writing finished, with start %f duration %f", CMTimeGetSeconds(audioTrack.timeRange.start), CMTimeGetSeconds(audioTrack.timeRange.duration));

                                [audioWriterInput markAsFinished];
                                [self.videoWriter endSessionAtSourceTime:videoTrack.timeRange.duration];
                                [self.videoWriter finishWritingWithCompletionHandler:^{
                                    debug NSLog(@"Finished writing to file");
                                    [self.currentUpload attachVideo:exportPath];
                                    self.currentUpload = nil;
                                    self.videoWriter = nil;
                                }];
                            }
                        }
                    }
                    break;
                    case AVAssetReaderStatusFailed:
                        NSLog(@"ERROR: AVAssetReaderStatusFailed: %@", videoReader.error);
                        [self.videoWriter cancelWriting];
                        self.videoWriter = nil;
                        break;
                }
                break;
            }
        }
    }];
}

#pragma mark - Video playback

- (void)setPlayerAssetFromUrl:(NSURL *)videoUrl {
    self.currentVideoAsset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    NSString *tracksKey = @"tracks";

    [self.currentVideoAsset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error;
            AVKeyValueStatus status = [self.currentVideoAsset statusOfValueForKey:tracksKey error:&error];

            if (status == AVKeyValueStatusLoaded) {
                if (self.playerItem == nil) {
                    self.playerItem = [AVPlayerItem playerItemWithAsset:self.currentVideoAsset];
                    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
                    [self.playerLayer setPlayer:self.player];
                } else {
                    [self removePlayerItemObserver];
                    self.playerItem = [AVPlayerItem playerItemWithAsset:self.currentVideoAsset];
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
    self.reachedEnd = YES;
    [self togglePlay:NO];
}

- (void)deleteTmpFile {
    [TDFileSystemHelper removeFileAt:[self.editingVideoUrl path]];
}


#pragma mark - SAVideoRangeSliderDelegate

- (void)videoRange:(SAVideoRangeSlider *)videoRange didChangeLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition {
    self.startTime = leftPosition;
    self.stopTime = rightPosition;
}

- (void)videoRange:(SAVideoRangeSlider *)videoRange didGestureStateEndedLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition {
    [self trimVideo];
    [[TDAnalytics sharedInstance] logEvent:@"camera_trimmed"];
}

@end
