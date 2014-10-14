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
#import "ObservingPlayerItem.h"
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

static CGFloat const kMargin = 10;
static CGFloat const kMarginBottomOfMedia = 13;
static CGFloat const kHeightOfProfileRow = 65.;
static CGFloat const kCommentBottomPadding = 15.;
static CGFloat const kWidthOfMedia = 320.;
static NSString *const kTracksKey = @"tracks";

@interface TDPostView () <TTTAttributedLabelDelegate, ObservingPlayerItemDelegate>

@property (nonatomic) UIView *videoHolderView;
@property (nonatomic) TTTAttributedLabel *commentLabel;
@property (nonatomic) UIView *commentBottomLine;
@property (nonatomic) UIImageView *controlView;
@property (nonatomic) UIImageView *prStar;
@property (nonatomic) UIImageView *privatePost;
@property (nonatomic) UIImageView *controlImage;
@property (nonatomic) UIImageView *playerSpinner;
@property (nonatomic) AVURLAsset *videoAsset;
@property (nonatomic) AVPlayer *player;
@property (nonatomic) ObservingPlayerItem *playerItem;
@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) TDPost *post;
@property (nonatomic) PlayerState state;
@property (nonatomic) NSTimer *loadingTimeout;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic) CGFloat mediaSize;

@end


@implementation TDPostView

- (void)dealloc {
    [self removeVideo];
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

- (void)removeFromSuperview {
    // remove any observers if this view is killed
    [self removeVideo];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super removeFromSuperview];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.userInteractionEnabled = YES;

        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        self.mediaSize = (width / kWidthOfMedia) * kWidthOfMedia;

        // add pr star at lowest level
        self.prStar = [[UIImageView alloc] initWithFrame:CGRectMake(width - 65, kMargin + 6, 32, 32)];
        self.prStar.image = [UIImage imageNamed:@"trophy_64x64"];
        self.prStar.hidden = YES;
        [self addSubview:self.prStar];

        self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(65, kMargin, width - 85, 45)];
        self.usernameLabel.font = [TDConstants fontSemiBoldSized:16.0];
        self.usernameLabel.textColor = [TDConstants brandingRedColor];
        self.usernameLabel.numberOfLines = 1;
        self.usernameLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *usernameTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(usernamePressed:)];
        [self.usernameLabel addGestureRecognizer:usernameTap];
        [self addSubview:self.usernameLabel];

        self.commentLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(kMargin, kHeightOfProfileRow, width - (kMargin * 2), 0)];
        self.commentLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
        self.commentLabel.textColor = [TDConstants commentTextColor];
        self.commentLabel.font = [TDConstants fontRegularSized:16];
        self.commentLabel.delegate = self;
        self.commentLabel.hidden = YES;
        self.commentLabel.numberOfLines = 0;
        self.commentLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
        [self addSubview:self.commentLabel];

        self.commentBottomLine = [[UIView alloc] initWithFrame:CGRectMake(kMargin, kHeightOfProfileRow, width - (kMargin * 2), 1 / [[UIScreen mainScreen] scale])];
        self.commentBottomLine.backgroundColor = [TDConstants lightBorderColor];
        self.commentBottomLine.hidden = YES;
        [self addSubview:self.commentBottomLine];

        self.createdLabel = [[TDUpdatingDateLabel alloc] initWithFrame:CGRectMake(width - 60, kMargin, 53, 45)];
        self.createdLabel.textColor = [TDConstants commentTimeTextColor];
        self.createdLabel.font = [TDConstants fontLightSized:14.0];
        self.createdLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:self.createdLabel];

        self.userProfileImage = [[UIImageView alloc] initWithFrame:CGRectMake(kMargin, kMargin, 45, 45)];
        self.userProfileImage.image = [UIImage imageNamed:@"prof_pic_default"];
        self.userProfileImage.backgroundColor = [TDConstants darkBackgroundColor];
        self.userProfileImage.layer.cornerRadius = self.userProfileImage.layer.frame.size.width / 2;
        self.userProfileImage.clipsToBounds = YES;
        self.userProfileImage.userInteractionEnabled = YES;
        UITapGestureRecognizer *userProfileTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(usernamePressed:)];
        [self.userProfileImage addGestureRecognizer:userProfileTap];
        [self addSubview:self.userProfileImage];

        self.privatePost = [[UIImageView alloc] initWithFrame:CGRectMake(kMargin - 1.5, kMargin + 25.5, 21, 21)]; // the image has a white border (thus the weird half pixels)
        self.privatePost.image = [UIImage imageNamed:@"icon-lock"];
        self.privatePost.hidden = YES;
        [self addSubview:self.privatePost];

        UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 1 / [[UIScreen mainScreen] scale])];
        topLine.backgroundColor = [TDConstants darkBorderColor];
        [self addSubview:topLine];
    }
    return self;
}

