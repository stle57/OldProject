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

static const NSString *ItemStatusContext;

@interface TDPostView ()

@property (weak, nonatomic) IBOutlet UIView *videoHolderView;
@property (weak, nonatomic) IBOutlet UIView *controlView;
@property (weak, nonatomic) IBOutlet UIImageView *playImage;

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) BOOL didPlay;
@property (nonatomic) BOOL isLoading;

@end

@implementation TDPostView

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)awakeFromNib {
    self.profileImage.layer.cornerRadius = 16.0;
    self.profileImage.layer.masksToBounds = YES;
    self.profileImage.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.profileImage.layer.borderWidth = 1.0;

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCaptured:)];
    [self.controlView addGestureRecognizer:singleTap];

    [self.previewImage setMultipleTouchEnabled:YES];
    [self.previewImage setUserInteractionEnabled:YES];
    self.userInteractionEnabled=YES;
}

- (void)setPost:(TDPost *)post {
    self.usernameLabel.text = post.user.username;
    self.createdLabel.text = [post.createdAt timeAgo];

    self.filename = post.filename;
    self.isLoading = NO;
    self.isPlaying = NO;
    self.didPlay = NO;
    self.playImage.hidden = NO;

    // Likes
    [self.likeCommentView setLike:post.liked];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"TDDownloadPreviewImageNotification"
                                                        object:self
                                                      userInfo:@{@"imageView":self.previewImage, @"filename":self.filename}];

    if (self.player != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
        [self.playerItem removeObserver:self forKeyPath:@"status" context:&ItemStatusContext];

        [self.playerLayer removeFromSuperlayer];
        self.player = nil;
        self.playerItem = nil;
        self.playerLayer = nil;
    }
}

- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture {
    if (!self.isLoading) {
        if (self.isPlaying) {
            [self.player pause];
            self.playImage.hidden = NO;
        } else {
            [self startVideo];
            self.playImage.hidden = YES;
        }
        self.isPlaying = !self.isPlaying;
    }
}

- (void)startVideo {
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

        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:location options:nil];
        NSString *tracksKey = @"tracks";

        [asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
               NSError *error;
               AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];

               if (status == AVKeyValueStatusLoaded) {
                   self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                   [self.playerItem addObserver:self forKeyPath:@"status"
                                        options:0 context:&ItemStatusContext];
                   [[NSNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(playerItemDidReachEnd:)
                                                                name:AVPlayerItemDidPlayToEndTimeNotification
                                                              object:self.playerItem];
                   self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
                   [self.playerLayer setPlayer:self.player];
               } else {
                   // TODO: Put up an error state on the view
                   debug NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
               }
           });
         }];
    } else {
        [self.player play];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &ItemStatusContext && self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.playerLayer.hidden = NO;
            // Only play once on status change (status change is called every time the player is reset)
            if (!self.didPlay) {
                self.isLoading = NO;
                self.didPlay = YES;
                [self.player play];
            }
        });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object
                           change:change context:context];
    return;
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    self.playImage.hidden = NO;
    self.isPlaying = NO;
    [self.player seekToTime:kCMTimeZero];
}


@end
