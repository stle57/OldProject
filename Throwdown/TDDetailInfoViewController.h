//
//  TDDetailInfoViewController.h
//  Throwdown
//
//  Created by Stephanie Le on 1/18/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

@interface TDDetailInfoViewController : UIViewController
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIImageView *logoImageView;
@property (nonatomic) UILabel *label;
@property (nonatomic) TTTAttributedLabel *detailDescription;
@property (nonatomic) NSString *navTitle;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil title:(NSString*)title campaignData:(NSDictionary*)campaignData;

@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UILabel *navLabel;

- (IBAction)closeButtonPressed:(id)sender;
@end