- (void)setPost:(TDPost *)post {
    if (post == nil) {
        return;
    }

    // Only update if this isn't the same post or username or picture has changed
    if ([self.post.postId isEqual:post.postId] && [self.usernameLabel.text isEqualToString:post.user.username] && [self.userPicture isEqualToString:post.user.picture]) {
        return;
    }
    // If it's the same (eg table was refreshed), bail so that we don't stop video playback
    if ([self.post.postId isEqual:post.postId] && self.state == PlayerStatePlaying ) {
        return;
    }

    // We re-add the video every time it's needed
    [self removeVideo];

    _post = post;
    self.userPicture = post.user.picture;
    self.state = PlayerStateNotLoaded;

    CGFloat width = [UIScreen mainScreen].bounds.size.width;

    // Set username label and size (for tap area)
    self.usernameLabel.text = post.user.username;
    CGSize size = [self.usernameLabel sizeThatFits:CGSizeMake(width - 85, 45)];
    CGRect frame = self.usernameLabel.frame;
    frame.size.width = size.width;
    self.usernameLabel.frame = frame;

    self.prStar.hidden = !post.personalRecord;
    self.privatePost.hidden = !post.isPrivate;

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

    if (post.comment) {
        [self.commentLabel setText:post.comment afterInheritingLabelAttributesAndConfiguringWithBlock:nil];
        [TDViewControllerHelper linkUsernamesInLabel:self.commentLabel users:post.mentions];
        self.commentLabel.attributedText = [TDViewControllerHelper makeParagraphedTextWithAttributedString:self.commentLabel.attributedText];

        CGFloat commentHeight = [TDViewControllerHelper heightForText:post.comment withMentions:post.mentions withFont:[TDConstants fontRegularSized:16] inWidth:width - (kMargin * 2)];
        commentHeight = commentHeight == 0 ? 0 : commentHeight + kCommentBottomPadding;
        CGRect commentFrame = self.commentLabel.frame;
        commentFrame.origin.y = kHeightOfProfileRow + (self.post.kind == TDPostKindText ? 0 : self.mediaSize + kMarginBottomOfMedia);;
        commentFrame.size.height = commentHeight;
        self.commentLabel.frame = commentFrame;
        self.commentLabel.hidden = NO;

        CGRect lineFrame = self.commentBottomLine.frame;
        lineFrame.origin.y = commentFrame.origin.y + commentHeight +  (1 / [[UIScreen mainScreen] scale]);
        self.commentBottomLine.frame = lineFrame;
        self.commentBottomLine.hidden = NO;
    } else {
        self.commentLabel.hidden = YES;
        self.commentBottomLine.hidden = YES;
    }

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

- (void)setupPreview {
    if (!self.previewImage) {
        self.previewImage = [[UIImageView alloc] init];
        self.previewImage.backgroundColor = [TDConstants darkBackgroundColor];
        [self.previewImage setUserInteractionEnabled:YES];
        [self addSubview:self.previewImage];
    }
    self.previewImage.image = nil;
    self.previewImage.frame = CGRectMake(0, kHeightOfProfileRow, self.mediaSize, self.mediaSize);
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
        self.playerSpinner = [[UIImageView alloc] init];
        self.videoHolderView = [[UIView alloc] initWithFrame:CGRectMake(0, kHeightOfProfileRow, self.mediaSize, self.mediaSize)];
        self.controlView = [[UIImageView alloc] initWithFrame:CGRectMake(0, kHeightOfProfileRow, self.mediaSize, self.mediaSize)];
        self.controlView.contentMode = UIViewContentModeCenter;
        self.controlView.userInteractionEnabled = YES;
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
        [self.controlView addGestureRecognizer:self.tapGestureRecognizer];
        [self addSubview:self.videoHolderView];
        [self addSubview:self.playerSpinner];
        [self addSubview:self.controlView];
        [self insertSubview:self.videoHolderView aboveSubview:self.previewImage];
        [self insertSubview:self.playerSpinner aboveSubview:self.videoHolderView];
        [self insertSubview:self.controlView aboveSubview:self.playerSpinner];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseTapGesture:) name:TDNotificationPauseTapGesture object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeTapGesture:) name:TDNotificationResumeTapGesture object:nil];
    }
}

