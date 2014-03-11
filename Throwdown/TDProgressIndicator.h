//
//  TDProgressIndicator.h
//  Throwdown
//
//  Created by Andrew C on 3/4/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDPostUpload.h"
#import "TDHomeHeaderUploadDelegate.h"

@interface TDProgressIndicator : UIView

@property (strong, nonatomic) UIImageView *thumbnailView;

- (id)initWithUpload:(TDPostUpload *)upload delegate:(id<TDHomeHeaderUploadDelegate>)delegate;

@end
