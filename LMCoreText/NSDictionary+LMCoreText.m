//
//  NSAttributedString+LMCoreText.m
//  LMAttributedStringHeight
//
//  Created by zhuo on 2017/3/23.
//  Copyright © 2017年 zhuo. All rights reserved.
//

#import "NSDictionary+LMCoreText.h"
#import <CoreText/CoreText.h>

@implementation NSDictionary (LMCoreText)


- (NSParagraphStyle *)paragraphStyle
{
    NSParagraphStyle *nsParagraphStyle = [self objectForKey:NSParagraphStyleAttributeName];
    
    if (nsParagraphStyle && [nsParagraphStyle isKindOfClass:[NSParagraphStyle class]])
    {
        return nsParagraphStyle;
    }
    
    
    CTParagraphStyleRef ctParagraphStyle = (__bridge CTParagraphStyleRef)[self objectForKey:(id)kCTParagraphStyleAttributeName];
    
    if (ctParagraphStyle)
    {
        return (__bridge_transfer  NSParagraphStyle*)ctParagraphStyle;
    }
    
    return nil;
}


@end
