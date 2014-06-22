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
#import "TDAppDelegate.h"
#import "TDAPIClient.h"
#import <QuartzCore/QuartzCore.h>

typedef enum {
    ControlStatePaused,
    ControlStatePlay,
    ControlStateLoading,
    ControlStateNone
} ControlState;


typedef enum {
    PlayerStateNotLoaded,
    PlayerStateLoading,
    PlayerStatePlaying,
    PlayerStatePaused,
    PlayerStateReachedEnd
} PlayerState;

@interface TDPostView ()

@property (weak, nonatomic) IBOutlet UIView *videoHolderView;
@property (weak, nonatomic) IBOutlet UIImageView *controlView;
@property (weak, nonatomic) IBOutlet UIView *topLine;

@property (strong, nonatomic) UIImageView *controlImage;
@property (strong, nonatomic) UIImageView *playerSpinner;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) TDPost *aPost;
@property (nonatomic) PlayerState state;
@property (nonatomic) NSTimer *loadingTimeout;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@end


@implementation TDPostView

@synthesize delegate;

- (void)dealloc {
    delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    [self.previewImage setMultipleTouchEnabled:YES];
    [self.previewImage setUserInteractionEnabled:YES];
    self.userInteractionEnabled=YES;

    self.usernameLabel.font = [TDConstants fontSemiBoldSized:17.0];
    self.createdLabel.font = [TDConstants fontLightSized:14.0];

    self.userProfileImage.layer.cornerRadius = self.userProfileImage.layer.frame.size.width / 2;
    self.userProfileImage.clipsToBounds = YES;

    // top line to 0.5 high on retina
    CGRect topLineRect = self.topLine.frame;
    topLineRect.size.height = 1 / [[UIScreen mainScreen] scale];
    self.topLine.frame = topLineRect;

    origRectOfUserButton = self.userNameButton.frame;

    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    [self.controlView addGestureRecognizer:self.tapGestureRecognizer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseTapGesture:) name:TDNotificationPauseTapGesture object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeTapGesture:) name:TDNotificationResumeTapGesture object:nil];
}

- (void)pauseTapGesture:(NSNotification *)n {
    [self.controlView removeGestureRecognizer:self.tapGestureRecognizer];
}

- (void)resumeTapGesture:(NSNotification *)n {
    [self.controlView addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)setPost:(TDPost *)post {
    if (post == nil) {
        return;
    }

    // Only update if this isn't the same post or username or picture has changed
    if ([self.filename isEqualToString:post.filename] && [self.usernameLabel.text isEqualToString:post.user.username] && [self.userPicture isEqualToString:post.user.picture]) {
        return;
    }
    self.userPicture = post.user.picture;

    // If it's the same (eg table was refreshed), bail so that we don't stop video playback
    if (self.state == PlayerStatePlaying && [self.aPost isEqual:post]) {
        return;
    }

    self.state = PlayerStateNotLoaded;
    self.aPost = post;
    self.usernameLabel.text = post.user.username;
    self.userNameButton.frame = CGRectMake(origRectOfUserButton.origin.x,
                                           origRectOfUserButton.origin.y,
                                           [TDAppDelegate minWidthOfThisLabel:self.usernameLabel] + self.usernameLabel.frame.origin.x,
                                           origRectOfUserButton.size.height);

    // Set first to not show the wrong image while loading or if load fails
    [self.userProfileImage setImage:[UIImage imageNamed:@"prof_pic_default"]];
    if (post.user && ![post.user hasDefaultPicture]) {
        [[TDAPIClient sharedInstance] setImage:@{@"imageView":self.userProfileImage,
                                                 @"filename":post.user.picture,
                                                 @"width":[NSNumber numberWithInt:self.userProfileImage.frame.size.width],
                                                 @"height":[NSNumber numberWithInt:self.userProfileImage.frame.size.height]}];
    }

    self.createdLabel.labelDate = post.createdAt;
    self.createdLabel.text = [post.createdAt timeAgo];

    self.filename = post.filename;

    if (post.kind == TDPostKindVideo) {
        [self updateControlImage:ControlStatePlay];
    } else {
        [self updateControlImage:ControlStateNone];
    }

    // Likes & Comments
    [self.likeView setLike:post.liked];
    [self.likeView setLikesArray:post.likers totalLikersCount:888];
    [self.likeView setCommentsArray:post.comments];

    [self.previewImage setImage:nil];
    [self hideLoadingError];

    if (self.filename) {
        [[TDAPIClient sharedInstance] setImage:@{@"imageView":self.previewImage, @"filename":[self.filename stringByAppendingString:FTImage]}];
    }

    if (self.player != nil) {
        [self removeObservers];
    }
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:TDNotificationStopPlayers
                                                  object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.playerItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemPlaybackStalledNotification
                                                  object:self.playerItem];

    [self.playerItem removeObserver:self forKeyPath:@"status" context:nil];
    //        [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty" context:nil];
    //        [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp" context:nil];
    [self.playerLayer removeFromSuperlayer];
    self.player = nil;
    self.playerItem = nil;
    self.playerLayer = nil;
}

