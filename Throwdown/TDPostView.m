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

@implementation TDPostView
{
    AVPlayer *player;
    AVPlayerItem *playerItem;
    AVPlayerLayer *playerLayer;
}

// Define this constant for the key-value observation context.
static const NSString *ItemStatusContext;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) awakeFromNib
{
    self.profileImage.layer.cornerRadius = 16.0;
    self.profileImage.layer.masksToBounds = YES;
    self.profileImage.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.profileImage.layer.borderWidth = 1.0;

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCaptured:)];

    [self.previewImage addGestureRecognizer:singleTap];
    [self.previewImage setMultipleTouchEnabled:YES];
    [self.previewImage setUserInteractionEnabled:YES];
    self.userInteractionEnabled=YES;

//    [self.profileImage setImage:[UIImage imageWithContentsOfFile:@"prof_pic_med2.png"]];
}

- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture
{
//    UIView *tappedView = [gesture.view hitTest:[gesture locationInView:gesture.view] withEvent:nil];
//    NSLog(@"Touch event on view: %@",[tappedView class]);

    NSURL *location = [TDConstants getStreamingUrlFor:self.filename];
//    NSURL *location = [NSURL URLWithString:@"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"];
    NSLog(@"Loading movie from: %@", location);

    self.previewImage.hidden = YES;

//    [item addObserver:self forKeyPath:@"status" options:0 context:&ItemStatusContext];
//    player = [AVPlayer playerWithPlayerItem:playerItem];
    playerLayer = [AVPlayerLayer layer];
//    [playerLayer setPlayer:player];
    [playerLayer setFrame:self.previewImage.frame];
    [playerLayer setBackgroundColor:[UIColor blackColor].CGColor];
    [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.layer addSublayer:playerLayer];


    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:location options:nil];
    NSString *tracksKey = @"tracks";

    [asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
           NSError *error;
           AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];

           if (status == AVKeyValueStatusLoaded) {
//               playerItem = [AVPlayerItem playerItemWithURL:location];
               playerItem = [AVPlayerItem playerItemWithAsset:asset];
               [playerItem addObserver:self forKeyPath:@"status"
                                    options:0 context:&ItemStatusContext];
//               [[NSNotificationCenter defaultCenter] addObserver:self
//                                                        selector:@selector(playerItemDidReachEnd:)
//                                                            name:AVPlayerItemDidPlayToEndTimeNotification
//                                                          object:playerItem];
               player = [AVPlayer playerWithPlayerItem:playerItem];
               [playerLayer setPlayer:player];
           } else {
               // You should deal with the error appropriately.
               NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
           }
       });
         // The completion block goes here.
     }];

//    [player play];
}

- (IBAction)play:sender {
    [player play];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {

    if (context == &ItemStatusContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"GOT STATUS CHANGE");
            [player play];
//            [self syncUI];
        });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object
                           change:change context:context];
    return;
}


- (void) setPreviewImageFrom:(NSString *)filename
{
    self.filename = filename;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TDDownloadPreviewImageNotification"
                                                        object:self
                                                      userInfo:@{@"imageView":self.previewImage, @"filename":filename}];
}

//- (void)imageTapped {
//    NSURL *url = [NSURL URLWithString:@"http://www.samkeeneinteractivedesign.com/videos/littleVid3.mp4"];
//    self.mPlayer = [AVPlayer playerWithURL:url];
//    self.mPlayer2 = [AVPlayer playerWithURL:url];
//    [mPlayer addObserver:self forKeyPath:@"status" options:0 context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
//}
//
//- (void)observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context
//{
//    if (mPlayer.status == AVPlayerStatusReadyToPlay) {
//        [self.mPlaybackView2 setPlayer:self.mPlayer2];
//        [self.mPlaybackView setPlayer:self.mPlayer];
//        [self.mPlayer play];
//        [self.mPlayer2 play];
//    }
//}


@end
