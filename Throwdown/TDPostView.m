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
#import <SDWebImage/SDWebImageManager.h>
#import "UIImage+Resizing.h"
#import "ScrollWheel.h"

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
static CGFloat const kTextRightMargin = 85.;
static CGFloat const kUsernameMargin = 3;
static CGFloat const kUsernameNormalHeight = 62.0;
static CGFloat const kUsernameLocationHeight = 31.5;
static CGFloat const kUsernameLabelOffset = 65.;
static CGFloat const kCommentBottomPadding = 15.;
static CGFloat const kWidthOfMedia = 320.;
static NSString *const kTracksKey = @"tracks";

@interface TDPostView () <TTTAttributedLabelDelegate, ObservingPlayerItemDelegate, ScrollWheelDelegate>

@property (nonatomic) UIView *videoHolderView;
@property (nonatomic) TTTAttributedLabel *commentLabel;
@property (nonatomic) UIView *commentBottomLine;
@property (nonatomic) UIImageView *controlView;
@property (nonatomic) UIImageView *prStar;
@property (nonatomic) UIImageView *privatePost;
@property (nonatomic) UIImageView *semiPrivatePost;
@property (nonatomic) UIImageView *controlImage;
@property (nonatomic) UIImageView *playerSpinner;
@property (nonatomic) UIImageView *locationPinImage;
@property (nonatomic) UIView *topLine;
@property (nonatomic) TTTAttributedLabel *locationLabel;
@property (nonatomic) AVURLAsset *videoAsset;
@property (nonatomic) AVPlayer *player;
@property (nonatomic) ObservingPlayerItem *playerItem;
@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) TDPost *post;
@property (nonatomic) PlayerState state;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic) CGFloat mediaSize;
@property (nonatomic) UIView *progressBackgroundView;
@property (nonatomic) UIView *progressBarView;
@property (nonatomic) ScrollWheel *scrollWheel;
@property (nonatomic) UIView *timeProgressBar;
@property (nonatomic) UILabel *timeLabel;
@property (nonatomic) float totalSeconds;
@property (nonatomic) float pausedSeconds;
@property (nonatomic) BOOL previewLoadError;
@property (nonatomic) float lastPosition;

// Used for caching and checking if the row has been updated
@property (nonatomic) NSURL *downloadURL;
@property (nonatomic) NSURL *userURL;

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

        self.topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 1 / [[UIScreen mainScreen] scale])];
        self.topLine.backgroundColor = [TDConstants darkBorderColor];
        [self addSubview:self.topLine];

        // add pr star at lowest level
        self.prStar = [[UIImageView alloc] initWithFrame:CGRectMake(width - kUsernameLabelOffset, kMargin + 6, 32, 32)];
        self.prStar.image = [UIImage imageNamed:@"trophy_64x64"];
        self.prStar.hidden = YES;
        [self addSubview:self.prStar];

        self.usernameLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(kUsernameLabelOffset, kUsernameMargin, width - kTextRightMargin, kUsernameNormalHeight)];
        self.usernameLabel.userInteractionEnabled = YES;
        self.usernameLabel.font = [TDConstants fontSemiBoldSized:17.0];
        self.usernameLabel.textColor = [TDConstants brandingRedColor];
        self.usernameLabel.text = @"";
        [self.usernameLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(usernamePressed:)]];
        [self addSubview:self.usernameLabel];

        self.locationPinImage = [[UIImageView alloc] initWithFrame:CGRectMake(kUsernameLabelOffset, 1 + kUsernameMargin + kUsernameLocationHeight, 10, 14)];
        self.locationPinImage.hidden = YES;
        self.locationPinImage.userInteractionEnabled = YES;
        [self.locationPinImage addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(locationButtonPressed)]];
        [self.locationPinImage setImage:[UIImage imageNamed:@"icon_pindrop_off"]];
        [self addSubview:self.locationPinImage];

        CGFloat locationLeftOffset = self.locationPinImage.frame.origin.x + self.locationPinImage.frame.size.width + 4;

        self.locationLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(locationLeftOffset, kUsernameMargin + kUsernameLocationHeight, width - kTextRightMargin - locationLeftOffset, kUsernameLocationHeight)];
        self.locationLabel.textInsets = UIEdgeInsetsMake(2, 0, 0, 0); // centers the text with the pin-image
        self.locationLabel.font = [TDConstants fontRegularSized:14];
        self.locationLabel.textColor =[TDConstants commentTimeTextColor];
        self.locationLabel.hidden = YES;
        self.locationLabel.userInteractionEnabled = YES;
        self.locationLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
        [self.locationLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(locationButtonPressed)]];
        [self addSubview:self.locationLabel];

        self.commentLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(kMargin, kHeightOfProfileRow, width - (kMargin * 2), 0)];
        self.commentLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
        self.commentLabel.textColor = [TDConstants commentTextColor];
        self.commentLabel.font = POST_COMMENT_FONT;
        self.commentLabel.delegate = self;
        self.commentLabel.hidden = YES;
        self.commentLabel.numberOfLines = 0;
        self.commentLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
        [self addSubview:self.commentLabel];

        self.commentBottomLine = [[UIView alloc] initWithFrame:CGRectMake(kMargin, kHeightOfProfileRow, width - (kMargin * 2), 1 / [[UIScreen mainScreen] scale])];
        self.commentBottomLine.backgroundColor = [TDConstants darkBorderColor];
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

        self.semiPrivatePost = [[UIImageView alloc] initWithFrame:CGRectMake(kMargin - 1.5, kMargin + 25.5, 21, 21)]; // the image has a white border (thus the weird half pixels)
        self.semiPrivatePost.image = [UIImage imageNamed:@"icon_semi_private_feed"];
        self.semiPrivatePost.hidden = YES;
        [self addSubview:self.semiPrivatePost];


    }
    return self;
}

