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
#import "TDViewControllerHelper.h"
#import <TTTAttributedLabel/TTTAttributedLabel.h>
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

static CGFloat const kHeightOfProfileRow = 42.;
static CGFloat const kCommentBottomPadding = 10.;
static CGFloat const kHeightOfMedia = 320.;
static CGFloat const kWidthOfMedia = 320.;

@interface TDPostView () <TTTAttributedLabelDelegate>

@property (nonatomic) UIView *videoHolderView;
@property (nonatomic) TTTAttributedLabel *commentLabel;
@property (nonatomic) UIImageView *controlView;
@property (nonatomic) UIImageView *prStar;
@property (nonatomic) UIImageView *controlImage;
@property (nonatomic) UIImageView *playerSpinner;
@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *playerItem;
@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) TDPost *post;
@property (nonatomic) PlayerState state;
@property (nonatomic) NSTimer *loadingTimeout;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@end


@implementation TDPostView

- (void)dealloc {
    self.delegate = nil;
    if (self.controlView && self.tapGestureRecognizer) {
        [self.controlView removeGestureRecognizer:self.tapGestureRecognizer];
    }
    for (UIGestureRecognizer *g in self.usernameLabel.gestureRecognizers) {
        [self.usernameLabel removeGestureRecognizer:g];
    }
    for (UIGestureRecognizer *g in self.userProfileImage.gestureRecognizers) {
        [self.userProfileImage removeGestureRecognizer:g];
    }
    self.usernameLabel = nil;
    self.post = nil;
    self.commentLabel.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {

        self.userInteractionEnabled = YES;

        // add pr star at lowest level
        self.prStar = [[UIImageView alloc] initWithFrame:CGRectMake(235, 0, 85, 90.5)];
        self.prStar.image = [UIImage imageNamed:@"pr_star_in_feed_170x181"];
        self.prStar.hidden = YES;
        [self addSubview:self.prStar];

        self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(42, 5, 215, 32)];
        self.usernameLabel.font = [TDConstants fontSemiBoldSized:17.0];
        self.usernameLabel.textColor = [TDConstants brandingRedColor];
        self.usernameLabel.numberOfLines = 1;
        self.usernameLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *usernameTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(usernamePressed:)];
        [self.usernameLabel addGestureRecognizer:usernameTap];
        [self addSubview:self.usernameLabel];

        self.commentLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(7, 42, COMMENT_MESSAGE_WIDTH, 0)];
        self.commentLabel.textColor = [TDConstants commentTextColor];
        self.commentLabel.font  = COMMENT_MESSAGE_FONT;
        self.commentLabel.delegate = self;
        self.commentLabel.hidden = YES;
        self.commentLabel.numberOfLines = 0;
        [self addSubview:self.commentLabel];

        self.createdLabel = [[TDUpdatingDateLabel alloc] initWithFrame:CGRectMake(260, 5, 53, 32)];
        self.createdLabel.textColor = [TDConstants commentTimeTextColor];
        self.createdLabel.font = [TDConstants fontLightSized:14.0];
        self.createdLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:self.createdLabel];

        self.userProfileImage = [[UIImageView alloc] initWithFrame:CGRectMake(7, 7, 28, 28)];
        self.userProfileImage.image = [UIImage imageNamed:@"prof_pic_default"];
        self.userProfileImage.backgroundColor = [TDConstants darkBackgroundColor];
        self.userProfileImage.layer.cornerRadius = self.userProfileImage.layer.frame.size.width / 2;
        self.userProfileImage.clipsToBounds = YES;
        self.userProfileImage.userInteractionEnabled = YES;
        UITapGestureRecognizer *userProfileTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(usernamePressed:)];
        [self.userProfileImage addGestureRecognizer:userProfileTap];
        [self addSubview:self.userProfileImage];

        UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 1 / [[UIScreen mainScreen] scale])];
        topLine.backgroundColor = [TDConstants borderColor];
        [self addSubview:topLine];
    }
    return self;
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
    if (self.state == PlayerStatePlaying && [self.post isEqual:post]) {
        return;
    }

    _post = post;
    self.state = PlayerStateNotLoaded;

    // Set username label and size (for tap area)
    self.usernameLabel.text = post.user.username;
    CGSize size = [self.usernameLabel sizeThatFits:CGSizeMake(215, 32)];
    CGRect frame = self.usernameLabel.frame;
    frame.size.width = size.width;
    self.usernameLabel.frame = frame;

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

    // We re-add the video every time it's needed
    [self removeVideo];

    if (post.comment) {
        // Comment body
        CGRect commentFrame = self.commentLabel.frame;
        commentFrame.size.width = COMMENT_MESSAGE_WIDTH;
        self.commentLabel.frame = commentFrame;
        self.commentLabel.font = COMMENT_MESSAGE_FONT;
        self.commentLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;

        [self.commentLabel setText:post.comment afterInheritingLabelAttributesAndConfiguringWithBlock:nil];
        [TDViewControllerHelper linkUsernamesInLabel:self.commentLabel users:post.mentions];
        self.commentLabel.attributedText = [TDViewControllerHelper makeParagraphedTextWithAttributedString:self.commentLabel.attributedText];
        CGFloat commentHeight = [TDViewControllerHelper heightForComment:post.comment withMentions:post.mentions];
        CGRect frame = self.commentLabel.frame;
        frame.size.height = commentHeight == 0 ? 0 : commentHeight + kCommentBottomPadding;
        self.commentLabel.frame = frame;
        self.commentLabel.hidden = NO;
    } else {
        self.commentLabel.hidden = YES;
    }

    self.prStar.hidden = !post.personalRecord;

    switch (post.kind) {
        case TDPostKindPhoto:
            self.filename = post.filename;
            [self setupPreview];
            break;

        case TDPostKindVideo:
            self.filename = post.filename;
            [self setupPreview];
            [self setupVideo];
            [self updateControlImage:ControlStatePlay];
            break;

        case TDPostKindText:
            [self removePreview];
            break;

        default:
            break;
    }
}

