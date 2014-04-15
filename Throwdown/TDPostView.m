//
//  TDPostView.m
//  Throwdown
//
//  Created by Andrew C on 2/3/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDPostView.h"
#import "TDConstants.h"
#import "AVFoundation/AVFoundation.h"
#import "NSDate+TimeAgo.h"

typedef enum {
    ControlStatePaused,
    ControlStatePlay,
    ControlStateLoading,
    ControlStateNone
} ControlState;

@interface TDPostView ()

@property (weak, nonatomic) IBOutlet UIView *videoHolderView;
@property (weak, nonatomic) IBOutlet UIView *controlView;

@property (strong, nonatomic) UIImageView *controlImage;
@property (strong, nonatomic) UIImageView *playerSpinner;
@property (weak, nonatomic) IBOutlet UIView *topLine;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) TDPost *aPost;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) BOOL didPlay;
@property (nonatomic) BOOL isLoading;
@property (nonatomic) BOOL reachedEnd;

@end


@implementation TDPostView

@synthesize delegate;

- (void)dealloc {
    delegate = nil;
}

- (BOOL)reachedEnd {
    if (!_reachedEnd) {
        _reachedEnd = NO;
    }
    return _reachedEnd;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)awakeFromNib {

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCaptured:)];
    [self.controlView addGestureRecognizer:singleTap];

    [self.previewImage setMultipleTouchEnabled:YES];
    [self.previewImage setUserInteractionEnabled:YES];
    self.userInteractionEnabled=YES;

    self.usernameLabel.font = [UIFont fontWithName:@"ProximaNova-Semibold" size:17.0];
    self.createdLabel.font = [UIFont fontWithName:@"ProximaNova-Light" size:14.0];

    // top line to 0.5 high on retina
    CGRect topLineRect = self.topLine.frame;
    topLineRect.size.height = 1 / [[UIScreen mainScreen] scale];
    self.topLine.frame = topLineRect;
}

- (void)setPost:(TDPost *)post {

    // If it's the same (eg table was refreshed), bail so that we don't stop video playback
    if (self.isPlaying && [self.aPost isEqual:post]) {
        return;
    }

    self.aPost = post;
    self.usernameLabel.text = post.user.username;
    self.createdLabel.text = [post.createdAt timeAgo];

    self.filename = post.filename;
    self.isLoading = NO;
    self.isPlaying = NO;
    self.didPlay = NO;
    [self updateControlImage:ControlStateNone];

    // Likes & Comments
    [self.likeView setLike:post.liked];
    [self.likeView setLikesArray:post.likers totalLikersCount:888];
    [self.likeView setCommentsArray:post.comments];

    [self.previewImage setImage:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:TDDownloadPreviewImageNotification
                                                        object:self
                                                      userInfo:@{@"imageView":self.previewImage, @"filename":self.filename}];

    if (self.player != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:TDNotificationStopPlayers
                                                      object:self];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];

        [self.playerItem removeObserver:self forKeyPath:@"status" context:nil];
        [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty" context:nil];
        [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp" context:nil];

        [self.playerLayer removeFromSuperlayer];
        self.player = nil;
        self.playerItem = nil;
        self.playerLayer = nil;
    }
}

- (void)updateControlImage:(ControlState)controlState {
    if (!self.playerSpinner) {
        self.playerSpinner = [[UIImageView alloc] initWithFrame:CGRectMake(290.0, 332.0, 20.0, 20.0)];
        [self addSubview:self.playerSpinner];
    }
    [self stopSpinner];
    switch (controlState) {
        case ControlStatePlay:
            [self.playerSpinner setImage:[UIImage imageNamed:@"video_status_play"]];
            break;
        case ControlStatePaused:
            [self.playerSpinner setImage:[UIImage imageNamed:@"video_status_pause"]];
            break;
        case ControlStateLoading:
            [self.playerSpinner setImage:[UIImage imageNamed:@"video_status_spinner"]];
            [self startSpinner];
            break;
        case ControlStateNone:
            [self.playerSpinner setImage:nil];
            break;
    }
}

- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture {
    if (!self.isLoading) {
        if (self.isPlaying) {
            [self stopVideo];
        } else {
            [self startVideo];
        }
    }
}