- (void)setPost:(TDPost *)post showDate:(BOOL)showDate {
    if (post == nil) {
        return;
    }

    // Only update if this isn't the same post or username or picture has changed
    if ([self.post.postId isEqual:post.postId] && [self.usernameLabel.text isEqualToString:post.user.username] && [self.userPicture isEqualToString:post.user.picture]
        && [self.post.comment isEqualToString:post.comment]) {
        return;
    }

    // If it's the same post bail so that we don't stop video playback (eg table was refreshed)
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

    // TODO : test overlap with PR button
    if (self.post.locationId) {
        self.usernameLabel.textInsets = UIEdgeInsetsMake(0, 0, 1, 0);
        self.usernameLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentBottom;
        CGSize size = [self.usernameLabel sizeThatFits:CGSizeMake(width - kTextRightMargin, kUsernameLocationHeight)];
        CGRect frame = self.usernameLabel.frame;
        frame.size.width = size.width;
        frame.size.height = kUsernameLocationHeight;
        self.usernameLabel.frame = frame;

        self.locationLabel.text = post.locationName;
        CGFloat locationMaxWidth = width - (post.personalRecord ? kTextRightMargin : kTextRightMargin - [UIImage imageNamed:@"trophy_64x64"].size.width) - self.locationPinImage.frame.origin.x + self.locationPinImage.frame.size.width + 6;

        size = [self.locationLabel sizeThatFits:CGSizeMake(locationMaxWidth, kUsernameLocationHeight)];
        frame = self.locationLabel.frame;
        frame.size.width = locationMaxWidth < size.width ? locationMaxWidth : size.width;
        frame.size.height = kUsernameLocationHeight;
        self.locationLabel.frame = frame;
        self.locationLabel.hidden = NO;
        self.locationPinImage.hidden = NO;
        self.locationLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    } else {

        self.usernameLabel.textInsets = UIEdgeInsetsZero;
        self.usernameLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentCenter;
        CGSize size = [self.usernameLabel sizeThatFits:CGSizeMake(width - kTextRightMargin, kUsernameNormalHeight)];
        CGRect frame = self.usernameLabel.frame;
        frame.size.width = size.width;
        frame.size.height = kUsernameNormalHeight;
        self.usernameLabel.frame = frame;

        self.locationPinImage.hidden = YES;
        self.locationLabel.hidden = YES;
    }
    self.usernameLabel.text = post.user.username;

    self.prStar.hidden = !post.personalRecord;
    self.privatePost.hidden = (post.visibility == TDPostPrivacyPrivate) ? NO : YES;
    self.semiPrivatePost.hidden = (post.visibility == TDPostSemiPrivate) ? NO : YES;

    // Set first to not show the wrong image while loading or if load fails
    [self.userProfileImage setImage:[UIImage imageNamed:@"prof_pic_default"]];
    if (post.user && ![post.user hasDefaultPicture]) {
        [self downloadUserImage:post.user.picture];
    }

    if (showDate) {
        self.createdLabel.labelDate = post.createdAt;
        self.createdLabel.text = [post.createdAt timeAgo];
        self.createdLabel.hidden = NO;
    } else {
        self.createdLabel.hidden = YES;
    }

    if (post.comment) {
        NSString *editedComment;

        if (post.updated) {
            NSString *editedString = @" (edited)";
            editedComment = [NSString stringWithFormat:@"%@%@", post.comment, editedString];
            [self.commentLabel setText:editedComment afterInheritingLabelAttributesAndConfiguringWithBlock:^(NSMutableAttributedString *mutableAttributedString) {
                NSRange range = [editedComment rangeOfString:editedString];
                if (range.location != NSNotFound) {
                    // Core Text APIs use C functions without a direct bridge to UIFont. See Apple's "Core Text Programming Guide" to learn how to configure string attributes.
                    [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[TDConstants commentTimeTextColor] range:range];
                }

                return mutableAttributedString;
            }];
        } else {
            [self.commentLabel setText:post.comment afterInheritingLabelAttributesAndConfiguringWithBlock:nil];
         }

        [TDViewControllerHelper linkUsernamesInLabel:self.commentLabel users:post.mentions withHashtags:YES];
        self.commentLabel.attributedText = [TDViewControllerHelper makeParagraphedTextWithAttributedString:self.commentLabel.attributedText];

        CGFloat commentHeight = [TDViewControllerHelper heightForText:self.commentLabel.attributedText.string withMentions:post.mentions withFont:POST_COMMENT_FONT inWidth:width - (kMargin * 2)];
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
        case TDPostKindVideo:
            self.filename = post.filename;
            [self setupPreview];
            break;

        case TDPostKindText:
            [self removePreview];
            break;

        default:
            break;
    }
}

