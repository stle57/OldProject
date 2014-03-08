//
//  TDPostUpload.h
//  Throwdown
//
//  Created by Andrew C on 3/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDProgressIndicator.h"

@interface TDPostUpload : NSObject

- (id)initWithVideoPath:(NSString *)videoPath thumbnailPath:(NSString *)thumbnailPath newName:(NSString *)newName;

@property (strong, nonatomic) id<TDProgressIndicatorDelegate> delegate;

@end
