//
//  LMCoreTextFrameLayout.h
//  LMAttributedStringHeight
//
//  Created by zhuo on 2017/3/22.
//  Copyright © 2017年 zhuo. All rights reserved.



#import <UIKit/UIKit.h>

#define CGFLOAT_WIDTH_UNKNOWN 16777215.0f

// the value to use if the height is unknown
#define CGFLOAT_HEIGHT_UNKNOWN 16777215.0f

#import <CoreText/CoreText.h>
@class LMCoreTextLayoutLine;

@interface LMCoreTextFrameLayout : NSObject
{
	CGRect _frame;

	NSArray *_lines;
	NSAttributedString *_attributedStringFragment;
}

- (id)initWithFrame:(CGRect)frame attributedString:(NSAttributedString *)attributedString;

- (id)initWithFrame:(CGRect)frame attributedString:(NSAttributedString *)attributedString range:(NSRange)range;

- (NSRange)visibleStringRange;


/**
 This is a copy of the attributed string owned by the layouter of the receiver.
*/
- (NSAttributedString *)attributedStringFragment;

- (void)setAttributedStringFragment:(NSAttributedString *) attar;

@property (nonatomic, assign, readonly) CGRect frame;

/**
 The frame rectangle for the layout frame.
 */


@property (nonatomic, strong) NSArray *lines;

- (void)buildLines;

- (BOOL)isLineLastInParagraph:(LMCoreTextLayoutLine *)line;


/**
 Maximum number of lines to display before truncation.  Default is 0 which indicates no limit.
 */
@property(nonatomic, assign) NSInteger numberOfLines;


/**
 Line break mode used to indicate how truncation should occur
 */
@property(nonatomic, assign) NSLineBreakMode lineBreakMode;


/**
 Optional attributed string to use as truncation indicator.  If nil, will use "…" w/ attributes taken from text being truncated
 */
@property(nonatomic, strong)NSAttributedString *truncationString;

- (LMCoreTextLayoutLine *)lineContainingIndex:(NSUInteger)index;

@end