#pragma mark - download images

- (void)downloadUserImage:(NSString *)filename {
    self.userURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", RSHost, filename]];

    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:self.userURL options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        // no progress indicator here
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *finalURL) {
        // avoid doing anything on a row that's been reused b/c the download took too long and user scrolled away
        if (![finalURL isEqual:self.userURL] || !self.userProfileImage) {
            return;
        }
        if (!error && image) {
            CGFloat width = self.userProfileImage.frame.size.width * [UIScreen mainScreen].scale;
            image = [image scaleToSize:CGSizeMake(width, width)];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.userProfileImage.image = image;
            });
        }
    }];
}

- (void)downloadPreview {
    self.previewLoadError = NO;
    [self setupProgressBar];

    self.downloadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@", RSHost, self.filename, FTImage]];
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:self.downloadURL options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        [self updateProgressBar:(float)receivedSize expected:(float)expectedSize];
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *finalURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // avoid doing anything on a row that's been reused b/c the download took too long and user scrolled away
            // self.imageURL will have changed and previewImage will be remove if it's a text post
            // we have to do this on the main thread for thread safety
            if (![finalURL isEqual:self.downloadURL] || !self.previewImage) {
                return;
            }
            if (error || !image) {
                self.previewLoadError = YES;
                [self removeProgressBar];
                [self setupTapControl];
                [self showLoadingError];
            } else if (image) {
                [self removeProgressBar];
                self.previewImage.image = image;
                if (self.post.kind == TDPostKindVideo) {
                    [self setupVideo];
                    [self updateControlImage:ControlStatePlay];
                }
            }
        });
    }];
}

#pragma mark - setup subviews

- (void)setupPreview {
    [self removeTapControl]; // removes any old failed image downloads
    [self removeProgressBar]; // if cell is reused while download is in progress

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
        [self downloadPreview];
    }
}

- (void)removePreview {
    if (self.previewImage) {
        [self.previewImage removeFromSuperview];
        self.previewImage = nil;
    }

    // if it's still downloading
    [self removeProgressBar];
    // if the preview image failed to download
    [self removeTapControl];
}

