//
//  TDActivitiesCell.h
//  Throwdown
//
//  Created by Andrew C on 4/14/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDActivitiesCellDelegate <NSObject>
-(void)userProfilePressedFromRow:(NSInteger)row;
-(void)postPressedFromRow:(NSInteger)row;
@end

@interface TDActivitiesCell : UITableViewCell

@property (nonatomic, assign) id <TDActivitiesCellDelegate> __unsafe_unretained delegate;
@property (nonatomic) NSDictionary *activity;
@property (nonatomic, assign) NSInteger row;

@end