- (CGFloat)getMediaOffset {
    return kHeightOfProfileRow + (self.commentLabel.hidden ? 0 : self.commentLabel.frame.size.height);
}

- (void)setupPreview {
    if (!self.previewImage) {
        self.previewImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, [self getMediaOffset], kHeightOfMedia, kWidthOfMedia)];
        self.previewImage.backgroundColor = [TDConstants darkBackgroundColor];
        [self.previewImage setUserInteractionEnabled:YES];
        [self.previewImage setImage:nil];
        [self addSubview:self.previewImage];
    }
    [self hideLoadingError];

    if (self.filename) {
        [[TDAPIClient sharedInstance] setImage:@{ @"imageView":self.previewImage, @"filename":[self.filename stringByAppendingString:FTImage] }];
    }
}

- (void)removePreview {
    if (self.previewImage) {
        [self.previewImage removeFromSuperview];
        self.previewImage = nil;
    }
}

- (void)setupVideo {
    if (!self.controlView) {
        self.videoHolderView = [[UIView alloc] initWithFrame:CGRectMake(0, [self getMediaOffset], kHeightOfMedia, kWidthOfMedia)];
        self.controlView = [[UIImageView alloc] initWithFrame:CGRectMake(0, [self getMediaOffset], kHeightOfMedia, kWidthOfMedia)];
        self.controlView.contentMode = UIViewContentModeCenter;
        self.controlView.userInteractionEnabled = YES;
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
        [self.controlView addGestureRecognizer:self.tapGestureRecognizer];
        [self addSubview:self.controlView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseTapGesture:) name:TDNotificationPauseTapGesture object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeTapGesture:) name:TDNotificationResumeTapGesture object:nil];
    }
}

- (void)removeVideo {
    if (self.player != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:TDNotificationPauseTapGesture object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:TDNotificationResumeTapGesture object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:TDNotificationStopPlayers object:self];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:self.playerItem];

        [self.playerItem removeObserver:self forKeyPath:@"status" context:nil];
        [self.playerLayer removeFromSuperlayer];
        [self.videoHolderView removeFromSuperview];
        [self.controlView removeFromSuperview];
        self.player = nil;
        self.playerItem = nil;
        self.playerLayer = nil;
        self.videoHolderView = nil;
        self.controlView = nil;
    }
}

#pragma mark - UI callbacks

- (void)pauseTapGesture:(NSNotification *)n {
    [self.controlView removeGestureRecognizer:self.tapGestureRecognizer];
}

- (void)resumeTapGesture:(NSNotification *)n {
    [self.controlView addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)handleTapFrom:(UITapGestureRecognizer *)tap {
    if (self.post.kind == TDPostKindVideo) {

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

#pragma mark - video handling

- (void)updateControlImage:(ControlState)controlState {
    if (!self.playerSpinner) {
        self.playerSpinner = [[UIImageView alloc] initWithFrame:CGRectMake(290.0, [self getMediaOffset] + kHeightOfMedia - 30, 20.0, 20.0)];
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

    self.state = PlayerStateLoading;
    [self hideLoadingError];

    NSURL *location = [TDConstants getStreamingUrlFor:self.filename];
    debug NSLog(@"Loading movie from: %@", location);

    self.playerLayer = [AVPlayerLayer layer];
    [self.playerLayer setFrame:CGRectMake(0, 0, kHeightOfMedia, kWidthOfMedia)];
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
    if (self.controlView) {
        self.controlView.backgroundColor = [UIColor clearColor];
        [self.controlView setImage:nil];
    }
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

- (void)usernamePressed:(UITapGestureRecognizer *)g {
    if (self.delegate && [self.delegate respondsToSelector:@selector(userButtonPressedFromRow:)]) {
        [self.delegate userButtonPressedFromRow:self.row];
    }
}

+ (CGFloat)heightForPost:(TDPost *)post {
    CGFloat commentHeight = [TDViewControllerHelper heightForComment:post.comment withMentions:post.mentions];
    commentHeight = commentHeight == 0 ? 0 : commentHeight + kCommentBottomPadding;
    switch (post.kind) {
        case TDPostKindPhoto:
        case TDPostKindVideo:
            return kHeightOfProfileRow + kHeightOfMedia + commentHeight;
            break;
            
        case TDPostKindText:
            return kHeightOfProfileRow + commentHeight;
            break;

        case TDPostKindUnknown:
            return kHeightOfProfileRow;
            break;
    }
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if (self.delegate && [self.delegate respondsToSelector:@selector(userProfilePressedWithId:)]) {
        [self.delegate userProfilePressedWithId:[NSNumber numberWithInteger:[[url path] integerValue]]];
    }
}


@end