- (void)stopVideoFromNotification:(NSNotification *)notification {
    // Ignore if we're sending to ourselves
    if (notification.object != self.filename) {
        debug NSLog(@"TDNotificationStopPlayers ACCEPTED");
        // setting didPlay prevents auto-play if this notification is received
        // after tapping to start a video before video finishes buffering
        self.didPlay = YES;
        [self stopVideo];
    } else {
        debug NSLog(@"TDNotificationStopPlayers IGNORED");
    }
}

- (void)stopVideo {
    if (self.isPlaying) {
        self.isPlaying = NO;
        [self.player pause];
        [self updateControlImage:ControlStatePaused];
    }
}

- (void)startVideo {
    // Stop any previous players
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:self.filename];

    if (self.player == nil)  {
        self.isLoading = YES;
        NSURL *location = [TDConstants getStreamingUrlFor:self.filename];
        debug NSLog(@"Loading movie from: %@", location);

        self.playerLayer = [AVPlayerLayer layer];
        [self.playerLayer setFrame:CGRectMake(0, 0, 320, 320)];
        [self.playerLayer setBackgroundColor:[UIColor blackColor].CGColor];
        [self.playerLayer setVideoGravity:AVLayerVideoGravityResize];
        [self.videoHolderView.layer addSublayer:self.playerLayer];
        self.playerLayer.hidden = YES;

        [self updateControlImage:ControlStateLoading];

        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:location options:nil];
        NSString *tracksKey = @"tracks";

        [asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
               NSError *error;
               AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];

               if (status == AVKeyValueStatusLoaded) {
                   self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                   [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
                   [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
                   [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];

                   [[NSNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(stopVideoFromNotification:)
                                                                name:TDNotificationStopPlayers
                                                              object:nil];
                   [[NSNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(playerItemDidReachEnd:)
                                                                name:AVPlayerItemDidPlayToEndTimeNotification
                                                              object:self.playerItem];

                   self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
                   [self.playerLayer setPlayer:self.player];

                   // Not sure why we have to specify this specifically, since this value is defined as default
                   [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategorySoloAmbient error: nil];
               } else {
                   // TODO: Put up an error state on the view
                   debug NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
               }
           });
         }];
    } else {
        self.isPlaying = YES;
        if (self.reachedEnd) {
            [self.player seekToTime:kCMTimeZero];
            self.reachedEnd = NO;
        }
        [self.player play];
        [self updateControlImage:ControlStateNone];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.playerItem && [keyPath isEqualToString:@"playbackBufferEmpty"]) {
        [self updateControlImage:ControlStateLoading];
        return;
    } else if (object == self.playerItem && [keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        [self updateControlImage:ControlStateNone];
        return;
    } else if (object == self.playerItem && [keyPath isEqualToString:@"status"]) {

        if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.playerLayer.hidden = NO;
                // Only play once on status change (status change is called every time the player is reset)
                if (self.isLoading) {
                    self.isLoading = NO;
                    [self stopSpinner];
                    [self updateControlImage:ControlStateNone];
                }
                if (!self.didPlay) {
                    self.didPlay = YES;
                    [self startVideo];
                }
            });
        }
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    self.isPlaying = NO;
    self.reachedEnd = YES;
    [self updateControlImage:ControlStatePlay];
}

- (void)startSpinner {
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
    rotationAnimation.duration = 1.0;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

    [self.playerSpinner.layer addAnimation:rotationAnimation forKey:kSpinningAnimation];
}

- (void)stopSpinner {
    [self.playerSpinner.layer removeAnimationForKey:kSpinningAnimation];
}

/*-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (delegate) {
        if ([delegate respondsToSelector:@selector(postTouchedFromRow:)]) {
            [delegate postTouchedFromRow:self.row];
        }
    }
} */

#pragma mark - User Name Button
- (IBAction)userButtonPressed:(UIButton *)sender
{
    NSLog(@"userButtonPressed");

    if (delegate) {
        if ([delegate respondsToSelector:@selector(userButtonPressedFromRow:)]) {
            [delegate userButtonPressedFromRow:self.row];
        }
    }
}

@end
