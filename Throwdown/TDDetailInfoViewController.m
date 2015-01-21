//
//  TDDetailInfoViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 1/18/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import "TDDetailInfoViewController.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"
#import <SDWebImageManager.h>
#import <UIImage+Resizing.h>

@interface TDDetailInfoViewController () <TTTAttributedLabelDelegate>
@property (nonatomic) NSDictionary *data;
@end

@implementation TDDetailInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil title:(NSString*)title campaignData:(NSDictionary *)campaignData
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navTitle = title;
        self.data = [campaignData copy];
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];

    // Background color

    self.view.backgroundColor = [UIColor whiteColor];
    debug NSLog(@"self.view = %@", NSStringFromCGRect(self.view.frame));
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,  SCREEN_HEIGHT - self.navigationController.navigationBar.frame.size.height)];

    if (self.scrollView.scrollEnabled) {
        debug NSLog(@"scrolling is enabled");
    }
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.closeButton];     // 'X'
    self.navigationItem.leftBarButtonItem = leftBarButton;
    [navigationBar setBarStyle:UIBarStyleBlack];
    [navigationBar setTranslucent:NO];
    [navigationBar setOpaque:YES];

    // Title
    self.navLabel.text = self.navTitle;
    self.navLabel.textColor = [UIColor whiteColor];
    self.navLabel.font = [TDConstants fontSemiBoldSized:18];
    self.navLabel.textAlignment = NSTextAlignmentCenter;
    [self.navLabel sizeToFit];
    [self.navigationItem setTitleView:self.navLabel];

    self.logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2 - kBigImageWidth/2, 15, kBigImageWidth, kBigImageHeight)];
    self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;

    [self.scrollView addSubview:self.logoImageView];

    [self downloadPreview:[self.data objectForKey:@"image"]];

    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, self.logoImageView.frame.origin.y + kBigImageHeight + 10, SCREEN_WIDTH, 100)];

    NSString *titleStr = [self.data objectForKey:@"title"];
    NSAttributedString *titleAttrStr = [TDViewControllerHelper makeParagraphedTextWithString:titleStr font:[TDConstants fontSemiBoldSized:19] color:[TDConstants headerTextColor] lineHeight:23 lineHeightMultipler:(23./19.)];
    self.label.attributedText = titleAttrStr;
    [self.label setNumberOfLines:0];
    [self.label sizeToFit];

    CGRect labelFrame = self.label.frame;
    labelFrame.origin.x = SCREEN_WIDTH/2 - self.label.frame.size.width/2;
    self.label.frame = labelFrame;
    [self.scrollView addSubview:self.label];

    self.detailDescription = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, self.label.frame.origin.y + self.label.frame.size.height + 15, SCREEN_WIDTH-60, 200)];
    self.detailDescription.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.detailDescription.delegate = self;
    self.detailDescription.linkAttributes = nil;
    self.detailDescription.activeLinkAttributes = nil;
    self.detailDescription.inactiveLinkAttributes = nil;
    self.detailDescription.font = [TDConstants fontRegularSized:15];
    [self.detailDescription setNumberOfLines:0];
    NSString *detailStr = [self.data objectForKey:@"description"];
    [self.detailDescription setText:detailStr];

    NSMutableAttributedString *detailAttrStr = [self.detailDescription.attributedText mutableCopy];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:18/15.];
    [paragraphStyle setMinimumLineHeight:18];
    [paragraphStyle setMaximumLineHeight:18];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    [detailAttrStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, detailStr.length)];
    [detailAttrStr addAttribute:NSFontAttributeName value:[TDConstants fontRegularSized:15] range:NSMakeRange(0, detailStr.length)];
    [detailAttrStr addAttribute:NSForegroundColorAttributeName value:[TDConstants headerTextColor] range:NSMakeRange(0, detailStr.length)];
    detailAttrStr = [TDViewControllerHelper boldHashtagsInText:detailAttrStr fontSize:15];
    self.detailDescription.attributedText = detailAttrStr;
    [TDViewControllerHelper colorLinksInLabel:self.detailDescription];
    [self.detailDescription sizeToFit];

    CGRect detailFrame = self.detailDescription.frame;
    detailFrame.size.width = SCREEN_WIDTH - 60;
    detailFrame.origin.x = 30;
    detailFrame.origin.y = self.label.frame.origin.y + self.label.frame.size.height + 15;
    self.detailDescription.frame = detailFrame;
    [self.scrollView addSubview:self.detailDescription];

    CGSize scrollableSize =  CGSizeMake(SCREEN_WIDTH,
                                        15 + kBigImageHeight + 10 + self.label.frame.size.height + 15 + self.detailDescription.frame.size.height + 20 + 20);
    [self.scrollView setContentSize:scrollableSize];

    [self.view addSubview:self.scrollView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closeButtonPressed:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)downloadPreview:(NSString*)stringURL {
    NSURL *downloadURL = [NSURL URLWithString:stringURL];

    downloadURL = [NSURL URLWithString:stringURL];
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:downloadURL options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        // no progress bar here
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *finalURL) {
        if (![finalURL isEqual:downloadURL]) {
            return;
        }
        if (!error && image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.logoImageView) {
                    self.logoImageView.image = image;
                }
            });
        }
    }];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if (![TDViewControllerHelper isThrowdownURL:url]) {
        [TDViewControllerHelper askUserToOpenInSafari:url];
    }
}

@end
