//
//  LMCoreTextLayoutLine.h
//  LMAttributedStringHeight
//
//  Created by zhuo on 2017/3/22.
//  Copyright © 2017年 zhuo. All rights reserved.


#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>


@class DTCoreTextLayoutFrame;

/**
 This class represents one layouted line and contains a number of glyph runs.
 */
@interface LMCoreTextLayoutLine : NSObject
{
	// IVAR required by DTRichTextEditor, used in category
		NSInteger _stringLocationOffset; // offset to modify internal string location to get actual location
}

- (id)initWithLine:(CTLineRef)line;

- (id)initWithLine:(CTLineRef)line stringLocationOffset:(NSInteger)stringLocationOffset;

@property (nonatomic, assign) NSRange stringRange; //字符的范围

/**
 The frame of the receiver relative to the layout frame
 */
@property (nonatomic, assign) CGRect frame;

@property (nonatomic,assign, readonly)  CGFloat leading; //

@property (nonatomic,assign) CGFloat lineHeight;



/**
 The ascent (height above the baseline) of the receiver
 */
@property (nonatomic, assign) CGFloat ascent; // needs to be modifiable

@property (nonatomic,assign) CGFloat descent;

/**
 The baseline origin of the receiver
 */
@property (nonatomic, assign) CGPoint baselineOrigin;

/**
 `YES` if the writing direction is Right-to-Left, otherwise `NO`
 */
@property (nonatomic, assign) BOOL writingDirectionIsRightToLeft;

/** 注释*/
@property (nonatomic, readonly) NSParagraphStyle *paragraphStyle;

@end
