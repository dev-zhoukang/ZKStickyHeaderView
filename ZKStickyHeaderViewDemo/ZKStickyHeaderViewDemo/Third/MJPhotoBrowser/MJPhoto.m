//
//  MJPhoto.m
//
//  Created by ZK on 16/7/19.
//  Copyright © 2016年 ZK. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MJPhoto.h"

@implementation MJPhoto

- (void)setSrcImageView:(UIImageView *)srcImageView
{
    _srcImageView = srcImageView;
    _placeholder = srcImageView.image;
}

@end