- (void)setupProgressBar {
    [self removeProgressBar]; // never want more than one!
    CGFloat y = kHeightOfProfileRow + (self.mediaSize / 2) - 5;
    CGFloat x = (SCREEN_WIDTH - 200) / 2;
    self.progressBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(x, y, 200, 10)];
    self.progressBackgroundView.backgroundColor = [TDConstants lightBorderColor];
    self.progressBackgroundView.layer.cornerRadius = 5;
    self.progressBackgroundView.layer.masksToBounds = YES;
    [self addSubview:self.progressBackgroundView];

    self.progressBarView = [[UIView alloc] initWithFrame:CGRectMake(x, y, 0, 10)];
    self.progressBarView.backgroundColor = [UIColor whiteColor];
    self.progressBarView.layer.cornerRadius = 5;
    self.progressBarView.layer.masksToBounds = YES;
    [self addSubview:self.progressBarView];
}

- (void)updateProgressBar:(float)receivedSize expected:(float)expectedSize {
    CGFloat width = 200.0 * (receivedSize / expectedSize);
    // Progress can be NaN! eg on Verizon.
    if (!isnan(width) && width > 10 && width <= 200 && self.progressBarView != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // progress bar could have been removed
            // we have to do this on the main thread for thread safety
            if (self.progressBarView && width > 10) {
                CGRect frame = self.progressBarView.frame;
                frame.size.width = width;
                self.progressBarView.frame = frame;
            }
        });
    }
}

- (void)removeProgressBar {
    if (self.progressBarView) {
        [self.progressBarView removeFromSuperview];
        [self.progressBackgroundView removeFromSuperview];
        self.progressBarView = nil;
        self.progressBackgroundView = nil;
    }
}

- (void)setupVideo {
    self.playerSpinner = [[UIImageView alloc] initWithFrame:CGRectMake((self.mediaSize / 2) - 35, kHeightOfProfileRow + (self.mediaSize / 2) - 35, 70, 70)];
    [self addSubview:self.playerSpinner];
    self.videoHolderView = [[UIView alloc] initWithFrame:CGRectMake(0, kHeightOfProfileRow, self.mediaSize, self.mediaSize)];
    [self addSubview:self.videoHolderView];
    [self insertSubview:self.videoHolderView aboveSubview:self.previewImage];
    [self insertSubview:self.playerSpinner aboveSubview:self.videoHolderView];
    [self setupTapControl];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseTapGesture:) name:TDNotificationPauseTapGesture object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeTapGesture:) name:TDNotificationResumeTapGesture object:nil];
}

- (void)removeVideo {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TDNotificationPauseTapGesture object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TDNotificationResumeTapGesture object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TDNotificationStopPlayers object:self];

    [self.playerItem removeObservers];
    self.playerItem = nil;
    [self.playerLayer removeFromSuperlayer];
    [self.videoHolderView removeFromSuperview];
    [self.playerSpinner removeFromSuperview];
    self.player = nil;
    self.playerLayer = nil;
    self.videoHolderView = nil;
    self.playerSpinner = nil;

    [self.timeProgressBar removeFromSuperview];
    self.timeProgressBar = nil;
    [self.scrollWheel removeFromSuperview];
    self.scrollWheel = nil;
    [self.timeLabel removeFromSuperview];
    self.timeLabel = nil;

    [self setNeedsDisplay];
}

// used for video and for retrying preview download if it fails
- (void)setupTapControl {
    [self removeTapControl]; // no duplicates please
    self.controlView = [[UIImageView alloc] initWithFrame:CGRectMake(0, kHeightOfProfileRow, self.mediaSize, self.mediaSize)];
    self.controlView.contentMode = UIViewContentModeCenter;
    self.controlView.userInteractionEnabled = YES;
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    [self.controlView addGestureRecognizer:self.tapGestureRecognizer];
    [self addSubview:self.controlView];
    if (self.playerSpinner) {
        [self insertSubview:self.controlView aboveSubview:self.playerSpinner];
    }
}

- (void)removeTapControl {
    if (self.controlView) {
        if (self.tapGestureRecognizer) {
            [self.controlView removeGestureRecognizer:self.tapGestureRecognizer];
            self.tapGestureRecognizer = nil;
        }
        [self.controlView removeFromSuperview];
        self.controlView = nil;
    }
}

