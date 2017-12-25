//
//  LPAnimateImage.h
//  TestPhoto
//
//  Created by Jack on 2017/12/11.
//  Copyright © 2017年 Jack. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LPAnimateImage : NSObject

@property (nonatomic,assign) NSInteger frameCount;
@property (nonatomic,assign) double duration;
@property (nonatomic,assign) NSInteger loopCount;
@property (nonatomic,assign) CGSize size;


- (instancetype)initWithUrl:(NSURL *)url;
- (instancetype)initWithData:(NSData *)data;
- (instancetype)initSource:(CGImageSourceRef)source ;

- (CGImageRef)imageAtIndex:(NSInteger)index;
- (double)delayAtIndex:(NSInteger)index;

@end
