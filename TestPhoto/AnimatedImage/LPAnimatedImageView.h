//
//  LPAnimatedImageView.h
//  TestPhoto
//
//  Created by Jack on 2017/12/11.
//  Copyright © 2017年 Jack. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LPAnimateImage;
@interface LPAnimatedImageView : UIView

@property (nonatomic,strong) LPAnimateImage *animatedImage;
@property (nonatomic,assign) BOOL isPlaying;

@end