- (void)setupScrollWheel {
    int height = 0;
    switch ((int)[UIScreen mainScreen].bounds.size.width) {
        case 320:
            height = 44;
            break;
        case 375:
            height = 50;
            break;
        case 414:
            height = 58;
            break;
    }
    int labelHeight = 20;

    if (!self.scrollWheel) {
        // must init with height, used to draw heigth of ticks
        self.scrollWheel = [[ScrollWheel alloc] initWithFrame:CGRectMake(0, kHeightOfProfileRow + self.mediaSize, [UIScreen mainScreen].bounds.size.width, height)];
        self.scrollWheel.delegate = self;
        self.scrollWheel.minPosition = 0;
        self.scrollWheel.maxPosition = self.totalSeconds;
        self.scrollWheel.modifier = 0.003;
        self.scrollWheel.clipsToBounds = YES;
        [self addSubview:self.scrollWheel];
        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, kHeightOfProfileRow + self.mediaSize - labelHeight - 6, 60, 20)];
        self.timeLabel.alpha = 0;
        self.timeLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
        self.timeLabel.font = [TDConstants fontRegularSized:13];
        self.timeLabel.textColor = [UIColor whiteColor];
        self.timeLabel.layer.cornerRadius = 4;
        self.timeLabel.clipsToBounds = YES;
        self.timeLabel.textAlignment = NSTextAlignmentCenter;
        self.timeLabel.userInteractionEnabled = YES;
        [self addSubview:self.timeLabel];
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panTimeLabel:)];
        [self.timeLabel addGestureRecognizer:panRecognizer];
    }
    [self.scrollWheel setPosition:self.pausedSeconds];
    [self updateTimeProgreesBarTo:self.pausedSeconds];

    CGRect timeFrame = self.timeProgressBar.frame;
    timeFrame.origin.y = kHeightOfProfileRow + self.mediaSize - height - 3;

    CGRect scrollFrame = self.scrollWheel.frame;
    scrollFrame.size.height = 0;
    self.scrollWheel.frame = scrollFrame;

    scrollFrame.origin.y = kHeightOfProfileRow + self.mediaSize - height;
    scrollFrame.size.height = height;

    CGRect timeLabelFrame = self.timeLabel.frame;
    timeLabelFrame.origin.y = kHeightOfProfileRow + self.mediaSize - height - labelHeight - 6;

    self.scrollWheel.hidden = NO;
    self.timeLabel.hidden = NO;
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.scrollWheel.frame = scrollFrame;
        self.timeLabel.alpha = 1.0;
        self.timeLabel.frame = timeLabelFrame;
        self.timeProgressBar.frame = timeFrame;
    } completion:nil];
}

- (void)updateTimeProgreesBarTo:(float)time {

    self.totalSeconds = CMTimeGetSeconds([self.playerItem duration]);

    if (isnan(self.totalSeconds)) {
        return;
    }
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGRect frame = self.timeProgressBar.frame;
    frame.size.width = width * (time / self.totalSeconds);
    self.timeProgressBar.frame = frame;

    if (self.timeLabel) {
        CGRect timeFrame = self.timeLabel.frame;
        int x = frame.size.width - timeFrame.size.width / 2;
        if (x < 3) {
            x = 3;
        } else if (x > width - timeFrame.size.width) {
            x = width - timeFrame.size.width - 3;
        }
        timeFrame.origin.x = x;
        self.timeLabel.frame = timeFrame;

        // time is in seconds
        float seconds = floorf(fmodf(time, 60));
        float minutes = floorf(fmodf(time / 60, 60));
        float hundred = floorf(fmodf(time * 100.0, 100));
        NSString *format = [NSString stringWithFormat:@"%%0%dd:%%0%dd:%%0%dd", 2, 2, 2];
        self.timeLabel.text = [NSString stringWithFormat:format, (int)minutes, (int)seconds, (int)hundred];
    }
}

#pragma mark - UI callbacks

- (void)panTimeLabel:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self scrollWheelStartedInteraction];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint location = [gesture locationInView:self];
        CGFloat width = [UIScreen mainScreen].bounds.size.width;

        float seconds = (location.x / width) * self.totalSeconds;
        [self.scrollWheel setPosition:seconds];
        [self updateTimeProgreesBarTo:seconds];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self.playerItem seekToTime:CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        });
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        [self scrollWheelEndedInteraction];
    }
}

