//
//  TDUserListCell.h
//  Throwdown
//
//  Created by Andrew C on 7/22/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDUserListCell : UITableViewCell

@property (nonatomic) UILabel *name;
@property (nonatomic) UILabel *username;
@property (nonatomic) UIImageView *profileImage;
@property (nonatomic, assign) NSInteger userId;
@property (nonatomic) NSURL *userImageURL;

@end
