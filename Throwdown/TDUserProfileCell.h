//
//  TDUserProfileCell.h
//  Throwdown
//
//  Created by Andrew Bennett on 4/8/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDUserProfileCellDelegate <NSObject>
@optional
@end

@interface TDUserProfileCell : UITableViewCell
{
    id <TDUserProfileCellDelegate> __unsafe_unretained delegate;
}

@property (nonatomic, assign) id <TDUserProfileCellDelegate> __unsafe_unretained delegate;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;

@end
