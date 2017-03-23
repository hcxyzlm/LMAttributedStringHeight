//
//  LMCoreTextLayoutLine.m
//  LMAttributedStringHeight
//
//  Created by zhuo on 2017/3/22.
//  Copyright © 2017年 zhuo. All rights reserved.

#import "LMCoreTextLayoutLine.h"
#import "NSDictionary+LMCoreText.h"

@interface LMCoreTextLayoutLine ()

@property (nonatomic, strong, readwrite) NSParagraphStyle *paragraphStyle;
@end

@implementation LMCoreTextLayoutLine
{
	CGRect _frame;
    
	CTLineRef _line;
	
	CGPoint _baselineOrigin;
	
	CGFloat _ascent;
	CGFloat _descent;
	CGFloat _leading;
	CGFloat _width;
	CGFloat _trailingWhitespaceWidth;
    
	BOOL _didCalculateMetrics;
	
	BOOL _writingDirectionIsRightToLeft;
	BOOL _needsToDetectWritingDirection;
    
}

- (id)initWithLine:(CTLineRef)line
{
	return [self initWithLine:line stringLocationOffset:0];
}

- (id)initWithLine:(CTLineRef)line stringLocationOffset:(NSInteger)stringLocationOffset
{
	if (!line)
	{
		return nil;
	}
	
	if ((self = [super init]))
	{
		_line = line;
		CFRetain(_line);
				
		// writing direction
		_needsToDetectWritingDirection = YES;
				
		_stringLocationOffset = stringLocationOffset;
	}
	return self;
}

- (CGFloat)lineHeight
{
    
    return _lineHeight;
}

- (void)dealloc
{
//    if (_line) {
//        CFRelease(_line);
//        _line = nil;
//    }
	
}

#ifndef COVERAGE
// exclude method from coverage testing

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ origin=%@ frame=%@ range=%@", [self class], NSStringFromCGPoint(_baselineOrigin), NSStringFromCGRect(self.frame), NSStringFromRange(self.stringRange)];
}

#endif

- (NSRange)stringRange
{
	CFRange range = CTLineGetStringRange(_line);
    
	return NSMakeRange(range.location, range.length);
}

// bounds of an image encompassing the entire run
- (CGRect)imageBoundsInContext:(CGContextRef)context
{
	return CTLineGetImageBounds(_line, context);
}

- (void)_calculateMetrics
{
	@synchronized(self)
	{
		if (!_didCalculateMetrics)
		{
			_width = (CGFloat)CTLineGetTypographicBounds(_line, &_ascent, &_descent, &_leading);
			_trailingWhitespaceWidth = (CGFloat)CTLineGetTrailingWhitespaceWidth(_line);
			
			_didCalculateMetrics = YES;
		}
	}
}

- (CGRect)frame
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	CGRect frame = CGRectMake(_baselineOrigin.x, _baselineOrigin.y - _ascent, _width, _ascent + _descent);
    
	return frame;
}

- (CGFloat)width
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	return _width;
}

- (CGFloat)ascent
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	return _ascent;
}

- (void)setAscent:(CGFloat)ascent
{
	// need to get metrics because otherwise ascent gets overwritten
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	_ascent = ascent;
}

- (NSParagraphStyle *)paragraphStyle
{
    // get paragraph style from any glyph
    
    if (!_paragraphStyle) {
        NSDictionary *attributes = nil;
        @synchronized(self)
        {
            
            CFArrayRef runs = CTLineGetGlyphRuns(_line);
            CFIndex runCount = CFArrayGetCount(runs);
            if (runCount > 0) {
                CTRunRef oneRun = CFArrayGetValueAtIndex(runs, runCount-1);
                
                attributes =  (__bridge_transfer  NSDictionary*)CTRunGetAttributes(oneRun);
            }
            _paragraphStyle = [attributes paragraphStyle];
        }
    }
    
    return _paragraphStyle;
}

- (CGFloat)descent
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	return _descent;
}

- (CGFloat)leading
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	return _leading;
}

- (CGFloat)trailingWhitespaceWidth
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	return _trailingWhitespaceWidth;
}


- (void)setWritingDirectionIsRightToLeft:(BOOL)writingDirectionIsRightToLeft
{
	_writingDirectionIsRightToLeft = writingDirectionIsRightToLeft;
	_needsToDetectWritingDirection = NO;
}
- (NSRange) range {
    
    CFRange rag= CTLineGetStringRange(_line);
    
    return NSMakeRange(rag.location, rag.length);
}

@synthesize frame =_frame;

@synthesize ascent = _ascent;
@synthesize descent = _descent;

@synthesize paragraphStyle = _paragraphStyle;
@synthesize baselineOrigin = _baselineOrigin;

@end
