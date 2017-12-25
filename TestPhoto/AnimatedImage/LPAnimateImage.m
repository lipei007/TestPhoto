//
//  LPAnimateImage.m
//  TestPhoto
//
//  Created by Jack on 2017/12/11.
//  Copyright © 2017年 Jack. All rights reserved.
//

#import "LPAnimateImage.h"
#import <ImageIO/ImageIO.h>

@interface LPAnimateImage()
{
    CGImageSourceRef _imageSource;
    NSMutableArray *_delays;
}

@end

@implementation LPAnimateImage

- (instancetype)initWithUrl:(NSURL *)url {
    if (url == nil) {
        return nil;
    }
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge_retained CFURLRef)url, nil);
    if (source == nil) {
        return nil;
    }
    return [self initSource:source];
}

- (instancetype)initWithData:(NSData *)data {
    if (data == nil || data.length < 1) {
        return nil;
    }
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge_retained CFDataRef)data, nil);
    if (source == nil) {
        return nil;
    }
    return [self initSource:source];
}

- (instancetype)initSource:(CGImageSourceRef)source {
    
    if (source == nil) {
        return nil;
    }
    
    if (self = [super init]) {
        _imageSource = source;
        _frameCount = CGImageSourceGetCount(_imageSource);
        CFDictionaryRef imageProperties = CGImageSourceCopyProperties(source, nil);
        
        if (imageProperties != NULL) {
            _loopCount = [self.class loopCountForProperties:imageProperties];
        } else {
            _loopCount = 1;
        }
        
        CGImageRef firstImage = CGImageSourceCreateImageAtIndex(source, 0, nil);
        if (firstImage != NULL) {
            _size = CGSizeMake(CGImageGetWidth(firstImage), CGImageGetHeight(firstImage));
        } else {
            _size = CGSizeZero;
        }
        
        _delays = [NSMutableArray arrayWithCapacity:_frameCount];
         _duration = 0.0;
        
        for (int i = 0; i < _frameCount; i++) {
            NSNumber *delay = @(1.0 / 30.0);
            
            CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(source, i, nil);
            if (imageProperties != NULL) {
                double time = [self.class frameDelayForProperties:imageProperties];
                delay = @(time);
            }
            [_delays addObject:delay];
            _duration += [delay doubleValue];
        }
       
        
        CGImageRelease(firstImage);
        CFRelease(imageProperties);
    }
    return self;
}

- (CGImageRef)imageAtIndex:(NSInteger)index {
    if (index < _frameCount) {
        return CGImageSourceCreateImageAtIndex(_imageSource, index, nil);
    }
    return nil;
}

- (double)delayAtIndex:(NSInteger)index {
    return [_delays[index] doubleValue];
}

+ (double)frameDelayForProperties:(CFDictionaryRef)properties {
    CFDictionaryRef gifDictionary = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
    if (gifDictionary == NULL) {
        return 0;
    }
    double delay = [(NSNumber *)CFDictionaryGetValue(gifDictionary, kCGImagePropertyGIFUnclampedDelayTime) doubleValue];
    if (delay > 0.0) {
        return delay;
    }
    
    delay = [(NSNumber *)CFDictionaryGetValue(gifDictionary, kCGImagePropertyGIFDelayTime) doubleValue];
    if (delay > 0) {
        return delay;
    }
    
    return 0;
}

+ (NSInteger)loopCountForProperties:(CFDictionaryRef)properties {
    CFDictionaryRef gifDictionary = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
    if (gifDictionary != NULL) {
        NSInteger loopCount = [(NSNumber *)CFDictionaryGetValue(gifDictionary, kCGImagePropertyGIFLoopCount) integerValue];
        return loopCount;
    }
    return 1;
}

@end
