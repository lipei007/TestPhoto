//
//  LPAnimatedImageView.m
//  TestPhoto
//
//  Created by Jack on 2017/12/11.
//  Copyright © 2017年 Jack. All rights reserved.
//

#import "LPAnimatedImageView.h"
#import "LPAnimateImage.h"

@interface DisplayLinkProxyObject : NSObject

@property (nonatomic,weak) LPAnimatedImageView *myListener;

- (instancetype)initWithListener:(LPAnimatedImageView *)listener;
- (void)proxyTimerFired:(CADisplayLink *)link;

@end

@interface LPAnimatedImageView ()
{
    CADisplayLink *_displayLink;
    NSInteger _displayedIndex;
    UIView *_displayView;
    
    // animation state
    BOOL _hasStartedAnimating;
    BOOL _hasFinishedAnimating;
    BOOL _isInfinishedLoop;
    NSInteger _remainingLoopCount;
    double _elapseTime;
    double _previousTime;
}

@property (nonatomic,strong) DisplayLinkProxyObject *displayLinkProxy;

@end

#pragma mark - Implementation

@implementation LPAnimatedImageView

- (DisplayLinkProxyObject *)displayLinkProxy {
    if (!_displayLinkProxy) {
        _displayLinkProxy = [[DisplayLinkProxyObject alloc] initWithListener:self];
    }
    return _displayLinkProxy;
}

- (void)dealloc {
    [_displayLink invalidate];
}

- (void)setAnimatedImage:(LPAnimateImage *)animatedImage {
    _animatedImage = animatedImage;
    [self resetAnimationState];
    [self updateAnimation];
    [self setNeedsLayout];
}

- (void)setIsPlaying:(BOOL)isPlaying {
    
    if (isPlaying != _isPlaying) {
        _isPlaying = isPlaying;
        [self updateAnimation];
    }
    _isPlaying = isPlaying;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    double viewAspect = 0.0;
    if (self.bounds.size.height > 0.0) {
        viewAspect = CGRectGetWidth(self.bounds) / CGRectGetHeight(self.bounds);
    }
    
    double imageAspect = 0.0;
    if (self.animatedImage) {
        if (_animatedImage.size.height > 0) {
            imageAspect = _animatedImage.size.width / _animatedImage.size.height;
        }
    }
    
    CGRect viewFrame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    if (imageAspect < viewAspect) {
        viewFrame.size.width = self.bounds.size.height * imageAspect;
        viewFrame.origin.x = (self.bounds.size.width / 2.0) - (0.5 * viewFrame.size.width);
    } else if (imageAspect > 0.0) {
        viewFrame.size.height = self.bounds.size.width / imageAspect;
        viewFrame.origin.y = (self.bounds.size.height / 2.0) - (0.5 * viewFrame.size.height);
    }
    
    if (_animatedImage != nil) {
        
        if (_displayView == nil) {
            _displayView = [[UIView alloc] initWithFrame:CGRectZero];
            [self addSubview:_displayView];
            [self updateImage];
        }
        
    } else {
        if (_displayView != nil) {
            [_displayView removeFromSuperview];
            _displayView = nil;
        }
    }
    
    if (_displayView != nil) {
        _displayView.frame = viewFrame;
    }
    
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self updateAnimation];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self updateAnimation];
}

- (void)setAlpha:(CGFloat)alpha {
    [super setAlpha:alpha];
    [self updateAnimation];
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    [self updateAnimation];
}

- (BOOL)shouldAnimate {
    BOOL isShown = self.window != nil && self.superview != nil && !self.isHidden && self.alpha > 0.0;
    return isShown && self.animatedImage != nil && _isPlaying && !_hasFinishedAnimating;
}

- (void)resetAnimationState {
    _displayedIndex = 0;
    _hasStartedAnimating = NO;
    _hasFinishedAnimating = NO;
    _isInfinishedLoop = self.animatedImage != nil ? self.animatedImage.frameCount : 0;
    _remainingLoopCount = self.animatedImage != nil ? self.animatedImage.loopCount : 0;
    _elapseTime = 0.0;
    _previousTime = 0.0;
}

- (void)updateAnimation {
    if ([self shouldAnimate]) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self.displayLinkProxy selector:@selector(proxyTimerFired:)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        if (@available(iOS 10.0, *)) {
            [_displayLink setPreferredFramesPerSecond:60];
        } else {
            // Fallback on earlier versions
        }
    } else {
        [_displayLink invalidate];
        _displayLink = nil;
    }
}

- (void)updateImage {
    if (self.animatedImage != nil) {
        CGImageRef image = [self.animatedImage imageAtIndex:_displayedIndex];
        if (image != NULL && _displayView != nil) {
            _displayView.layer.contents = (__bridge id _Nullable)(image);
        }
    }
}

- (void)timerFired:(CADisplayLink *)link {
    if (![self shouldAnimate]) {
        return;
    }
    
    LPAnimateImage *image = self.animatedImage;
    if (image == nil) {
        return;
    }
    
    CFTimeInterval timestamp = link.timestamp;
    
    if (!_hasStartedAnimating) {
        _elapseTime = 0.0;
        _previousTime = timestamp;
        _hasStartedAnimating = YES;
    }
    
    double currentDelayTime = [image delayAtIndex:_displayedIndex];
    _elapseTime += timestamp - _previousTime;
    _previousTime = timestamp;
    
    if (_elapseTime >= MAX(10.0, currentDelayTime + 1.0)) {
        _elapseTime = 0.0;
    }
    
    BOOL changedFrame = NO;
    while (_elapseTime >= currentDelayTime) {
        _elapseTime -= currentDelayTime;
        _displayedIndex += 1;
        changedFrame = YES;
        if (_displayedIndex >= image.frameCount) {
            if (_isInfinishedLoop) {
                _displayedIndex = 0;
            } else {
                _remainingLoopCount -= 1;
                if (_remainingLoopCount == 0) {
                    _hasFinishedAnimating = YES;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self updateAnimation];
                    });
                } else {
                    _displayedIndex = 0;
                }
            }
        }
    }
    
    if (changedFrame) {
        [self updateImage];
    }
}



@end

#pragma mark - Displaylink Proxy

@implementation DisplayLinkProxyObject

- (instancetype)initWithListener:(LPAnimatedImageView *)listener {
    if (self = [super init]) {
        self.myListener = listener;
    }
    return self;
}

- (void)proxyTimerFired:(CADisplayLink *)link {
    if (self.myListener) {
        [self.myListener timerFired:link];
    }
}

@end
