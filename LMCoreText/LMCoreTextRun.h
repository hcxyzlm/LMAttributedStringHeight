//
//  LMCoreTextRun.h
//  LMAttributedStringHeight
//
//  Created by zhuo on 2017/3/23.
//  Copyright © 2017年 zhuo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

@interface LMCoreTextRun : NSObject



/**
 Creates a new glyph run from a `CTRun`, belonging to a given layout line and with a given offset from the left line origin.
 @param run The Core Text glyph run to wrap
 @param offset The offset from the left line origin to place the glyph run at
 @returns An initialized LMCoreTextRun
 */
- (id)initWithRun:(CTRunRef)run  offset:(CGFloat)offset;

@property (nonatomic, strong) NSDictionary *attributes;

@end