- (void)updateControlImage:(ControlState)controlState {
    if (!self.playerSpinner) {
        self.playerSpinner = [[UIImageView alloc] initWithFrame:CGRectMake(290.0, 332.0, 20.0, 20.0)];
        [self addSubview:self.playerSpinner];
    }
    [self stopSpinner];
    debug NSLog(@"update control state to: %d", controlState);
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

- (void)handleTapFrom:(UITapGestureRecognizer *)tap {
    if (self.aPost.kind == TDPostKindVideo) {

        switch (self.state) {
            case PlayerStateNotLoaded:
                [self loadVideo];
                break;

            case PlayerStatePlaying:
                [self stopVideo];
                break;

            case PlayerStateReachedEnd:
                self.state = PlayerStateLoading;
                [self updateControlImage:ControlStateLoading];
                [self startLoadingTimeout];
                [self.player seekToTime:kCMTimeZero];
                break;

            case PlayerStatePaused:
                [self playVideo];
                break;

            case PlayerStateLoading:
                // Do nothing
                break;
        }
    }
}

- (void)stopVideo {
    self.state = PlayerStatePaused;
    [self.player pause];
    [self updateControlImage:ControlStatePaused];
}

- (void)playVideo {
    self.state = PlayerStatePlaying;
    [self updateControlImage:ControlStateNone];
    [self.player play];
}

- (void)loadVideo {
    // Stop any previous players
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:self.filename];

    if (self.player != nil) {
        [self removeObservers];
    }

    self.state = PlayerStateLoading;
    [self hideLoadingError];

    NSURL *location = [TDConstants getStreamingUrlFor:self.filename];
    debug NSLog(@"Loading movie from: %@", location);

    self.playerLayer = [AVPlayerLayer layer];
    [self.playerLayer setFrame:CGRectMake(0, 0, 320, 320)];
    [self.playerLayer setBackgroundColor:[UIColor blackColor].CGColor];
    [self.playerLayer setVideoGravity:AVLayerVideoGravityResize];
    [self.videoHolderView.layer addSublayer:self.playerLayer];
    self.playerLayer.hidden = YES;

    [self updateControlImage:ControlStateLoading];
    [self startLoadingTimeout];

    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:location options:nil];
    NSString *tracksKey = @"tracks";

    [asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error;
            AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];

            if (status == AVKeyValueStatusLoaded) {
                self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];

                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(stopVideoFromNotification:)
                                                             name:TDNotificationStopPlayers
                                                           object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(playerItemDidReachEnd:)
                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                           object:self.playerItem];
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(playerItemDidStall:)
                                                             name:AVPlayerItemPlaybackStalledNotification
                                                           object:self.playerItem];

                self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
                [self.playerLayer setPlayer:self.player];

                // Not sure why we have to specify this specifically, since this value is defined as default
                [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategorySoloAmbient error: nil];
            } else {
                debug NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
                self.state = PlayerStateNotLoaded;
                [self showLoadingError];
            }
        });
    }];
}

- (void)stopVideoFromNotification:(NSNotification *)notification {
    // Ignore if we're sending to ourselves
    if (notification.object != self.filename) {
        debug NSLog(@"TDNotificationStopPlayers ACCEPTED");
        if (self.state == PlayerStateLoading || self.state == PlayerStateNotLoaded) {
            self.state = PlayerStateNotLoaded;
        } else {
            self.state = PlayerStatePaused;
            [self stopVideo];
        }
    } else {
        debug NSLog(@"TDNotificationStopPlayers IGNORED");
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.playerItem && [keyPath isEqualToString:@"status"]) {
        debug NSLog(@"PLAYBACK: status at state %d", self.state);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
                self.playerLayer.hidden = NO;
                // Only play once it's been loaded
                // status change is called every time the player is reset
                if (self.state == PlayerStateLoading) {
                    [self updateControlImage:ControlStateNone];
                    [self playVideo];
                }
            } else if (self.playerItem.status == AVPlayerItemStatusFailed) {
                debug NSLog(@"PLAYBACK: failed!");
                self.state = PlayerStateNotLoaded;
                [self showLoadingError];
            }
        });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
}

- (void)startLoadingTimeout {
    if (self.loadingTimeout) {
        [self.loadingTimeout invalidate];
    }
    self.loadingTimeout = [NSTimer scheduledTimerWithTimeInterval:30.0
                                                           target:self
                                                         selector:@selector(loadingTimedOut:)
                                                         userInfo:nil
                                                          repeats:NO];
}

- (void)loadingTimedOut:(NSTimer *)timer {
    if (self.state == PlayerStateLoading) {
        debug NSLog(@"PLAYBACK: timeout");
        self.state = PlayerStateNotLoaded;
        [self showLoadingError];
    }
}

- (void)playerItemDidStall:(NSNotification *)notification {
    debug NSLog(@"PLAYBACK: stalled");
    self.state = PlayerStateNotLoaded;
    [self showLoadingError];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    debug NSLog(@"PLAYBACK: reached end");
    self.state = PlayerStateReachedEnd;
    [self updateControlImage:ControlStatePlay];
   [self hideLoadingError];
}

- (void)showLoadingError {
    [self updateControlImage:ControlStateNone];
    self.controlView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    [self.controlView setImage:[UIImage imageNamed:@"video_status_retry"]];
}

- (void)hideLoadingError {
    self.controlView.backgroundColor = [UIColor clearColor];
    [self.controlView setImage:nil];
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

#pragma mark - User Name Button
- (IBAction)userButtonPressed:(UIButton *)sender {
    if (delegate && [delegate respondsToSelector:@selector(userButtonPressedFromRow:)]) {
        [delegate userButtonPressedFromRow:self.row];
    }
}
@end
