//
//  LMCoreTextLayoutLine.m
//  LMAttributedStringHeight
//
//  Created by zhuo on 2017/3/22.
//  Copyright © 2017年 zhuo. All rights reserved.

#import "LMCoreTextLayoutLine.h"
#import "NSDictionary+LMCoreText.h"
#import "LMCoreTextRun.h"

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
    
    NSArray *_coretextRuns;  // runs
    
    BOOL _hasScannedGlyphRunsForValues;
    
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
        _hasScannedGlyphRunsForValues = NO;
	}
	return self;
}

- (CGFloat)lineHeight
{
    if (!_hasScannedGlyphRunsForValues)
    {
        [self _scanGlyphRunsForValues];
    }
    
    return _lineHeight;
}

- (void)_scanGlyphRunsForValues
{
    @synchronized(self)
    {
        CGFloat maxFontSize = 0;
        
        for (LMCoreTextRun *oneRun in self.glyphRuns)
        {
            CTFontRef usedFont = (__bridge CTFontRef)([oneRun.attributes objectForKey:(id)kCTFontAttributeName]);
            if (usedFont)
            {
                
                maxFontSize = MAX(maxFontSize, CTFontGetSize(usedFont));
            }
            
        }
        
        _lineHeight = maxFontSize;
        
        _hasScannedGlyphRunsForValues= YES;
    }
}

- (void)dealloc
{
    if (_line) {
        CFRelease(_line);
    }
	
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
    
    NSDictionary *attributedDict = ((LMCoreTextRun*)[_coretextRuns lastObject]).attributes;
    
    return [attributedDict paragraphStyle];
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

#pragma mark - Properties
- (NSArray *)glyphRuns
{
    @synchronized(self)
    {
        if (!_coretextRuns)
        {
            // run array is owned by line
            CFArrayRef runs = CTLineGetGlyphRuns(_line);
            CFIndex runCount = CFArrayGetCount(runs);
            
            if (runCount)
            {
                NSMutableArray *tmpArray = [[NSMutableArray alloc] initWithCapacity:runCount];
                
                for (CFIndex i=0; i<runCount; i++)
                {
                    CTRunRef oneRun = CFArrayGetValueAtIndex(runs, i);
                    
                    CGPoint *positions = (CGPoint*)CTRunGetPositionsPtr(oneRun);
                    
                    BOOL shouldFreePositions = NO;
                    
                    if (positions == NULL) // Ptr gave NULL, we'll need to copy positions array and later free it
                    {
                        CFIndex glyphCount = CTRunGetGlyphCount(oneRun);
                        
                        shouldFreePositions = YES;
                        
                        size_t positionsBufferSize = sizeof(CGPoint) * glyphCount;
                        CGPoint *positionsBuffer = malloc(positionsBufferSize);
                        CTRunGetPositions(oneRun, CFRangeMake(0, 0), positionsBuffer);
                        positions = positionsBuffer;
                    }
                    
                    // assumption: position of first glyph is also the correct offset of the entire run
                    CGPoint position = positions[0];
                    
                    LMCoreTextRun *runs = [[LMCoreTextRun alloc] initWithRun:oneRun  offset:position.x];
                    [tmpArray addObject:runs];
                    
                    if ( shouldFreePositions )
                    {
                        free(positions);
                    }
                }
                
                _coretextRuns = tmpArray;
            }
        }
        
        return _coretextRuns;
    }
}

@synthesize frame =_frame;

@synthesize ascent = _ascent;
@synthesize descent = _descent;

@synthesize paragraphStyle = _paragraphStyle;
@synthesize baselineOrigin = _baselineOrigin;


@end
