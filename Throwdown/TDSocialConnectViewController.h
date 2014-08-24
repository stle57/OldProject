//
//  TDSocialConnectViewController.h
//  Throwdown
//
//  Created by Andrew C on 8/11/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    TDSocialNetworkFacebook,
    TDSocialNetworkTwitter
} TDSocialNetwork;

@interface TDSocialConnectViewController : UIViewController

@property (nonatomic, assign) TDSocialNetwork network;

@end
