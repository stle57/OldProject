//
//  TDActivitiesCell.h
//  Throwdown
//
//  Created by Andrew C on 4/14/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDActivitiesCellDelegate <NSObject>
@optional
-(void)userProfilePressedWithId:(NSNumber *)userId;
-(void)activityPressedFromRow:(NSNumber *)row;
@end

@interface TDActivitiesCell : UITableViewCell

@property (nonatomic, weak) id <TDActivitiesCellDelegate> delegate;
@property (nonatomic) NSDictionary *activity;
@property (nonatomic, assign) NSInteger row;

@end