- (void)removeVideo {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TDNotificationPauseTapGesture object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TDNotificationResumeTapGesture object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TDNotificationStopPlayers object:self];

    self.playerItem = nil;
    if (self.videoHolderView) {
        [self.playerLayer removeFromSuperlayer];
        [self.videoHolderView removeFromSuperview];
        [self.controlView removeFromSuperview];
        [self.playerSpinner removeFromSuperview];
        self.player = nil;
        self.playerLayer = nil;
        self.videoHolderView = nil;
        self.controlView = nil;
        self.playerSpinner = nil;
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
        return;
    }

    [self stopSpinner];
    debug NSLog(@"update control state to: %d", controlState);

    if (controlState != ControlStatePlay) {
        self.playerSpinner.frame = CGRectMake(self.mediaSize - 30, kHeightOfProfileRow + self.mediaSize - 30, 20.0, 20.0);
    }

    switch (controlState) {
        case ControlStatePlay:
            // 35 == half of 70 on play button
            self.playerSpinner.frame = CGRectMake((self.mediaSize / 2) - 35, kHeightOfProfileRow + (self.mediaSize / 2) - 35, 70, 70);
            [self.playerSpinner setImage:[UIImage imageNamed:@"play_button_140x140"]];
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

    NSURL *videoLocation = [TDConstants getStreamingUrlFor:self.filename];
    [self updateControlImage:ControlStateLoading];
    [self startLoadingTimeout];

    self.videoAsset = [[AVURLAsset alloc] initWithURL:videoLocation options:nil];
    [self.videoAsset loadValuesAsynchronouslyForKeys:@[kTracksKey] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error;
            AVKeyValueStatus status = [self.videoAsset statusOfValueForKey:kTracksKey error:&error];

            if (status == AVKeyValueStatusLoaded) {
                self.playerItem = [[ObservingPlayerItem alloc] initWithAsset:self.videoAsset];
                self.playerItem.delegate = self;

                self.playerLayer = [AVPlayerLayer layer];
                [self.playerLayer setFrame:CGRectMake(0, 0, self.mediaSize, self.mediaSize)];
                [self.playerLayer setBackgroundColor:[UIColor clearColor].CGColor];
                [self.playerLayer setVideoGravity:AVLayerVideoGravityResize];
                [self.videoHolderView.layer addSublayer:self.playerLayer];

                self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
                [self.player setActionAtItemEnd:AVPlayerActionAtItemEndPause];
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

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if ([TDViewControllerHelper isThrowdownURL:url] && self.delegate && [self.delegate respondsToSelector:@selector(userProfilePressedWithId:)]) {
        [self.delegate userProfilePressedWithId:[NSNumber numberWithInteger:[[[url path] lastPathComponent] integerValue]]];
    } else {
        [TDViewControllerHelper askUserToOpenInSafari:url];
    }
}

#pragma mark - table cell height calculation

+ (CGFloat)heightForPost:(TDPost *)post {
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat commentHeight = [TDViewControllerHelper heightForText:post.comment withMentions:post.mentions withFont:[TDConstants fontRegularSized:16] inWidth:width - (kMargin * 2)];
    commentHeight = commentHeight == 0 ? 0 : commentHeight + kCommentBottomPadding;
    CGFloat mediaSize = (width / kWidthOfMedia) * kWidthOfMedia;

    switch (post.kind) {
        case TDPostKindPhoto:
        case TDPostKindVideo:
            return kHeightOfProfileRow + mediaSize + commentHeight + (commentHeight > 0 ? kMarginBottomOfMedia : 0);
            break;

        case TDPostKindText:
            return kHeightOfProfileRow + commentHeight;
            break;

        case TDPostKindUnknown:
            return kHeightOfProfileRow;
            break;
    }
}


#pragma mark - ObservingPlayerItemDelegate

- (void)playerItemReadyToPlay {
    // Only play once it's been loaded
    // ready to play is called every time the player is reset
    if (self.state == PlayerStateLoading) {
        [self updateControlImage:ControlStateNone];
        [self playVideo];
    }
}

- (void)playerItemPlayFailed {
    debug NSLog(@"PLAYBACK: failed!");
    self.state = PlayerStateNotLoaded;
    [self showLoadingError];
}

- (void)playerItemRemovedObservation {
    [self stopVideo];
}

- (void)playerItemStalled {
    debug NSLog(@"PLAYBACK: stalled");
    self.state = PlayerStateNotLoaded;
    [self showLoadingError];
}

- (void)playerItemReachedEnd {
    debug NSLog(@"PLAYBACK: reached end");
    self.state = PlayerStateReachedEnd;
    [self updateControlImage:ControlStatePlay];
    [self hideLoadingError];
}


@end