- (void)pauseTapGesture:(NSNotification *)n {
    [self.controlView removeGestureRecognizer:self.tapGestureRecognizer];
}

- (void)resumeTapGesture:(NSNotification *)n {
    [self.controlView addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)handleTapFrom:(UITapGestureRecognizer *)tap {
    if (self.previewLoadError) {
        [self removeTapControl];
        [self downloadPreview];
    } else if (self.post.kind == TDPostKindVideo) {
        switch (self.state) {
            case PlayerStateNotLoaded:
                [self loadVideo];
                break;

            case PlayerStatePlaying:
                [self stopVideo];
                break;

            case PlayerStateReachedEnd:
                [self.player seekToTime:kCMTimeZero];
                [self playVideo];
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
    // returns here if this isn't a video (b/c this gets called when image load fails too)
    if (!self.playerSpinner) {
        return;
    }
    switch (controlState) {
        case ControlStatePlay:
            [self.playerSpinner setImage:[UIImage imageNamed:@"play_button_140x140"]];
            break;
        case ControlStatePaused:
        case ControlStateLoading:
        case ControlStateNone:
            [self.playerSpinner setImage:nil];
            break;
    }
}

- (void)stopVideo {
    if (self.state == PlayerStatePlaying) {
        self.state = PlayerStatePaused;
        [self.player pause];
        [self updateControlImage:ControlStatePaused];
        if (self.playerItem) {
            self.pausedSeconds = CMTimeGetSeconds([self.playerItem currentTime]);
            [self setupScrollWheel];
        }
    }
}

- (void)playVideo {
    CGRect timeFrame = self.timeProgressBar.frame;
    timeFrame.origin.y = kHeightOfProfileRow + self.mediaSize - 3;

    CGRect scrollFrame = self.scrollWheel.frame;
    scrollFrame.origin.y = kHeightOfProfileRow + self.mediaSize;
    scrollFrame.size.height = 0;

    CGRect timeLabelFrame = self.timeLabel.frame;
    timeLabelFrame.origin.y = kHeightOfProfileRow + self.mediaSize - 26;

    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.scrollWheel.frame = scrollFrame;
        self.timeLabel.alpha = 0.0;
        self.timeLabel.frame = timeLabelFrame;
        self.timeProgressBar.frame = timeFrame;
    } completion:^(BOOL finished) {
        if (finished) {
            self.scrollWheel.hidden = NO;
            self.timeLabel.hidden = NO;
        }
    }];

    self.state = PlayerStatePlaying;
    [self updateControlImage:ControlStateNone];
    [self.player play];
}

- (void)loadVideo {
    // Stop any previous players
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:self.filename];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopVideoFromNotification:) name:TDNotificationStopPlayers object:nil];

    self.state = PlayerStateLoading;
    [self hideLoadingError];

    [self updateControlImage:ControlStateLoading];

    if (![[TDAPIClient sharedInstance] videoExists:self.filename]) {
        [self updateControlImage:ControlStateNone];
        self.controlView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        [self setupProgressBar];
    }
    NSURL *finalURL = [NSURL URLWithString:self.filename];
    self.downloadURL = [finalURL copy];
    [[TDAPIClient sharedInstance] getVideo:self.filename callback:^(NSURL *videoLocation) {
        if (![finalURL isEqual:self.downloadURL] || !self.previewImage || self.state != PlayerStateLoading) {
            return;
        }
        self.controlView.backgroundColor = [UIColor clearColor];
        [self removeProgressBar];
        [self playVideoAt:videoLocation];
    } error:^{
        if (![finalURL isEqual:self.downloadURL] || !self.previewImage || self.state != PlayerStateLoading) {
            return;
        }
        self.state = PlayerStateNotLoaded;
        [self removeProgressBar];
        [self showLoadingError];
    } progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        [self updateProgressBar:(float)receivedSize expected:(float)expectedSize];
    }];
}

