//
//  TDCampaignView.h
//  Throwdown
//
//  Created by Stephanie Le on 1/19/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDConstants.h"

@protocol TDCampaignViewDelegate<NSObject>
@optional
-(void)loadDetailView;
-(void)loadChallengersView;
@end

@interface TDCampaignView : UIView
@property (nonatomic, weak) id <TDCampaignViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame campaignData:(NSDictionary*)campaignData;
+ (NSInteger)heightForCampaignHeader:(NSDictionary*)campaignData;
@end
