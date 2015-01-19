//
//  TDDetailInfoViewController.h
//  Throwdown
//
//  Created by Stephanie Le on 1/18/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDDetailInfoViewController : UIViewController
@property (nonatomic) UIImageView *logoImageView;
@property (nonatomic) UILabel *label;
@property (nonatomic) UILabel *detailDescription;
@property (nonatomic) NSString *navTitle;

@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UILabel *navLabel;

- (IBAction)closeButtonPressed:(id)sender;
@end