- (void)playVideoAt:(NSURL *)location {
    [self.playerItem removeObservers];
    self.playerItem = nil;
    self.player = nil;
    self.videoAsset = [[AVURLAsset alloc] initWithURL:location options:nil];
    [self.videoAsset loadValuesAsynchronouslyForKeys:@[kTracksKey] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error;
            AVKeyValueStatus status = [self.videoAsset statusOfValueForKey:kTracksKey error:&error];

            if (status == AVKeyValueStatusLoaded) {

                self.playerItem = [[ObservingPlayerItem alloc] initWithAsset:self.videoAsset];
                self.playerItem.delegate = self;

                self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
                [self.player setActionAtItemEnd:AVPlayerActionAtItemEndPause];

                self.playerLayer = [AVPlayerLayer layer];
                [self.playerLayer setFrame:CGRectMake(0, 0, self.mediaSize, self.mediaSize)];
                [self.playerLayer setBackgroundColor:[UIColor clearColor].CGColor];
                [self.playerLayer setVideoGravity:AVLayerVideoGravityResize];
                [self.playerLayer setPlayer:self.player];
                [self.videoHolderView.layer addSublayer:self.playerLayer];

                self.timeProgressBar = [[UIView alloc] initWithFrame:CGRectMake(0, kHeightOfProfileRow + self.mediaSize - 3, 0, 3)];
                self.timeProgressBar.backgroundColor = [UIColor colorWithRed:0 green:153.0/255.0 blue:224.0/255.0 alpha:1];
                [self addSubview:self.timeProgressBar];

                __weak typeof(self) _self = self;
                [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.05, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (_self != nil) {
                            [_self updateTimeProgreesBarTo:CMTimeGetSeconds(time)];
                        }
                    });
                }];

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
            [self stopVideo];
        }
    } else {
        debug NSLog(@"TDNotificationStopPlayers IGNORED");
    }
}

- (void)showLoadingError {
    [self updateControlImage:ControlStateNone];
    self.controlView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    [self.controlView setImage:[UIImage imageNamed:@"video_status_retry"]];
}

- (void)hideLoadingError {
    if (self.controlView) {
        self.controlView.backgroundColor = [UIColor clearColor];
        [self.controlView setImage:nil];
    }
}

#pragma mark - User Name Button

- (void)usernamePressed:(UITapGestureRecognizer *)g {
    if (self.delegate && [self.delegate respondsToSelector:@selector(userButtonPressedFromRow:)]) {
        [self.delegate userButtonPressedFromRow:self.row];
    }
}

#pragma mark - Location Button

- (void)locationButtonPressed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(locationButtonPressedFromRow:)]) {
        [self.delegate locationButtonPressedFromRow:self.row];
    }
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if ([TDViewControllerHelper isThrowdownURL:url] && self.delegate && [self.delegate respondsToSelector:@selector(userTappedURL:)]) {
        [self.delegate userTappedURL:url];
    } else {
        [TDViewControllerHelper askUserToOpenInSafari:url];
    }
}

#pragma mark - table cell height calculation

+ (CGFloat)heightForPost:(TDPost *)post {
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat commentHeight = [TDViewControllerHelper heightForText:post.comment withMentions:post.mentions withFont:POST_COMMENT_FONT inWidth:width - (kMargin * 2)];
    commentHeight = commentHeight == 0 ? 0 : commentHeight + kCommentBottomPadding +1.; // Add 1. for more padding to show commentBottomLine
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

#pragma mark - ScrollWheelDelegate

- (void)scrollWheelDidChange:(float)position {
    // If user hits play before the scroll finishes scrolling we ignore it
    if (self.state == PlayerStatePaused && self.lastPosition != position) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            if (position <= 0) {
                [self.playerItem seekToTime:kCMTimeZero];
            } else {
                CMTime time = CMTimeMakeWithSeconds(position, NSEC_PER_SEC);
                [self.playerItem seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
            }
        });
        [self updateTimeProgreesBarTo:position];
    }
    self.lastPosition = position;
}

- (void)scrollWheelStartedInteraction {
    // just send these up the chain for the tableview to disable scroll
    if (self.delegate && [self.delegate respondsToSelector:@selector(horizontalScrollingStarted)]) {
        [self.delegate horizontalScrollingStarted];
    }
}

- (void)scrollWheelEndedInteraction {
    // just send these up the chain for the tableview to enable scroll
    if (self.delegate && [self.delegate respondsToSelector:@selector(horizontalScrollingEnded)]) {
        [self.delegate horizontalScrollingEnded];
    }
}
@end
