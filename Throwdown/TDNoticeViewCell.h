//
//  TDNoticeViewCell.h
//  Throwdown
//
//  Created by Andrew C on 6/3/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDNotice.h"

@interface TDNoticeViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *ctaLabel;

- (void)setNotice:(TDNotice *)notice;

+ (NSInteger)heightForNotice:(TDNotice *)notice;

@end
