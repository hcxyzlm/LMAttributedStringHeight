//
//  LMCoreTextRun.m
//  LMAttributedStringHeight
//
//  Created by zhuo on 2017/3/23.
//  Copyright © 2017年 zhuo. All rights reserved.
//

#import "LMCoreTextRun.h"

@implementation LMCoreTextRun
{
    CTRunRef _run;
    
    CGFloat _offset; // x distance from line origin
    
     NSDictionary *_attributes; // weak because it is owned by _run IVAR
}

- (id)initWithRun:(CTRunRef)run offset:(CGFloat)offset {
    
    self = [super init];
    
    if (self)
    {
        _run = run;
        CFRetain(_run);
        
        _offset = offset;
    }
    
    return self;
}
- (void)dealloc {
    if (_run) {
        CFRelease(_run);
    }
}

- (NSDictionary *)attributes
{
    if (!_attributes)
    {
        _attributes = (__bridge NSDictionary *)CTRunGetAttributes(_run);
    }
    
    return _attributes;
}

@synthesize attributes = _attributes;
@end
