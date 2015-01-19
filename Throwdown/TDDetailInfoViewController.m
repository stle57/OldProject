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

@end

@implementation TDDetailInfoViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil title:(NSString*)title
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navTitle = title;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // Do any additional setup after loading the view from its nib.
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];

    // Background color

    self.view.backgroundColor = [UIColor whiteColor];

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


    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, self.logoImageView.frame.origin.y + [UIImage imageNamed:@"Strengthlete_Logo_BIG"].size.height + 10, 100, 100)];

    NSString *titleStr = @"Strengthlete 28-Day\nChallenge!";
    NSAttributedString *titleAttrStr = [TDViewControllerHelper makeParagraphedTextWithString:titleStr font:[TDConstants fontSemiBoldSized:19] color:[TDConstants headerTextColor] lineHeight:23 lineHeightMultipler:(23./19.)];
    self.label.attributedText = titleAttrStr;
    [self.label setNumberOfLines:0];
    [self.label sizeToFit];

    CGRect labelFrame = self.label.frame;
    labelFrame.origin.x = SCREEN_WIDTH/2 - self.label.frame.size.width/2;
    labelFrame.origin.y = self.logoImageView.frame.origin.y + self.label.frame.size.height + 10;
    self.label.frame = labelFrame;

    self.detailDescription = [[UILabel alloc] initWithFrame:CGRectMake(0, self.label.frame.origin.y + self.label.frame.size.height + 15, SCREEN_WIDTH, 200)];
    NSString *detailStr = @"Strengthlete challenges you to eat clean and exercise for all of February!\n\nEveryday, make a post of your workout and what you ate.\n\nTag #strengthlete in your post to be included in the Challenge.\n\nAt the end of 28 days, prizes will be awared to:\n\n -Protein\n-1-HR session with Catalyst Team\n-Ticket to the CrossFit Games";
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

    [TDViewControllerHelper boldHashtagsInLabel:self.detailDescription];
    CGRect detailFrame = self.detailDescription.frame;
    detailFrame.size.width = SCREEN_WIDTH - 60;
    detailFrame.origin.x = 30;
    detailFrame.origin.y = self.label.frame.origin.y + self.label.frame.size.height + 15;
    self.detailDescription.frame = detailFrame;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)closeButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
