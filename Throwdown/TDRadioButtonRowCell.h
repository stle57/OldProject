//
//  TDRadioButtonRowCell.h
//  Throwdown
//
//  Created by Andrew C on 8/26/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDRadioButtonRowCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UIImageView *checkmark;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end
