//
//  TDTagFeedViewController.h
//  Throwdown
//
//  Created by Andrew C on 1/17/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import "TDPostsViewController.h"
#import "TDGuestInfoCell.h"
#import "TDCampaignView.h"
@interface TDTagFeedViewController : TDPostsViewController<TDCampaignViewDelegate>

@property (nonatomic) NSString *tagName;

@end
