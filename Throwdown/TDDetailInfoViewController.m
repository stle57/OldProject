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

@interface TDDetailInfoViewController ()
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
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];

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

    self.logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Strengthlete_Logo_BIG"]];
    self.logoImageView.frame = CGRectMake(SCREEN_WIDTH/2 - [UIImage imageNamed:@"Strengthlete_Logo_BIG"].size.width/2, 15, [UIImage imageNamed:@"Strengthlete_Logo_BIG"].size.width, [UIImage imageNamed:@"Strengthlete_Logo_BIG"].size.height);
    [self.scrollView addSubview:self.logoImageView];

    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, self.logoImageView.frame.origin.y + [UIImage imageNamed:@"Strengthlete_Logo_BIG"].size.height + 10, SCREEN_WIDTH, 100)];

   // NSString *titleStr = @"Strengthlete 28-Day\nChallenge!";
    NSString *titleStr = [self.data objectForKey:@"title"];
    NSAttributedString *titleAttrStr = [TDViewControllerHelper makeParagraphedTextWithString:titleStr font:[TDConstants fontSemiBoldSized:19] color:[TDConstants headerTextColor] lineHeight:23 lineHeightMultipler:(23./19.)];
    self.label.attributedText = titleAttrStr;
    [self.label setNumberOfLines:0];
    [self.label sizeToFit];

    CGRect labelFrame = self.label.frame;
    labelFrame.origin.x = SCREEN_WIDTH/2 - self.label.frame.size.width/2;
    labelFrame.origin.y = self.logoImageView.frame.origin.y + self.label.frame.size.height + 10;
    self.label.frame = labelFrame;
    [self.scrollView addSubview:self.label];

    self.detailDescription = [[UILabel alloc] initWithFrame:CGRectMake(0, self.label.frame.origin.y + self.label.frame.size.height + 15, SCREEN_WIDTH-60, 200)];
    NSString *detailStr = [self.data objectForKey:@"description"];
    debug NSLog(@"detailStr = %@", detailStr);

    NSMutableAttributedString *detailAttrStr = [[NSMutableAttributedString alloc] initWithString:detailStr];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:18/15.];
    [paragraphStyle setMinimumLineHeight:18];
    [paragraphStyle setMaximumLineHeight:18];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    [detailAttrStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, detailStr.length)];
    [detailAttrStr addAttribute:NSFontAttributeName value:[TDConstants fontRegularSized:15] range:NSMakeRange(0, detailStr.length)];
    [detailAttrStr addAttribute:NSForegroundColorAttributeName value:[TDConstants headerTextColor] range:NSMakeRange(0, detailStr.length)];
    self.detailDescription.attributedText = detailAttrStr;
    [self.detailDescription setNumberOfLines:0];
    [self.detailDescription sizeToFit];

    CGRect detailFrame = self.detailDescription.frame;
    detailFrame.size.width = SCREEN_WIDTH - 60;
    detailFrame.origin.x = 30;
    detailFrame.origin.y = self.label.frame.origin.y + self.label.frame.size.height + 15;
    self.detailDescription.frame = detailFrame;
    [self.scrollView addSubview:self.detailDescription];

    CGSize scrollableSize =  CGSizeMake(SCREEN_WIDTH,
                                        15 + self.logoImageView.frame.size.height + 10 + self.label.frame.size.height + 15 + self.detailDescription.frame.size.height + 20);
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
@end
