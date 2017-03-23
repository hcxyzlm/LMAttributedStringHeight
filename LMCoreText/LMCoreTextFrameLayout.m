//
//  LMCoreTextFrameLayout.m
//  LMAttributedStringHeight
//
//  Created by zhuo on 2017/3/22.
//  Copyright © 2017年 zhuo. All rights reserved.

#import "LMCoreTextFrameLayout.h"
#import "LMCoreTextLayoutLine.h"

BOOL isLinesEqual(CTLineRef line1, CTLineRef line2)
{
    if(line1 == nil || line2 == nil) {
        return NO;
    }
    
    CFArrayRef glyphRuns1 = CTLineGetGlyphRuns(line1);
    CFArrayRef glyphRuns2 = CTLineGetGlyphRuns(line2);
    CFIndex runCount1 = CFArrayGetCount(glyphRuns1), runCount2 = CFArrayGetCount(glyphRuns2);
    
    if (runCount1 != runCount2)
        return NO;
    
    for (CFIndex i = 0; i < runCount1; i++)
    {
        CTRunRef run1 = CFArrayGetValueAtIndex(glyphRuns1, i);
        CTRunRef run2 = CFArrayGetValueAtIndex(glyphRuns2, i);
        
        CFIndex countInRun1 = CTRunGetGlyphCount(run1), countInRun2 = CTRunGetGlyphCount(run2);
        if (countInRun1 != countInRun2)
            return NO;
        
        const CGGlyph* constGlyphs1 = CTRunGetGlyphsPtr(run1);
        CGGlyph* glyphs1 = NULL;
        if (constGlyphs1 == NULL)
        {
            glyphs1 = (CGGlyph*)malloc(countInRun1*sizeof(CGGlyph));
            CTRunGetGlyphs(run1, CFRangeMake(0, countInRun1), glyphs1);
            constGlyphs1 = glyphs1;
        }
        
        const CGGlyph* constGlyphs2 = CTRunGetGlyphsPtr(run2);
        CGGlyph* glyphs2 = NULL;
        if (constGlyphs2 == NULL)
        {
            glyphs2 = (CGGlyph*)malloc(countInRun2*sizeof(CGGlyph));
            CTRunGetGlyphs(run2, CFRangeMake(0, countInRun2), glyphs2);
            constGlyphs2 = glyphs2;
        }
        
        BOOL result = YES;
        for (CFIndex j = 0; j < countInRun1; j++)
        {
            if (constGlyphs1[j] != constGlyphs2[j])
            {
                result = NO;
                break;
            }
        }
        
        if (glyphs1 != NULL)
            free(glyphs1);
        
        if (glyphs2 != NULL)
            free(glyphs2);
        
        if (!result)
            return NO;
    }
    
    return YES;
}

CFIndex getTruncationWithIndex(CTLineRef line, CTLineRef trunc)
{
    if (line == nil || trunc == nil) return 0;
    
    CFIndex truncCount = CFArrayGetCount(CTLineGetGlyphRuns(trunc));
    
    CFArrayRef lineRuns = CTLineGetGlyphRuns(line);
    CFIndex lineRunsCount = CFArrayGetCount(lineRuns);
    
    CFIndex index = lineRunsCount - truncCount - 1;
    
    // If the index is negative, CFArrayGetValueAtIndex will crash on iOS 10 beta.
    // We will just return 0 because on iOS 9, CFArrayGetValueAtIndex would have
    // returned nil anyways and the return truncation index would be 0.
    // Apple might have enabled an assert that only appears in the iOS 10 beta
    // release, but we will just avoid passing invalid arguments just to be safe.
    if (index < 0)
    {
        return 0;
    }
    else
    {
        CTRunRef lineLastRun = CFArrayGetValueAtIndex(lineRuns, index);
        
        CFRange lastRunRange = CTRunGetStringRange(lineLastRun);
        
        return lastRunRange.location = lastRunRange.length;
    }
}


@implementation LMCoreTextFrameLayout
{
	CTFrameRef _textFrame;
	CTFramesetterRef _framesetter;
	
	NSRange _requestedStringRange;
	NSRange _stringRange;
    
	NSInteger _numberLinesFitInFrame;
    
    NSArray *_paragraphRanges;
	
	CGFloat _longestLayoutLineWidth;
}

// makes a frame for a specific part of the attributed string of the layouter
- (id)initWithFrame:(CGRect)frame attributedString:(NSAttributedString *)attributedString range:(NSRange)range
{
	self = [super init];
	
	if (self)
	{
		_frame = frame;
		
		_attributedStringFragment = [attributedString mutableCopy];
		
		// determine correct target range
		_requestedStringRange = range;
		NSUInteger stringLength = [_attributedStringFragment length];
		
		if (_requestedStringRange.location >= stringLength)
		{
			return nil;
		}
		
		if (_requestedStringRange.length==0 || NSMaxRange(_requestedStringRange) > stringLength)
		{
			_requestedStringRange.length = stringLength - _requestedStringRange.location;
		}
		
		CFRange cfRange = CFRangeMake(_requestedStringRange.location, _requestedStringRange.length);
        
		_framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)_attributedStringFragment);
		
		if (_framesetter)
		{
			CFRetain(_framesetter);
			
			CGMutablePathRef path = CGPathCreateMutable();
			CGPathAddRect(path, NULL, frame);
			
			_textFrame = CTFramesetterCreateFrame(_framesetter, cfRange, path, NULL);
			
			CGPathRelease(path);
		}
		else
		{
			// Strange, should have gotten a valid framesetter
			return nil;
		}
		
	}
	
	return self;
}

// makes a frame for the entire attributed string of the layouter
- (id)initWithFrame:(CGRect)frame attributedString:(NSAttributedString *)attributedString
{
    return [self initWithFrame:frame attributedString:attributedString range:NSMakeRange(0,0)];
}

- (void)dealloc
{
	if (_textFrame)
	{
		CFRelease(_textFrame);
	}
	
	if (_framesetter)
	{
		CFRelease(_framesetter);
	}
}

// exclude method from coverage testing

- (NSString *)description
{
	return [self.lines description];
}


// determines the "half leading"
- (CGFloat)_algorithmWebKit_halfLeadingOfLine:(LMCoreTextLayoutLine *)line
{
    CGFloat maxFontSize = [line lineHeight];
    
    NSParagraphStyle *paragraphStyle = [line paragraphStyle];
    
    if (paragraphStyle.minimumLineHeight != 0 && paragraphStyle.minimumLineHeight > maxFontSize)
    {
        maxFontSize = paragraphStyle.minimumLineHeight;
    }
    
    if (paragraphStyle.maximumLineHeight != 0 && paragraphStyle.maximumLineHeight < maxFontSize)
    {
        maxFontSize = paragraphStyle.maximumLineHeight;
    }
    
    CGFloat leading;
    
    if (paragraphStyle.lineHeightMultiple > 0)
    {
        leading = maxFontSize * paragraphStyle.lineHeightMultiple;
    }
    else
    {
        // reasonable "normal"
        leading = maxFontSize * 1.1f;
    }
    
    // subtract inline box height
    CGFloat inlineBoxHeight = line.ascent + line.descent;
    
    return (leading - inlineBoxHeight)/2.0f;
}

- (CGPoint)_algorithmWebKit_BaselineOriginToPositionLine:(LMCoreTextLayoutLine *)line afterLine:(LMCoreTextLayoutLine *)previousLine
{
    CGPoint baselineOrigin = previousLine.baselineOrigin;
    
    if (previousLine)
    {
        baselineOrigin.y = CGRectGetMaxY(previousLine.frame);
        
        CGFloat halfLeadingFromText = [self _algorithmWebKit_halfLeadingOfLine:previousLine];
        
        
        baselineOrigin.y += halfLeadingFromText;
        
        // add previous line's after paragraph spacing
        if ([self isLineLastInParagraph:previousLine])
        {
            NSParagraphStyle *paragraphStyle = [previousLine paragraphStyle];
            baselineOrigin.y += paragraphStyle.paragraphSpacing;
        }
    }
    else
    {
        // first line in frame
        baselineOrigin = _frame.origin;
    }
    
    baselineOrigin.y += line.ascent;
    
    CGFloat halfLeadingFromText = [self _algorithmWebKit_halfLeadingOfLine:line];
    
    baselineOrigin.y += halfLeadingFromText;
    
    NSParagraphStyle *paragraphStyle = [line paragraphStyle];
    
    // add current line's before paragraph spacing
    if ([self isLineFirstInParagraph:line])
    {
        baselineOrigin.y += paragraphStyle.paragraphSpacingBefore;
    }
    
    // origins are rounded
    baselineOrigin.y = ceil(baselineOrigin.y);
    
    return baselineOrigin;
}

// returns YES if the given line is the last in a paragraph
- (BOOL)isLineLastInParagraph:(LMCoreTextLayoutLine *)line
{
    NSString *lineString = [[_attributedStringFragment string] substringWithRange:line.stringRange];
    
    if ([lineString hasSuffix:@"\n"])
    {
        return YES;
    }
    
    return NO;
}

// returns YES if the given line is the first in a paragraph
- (BOOL)isLineFirstInParagraph:(LMCoreTextLayoutLine *)line
{
    NSRange lineRange = line.stringRange;
    
    if (lineRange.location == 0)
    {
        return YES;
    }
    
    NSInteger prevLineLastUnicharIndex =lineRange.location - 1;
    unichar prevLineLastUnichar = [[_attributedStringFragment string] characterAtIndex:prevLineLastUnicharIndex];
    
    return [[NSCharacterSet newlineCharacterSet] characterIsMember:prevLineLastUnichar];
}

- (LMCoreTextLayoutLine *)lineContainingIndex:(NSUInteger)index {
    
    if (index <= self.lines.count -1) {
        return [self.lines objectAtIndex:index];
    }
    return nil;
}
- (NSArray *)paragraphRanges
{
    if (!_paragraphRanges)
    {
        NSString *plainString = [[self attributedStringFragment] string];
        NSUInteger length = [plainString length];
        
        NSRange paragraphRange = [self rangeOfParagraphsContaining:plainString range:NSMakeRange(0, 0) parBegIndex:NULL parEndIndex:NULL];
        
        NSMutableArray *tmpArray = [NSMutableArray array];
        
        while (paragraphRange.length)
        {
            NSValue *value = [NSValue valueWithRange:paragraphRange];
            [tmpArray addObject:value];
            
            NSUInteger nextParagraphBegin = NSMaxRange(paragraphRange);
            
            if (nextParagraphBegin>=length)
            {
                break;
            }
            
            // next paragraph
            paragraphRange = [self rangeOfParagraphsContaining:plainString range:NSMakeRange(nextParagraphBegin, 0) parBegIndex:NULL parEndIndex:NULL];
        }
        
        _paragraphRanges = tmpArray; // no copy for performance
    }
    
    return _paragraphRanges;
}

- (NSRange)rangeOfParagraphsContaining:(NSString *)string range:(NSRange)range parBegIndex:(NSUInteger *)parBegIndex parEndIndex:(NSUInteger *)parEndIndex
{
    // get beginning and end of paragraph containing the replaced range
    CFIndex beginIndex;
    CFIndex endIndex;
    
    CFStringGetParagraphBounds((__bridge CFStringRef)string, CFRangeMake(range.location, range.length), &beginIndex, &endIndex, NULL);
    
    if (parBegIndex)
    {
        *parBegIndex = beginIndex;
    }
    
    if (parEndIndex)
    {
        *parEndIndex = endIndex;
    }
    
    // endIndex is the first character of the following paragraph, so we don't need to add 1
    
    return NSMakeRange(beginIndex, endIndex - beginIndex);
}

#pragma mark - Building the Lines

/*
 Builds the array of lines with the internal typesetter of our framesetter. No need to correct line origins in this case because they are placed correctly in the first place. This version supports text boxes.
 */
- (void)_buildLinesWithTypesetter
{
	// framesetter keeps internal reference, no need to retain
	CTTypesetterRef typesetter = CTFramesetterGetTypesetter(_framesetter);
	
	NSMutableArray *typesetLines = [NSMutableArray array];
	
	LMCoreTextLayoutLine *previousLine = nil;
	
	// need the paragraph ranges to know if a line is at the beginning of paragraph
	NSMutableArray *paragraphRanges = [[self paragraphRanges] mutableCopy];
	
	NSRange currentParagraphRange = [[paragraphRanges objectAtIndex:0] rangeValue];
	
	// we start out in the requested range, length will be set by the suggested line break function
	NSRange lineRange = _requestedStringRange;
	
	// maximum values for abort of loop
	CGFloat maxY = CGRectGetMaxY(_frame);
	NSUInteger maxIndex = NSMaxRange(_requestedStringRange);
	NSUInteger fittingLength = 0;
	BOOL shouldTruncateLine = NO;
	
	do  // for each line
	{
		while (lineRange.location >= (currentParagraphRange.location+currentParagraphRange.length))
		{
			// we are outside of this paragraph, so we go to the next
			[paragraphRanges removeObjectAtIndex:0];
			
			currentParagraphRange = [[paragraphRanges objectAtIndex:0] rangeValue];
		}
		
		BOOL isAtBeginOfParagraph = (currentParagraphRange.location == lineRange.location);
		
		CGFloat headIndent = 0;
		CGFloat tailIndent = 0;
		
		// get the paragraph style at this index
		CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)[_attributedStringFragment attribute:(id)kCTParagraphStyleAttributeName atIndex:lineRange.location effectiveRange:NULL];
		
		if (isAtBeginOfParagraph)
		{
			CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(headIndent), &headIndent);
		}
		else
		{
			CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierHeadIndent, sizeof(headIndent), &headIndent);
		}
		
		CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierTailIndent, sizeof(tailIndent), &tailIndent);
		
		// add left padding to offset
		CGFloat lineOriginX;
		CGFloat availableSpace;
		
		CGFloat totalLeftPadding = 0;
		CGFloat totalRightPadding = 0;
		
		if (tailIndent<=0)
		{
			// negative tail indent is measured from trailing margin (we assume LTR here)
			availableSpace = _frame.size.width - headIndent - totalRightPadding + tailIndent - totalLeftPadding;
		}
		else
		{
			availableSpace = tailIndent - headIndent - totalLeftPadding - totalRightPadding;
		}
		
		
		CGFloat offset = totalLeftPadding;
		
		// if first character is a tab, then it is positioned without the indentation
		if (![[[_attributedStringFragment string] substringWithRange:NSMakeRange(lineRange.location, 1)] isEqualToString:@"\t"])
		{
			offset += headIndent;
		}
		
		// find how many characters we get into this line
		lineRange.length = CTTypesetterSuggestLineBreak(typesetter, lineRange.location, availableSpace);
		
		if (NSMaxRange(lineRange) > maxIndex)
		{
			// only layout as much as was requested
			lineRange.length = maxIndex - lineRange.location;
		}
		
		
		// determine whether this is a normal line or if it should be truncated
		shouldTruncateLine = ((self.numberOfLines>0 && [typesetLines count]+1==self.numberOfLines) || (_numberLinesFitInFrame>0 && _numberLinesFitInFrame==[typesetLines count]+1));
		
		CTLineRef line;
		BOOL isHyphenatedString = NO;
		
		if (!shouldTruncateLine)
		{
			static const unichar softHypen = 0x00AD;
			NSString *lineString = [[_attributedStringFragment attributedSubstringFromRange:lineRange] string];
			unichar lastChar = [lineString characterAtIndex:[lineString length] - 1];
			if (softHypen == lastChar)
			{
				NSMutableAttributedString *hyphenatedString = [[_attributedStringFragment attributedSubstringFromRange:lineRange] mutableCopy];
				NSRange replaceRange = NSMakeRange(hyphenatedString.length - 1, 1);
				[hyphenatedString replaceCharactersInRange:replaceRange withString:@"-"];
				line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)hyphenatedString);
				isHyphenatedString = YES;
			}
			else
			{
				// create a line to fit
				line = CTTypesetterCreateLine(typesetter, CFRangeMake(lineRange.location, lineRange.length));
			}
		}
		else
		{
			// extend the line to the end of the current paragraph
			// if we extend to the entire to the entire text range
			// it is possible to pull lines up from paragraphs below us
			NSRange oldLineRange = lineRange;
			lineRange.length = maxIndex-lineRange.location;
			CTLineRef baseLine = CTTypesetterCreateLine(typesetter, CFRangeMake(lineRange.location, lineRange.length));
			
			// convert lineBreakMode to CoreText type
            CTLineTruncationType truncationType = [self CTLineTruncationTypeFromNSLineBreakMode:self.lineBreakMode];
			
			// prepare truncation string
			NSAttributedString * attribStr = self.truncationString;
			if(attribStr == nil)
			{
				NSRange range;
				NSInteger index = oldLineRange.location;
				if (truncationType == kCTLineTruncationEnd)
				{
					index += (oldLineRange.length > 0 ? oldLineRange.length - 1 : 0);
				}
				else if (truncationType == kCTLineTruncationMiddle)
				{
					index += (oldLineRange.length > 1 ? (oldLineRange.length/2.0 - 1) : 0);
				}
				NSDictionary * attributes = [_attributedStringFragment attributesAtIndex:index effectiveRange:&range];
				attribStr = [[NSAttributedString alloc] initWithString:@"…" attributes:attributes];
			}
			
			CTLineRef elipsisLineRef = CTLineCreateWithAttributedString((__bridge  CFAttributedStringRef)(attribStr));
			
			// create the truncated line
			line = CTLineCreateTruncatedLine(baseLine, availableSpace, truncationType, elipsisLineRef);
            
            // check if truncation occurred
            BOOL truncationOccured = !isLinesEqual(baseLine, line);
            // if yes check was it before the end of the current paragraph or after
            NSUInteger endOfParagraphIndex = NSMaxRange(currentParagraphRange);
            // this works only for truncation at the end
            if (truncationType == kCTLineTruncationEnd)
            {
                if (truncationOccured)
                {
                    CFIndex truncationIndex = getTruncationWithIndex(line, elipsisLineRef);
                    // if truncation occurred after the end of the paragraph
                    // move truncation token to the end of the paragraph
                    if (truncationIndex > endOfParagraphIndex)
                    {
                        NSAttributedString *subStr = [_attributedStringFragment attributedSubstringFromRange:NSMakeRange(lineRange.location, endOfParagraphIndex - lineRange.location - 1)];
                        NSMutableAttributedString *attrMutStr = [subStr mutableCopy];
                        [attrMutStr appendAttributedString:attribStr];
                        CFRelease(line);
                        line = CTLineCreateWithAttributedString((__bridge  CFAttributedStringRef)(attrMutStr));
                    }
                    // otherwise, everything is OK
                }
                else
                {
                    // if no truncation happened, force addition of
                    // the truncation token to the end of the paragraph
                    if (maxIndex != endOfParagraphIndex)
                    {
                        NSAttributedString *subStr = [_attributedStringFragment attributedSubstringFromRange:NSMakeRange(lineRange.location, endOfParagraphIndex - lineRange.location - 1)];
                        NSMutableAttributedString *attrMutStr = [subStr mutableCopy];
                        [attrMutStr appendAttributedString:attribStr];
                        CFRelease(line);
                        line = CTLineCreateWithAttributedString((__bridge  CFAttributedStringRef)(attrMutStr));
                    }
                }
            }
			
			// clean up
			CFRelease(baseLine);
			CFRelease(elipsisLineRef);
		}
		
		// we need all metrics so get the at once
		CGFloat currentLineWidth = (CGFloat)CTLineGetTypographicBounds(line, NULL, NULL, NULL);
		
		// adjust lineOrigin based on paragraph text alignment
		CTTextAlignment textAlignment;
		
		if (!CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierAlignment, sizeof(textAlignment), &textAlignment))
		{
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
			textAlignment = kCTTextAlignmentNatural;
#else
			textAlignment = kCTTextAlignmentNatural;
#endif
		}
		
		// determine writing direction
		BOOL isRTL = NO;
		CTWritingDirection baseWritingDirection;
		
		if (CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(baseWritingDirection), &baseWritingDirection))
		{
			isRTL = (baseWritingDirection == kCTWritingDirectionRightToLeft);
		}
		else
		{
			baseWritingDirection = kCTWritingDirectionNatural;
		}
		
		switch (textAlignment)
		{
				
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
			case kCTTextAlignmentLeft:
#else
			case kCTTextAlignmentLeft:
#endif
			{
				lineOriginX = _frame.origin.x + offset;
				// nothing to do
				break;
			}
				
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
			case kCTTextAlignmentNatural:
#else
			case kCTTextAlignmentNatural:
#endif
			{
				lineOriginX = _frame.origin.x + offset;
				
				if (baseWritingDirection != kCTWritingDirectionRightToLeft)
				{
					break;
				}
				
				// right alignment falls through
			}
				
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
			case kCTTextAlignmentRight:
#else
			case kCTTextAlignmentRight:
#endif
			{
				lineOriginX = _frame.origin.x + offset + (CGFloat)CTLineGetPenOffsetForFlush(line, 1.0, availableSpace);
				
				break;
			}
				
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
			case kCTTextAlignmentCenter:
#else
			case kCTTextAlignmentCenter:
#endif
			{
				lineOriginX = _frame.origin.x + offset + (CGFloat)CTLineGetPenOffsetForFlush(line, 0.5, availableSpace);
				
				break;
			}
				
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
			case kCTTextAlignmentJustified:
#else
			case kCTTextAlignmentJustified:
#endif
			{
				BOOL isAtEndOfParagraph  = (currentParagraphRange.location+currentParagraphRange.length <= lineRange.location+lineRange.length ||
											[[_attributedStringFragment string] characterAtIndex:lineRange.location+lineRange.length-1]==0x2028);
				
				// only justify if not last line, not <br>, and if the line width is longer than _justifyRatio of the frame
				// avoids over-stretching
				if( !isAtEndOfParagraph && (currentLineWidth > 0.6 * _frame.size.width) )
				{
					// create a justified line and replace the current one with it
					CTLineRef justifiedLine = CTLineCreateJustifiedLine(line, 1.0f, availableSpace);
					
					// CTLineCreateJustifiedLine sometimes fails if the line ends with 0x00AD (soft hyphen) and contains cyrillic chars
					if (justifiedLine)
					{
						CFRelease(line);
						line = justifiedLine;
					}
				}
				
				if (isRTL)
				{
					// align line with right margin
					lineOriginX = _frame.origin.x + offset + (CGFloat)CTLineGetPenOffsetForFlush(line, 1.0, availableSpace);
				}
				else
				{
					// align line with left margin
					lineOriginX = _frame.origin.x + offset;
				}
				
				break;
			}
		}
		
		if (!line)
		{
			continue;
		}
		
		// wrap it
		LMCoreTextLayoutLine *newLine = [[LMCoreTextLayoutLine alloc] initWithLine:line
															  stringLocationOffset:isHyphenatedString ? lineRange.location : 0];
		newLine.writingDirectionIsRightToLeft = isRTL;
		CFRelease(line);
		
		// determine position of line based on line before it
		
		CGPoint newLineBaselineOrigin = [self _algorithmWebKit_BaselineOriginToPositionLine:newLine afterLine:previousLine];
        NSLog(@"newLineBaselineOrigin (%f, %f)", newLineBaselineOrigin.x, newLineBaselineOrigin.y);
		newLineBaselineOrigin.x = lineOriginX;
		newLine.baselineOrigin = newLineBaselineOrigin;
		
		// abort layout if we left the configured frame
		CGFloat lineBottom = CGRectGetMaxY(newLine.frame);
		
		// screen bottom last line min padding
		if (lineBottom>maxY)
		{
			if ([typesetLines count] && self.lineBreakMode)
			{
				_numberLinesFitInFrame = [typesetLines count];
				[self _buildLinesWithTypesetter];
				
				return;
			}
			else
			{
				// doesn't fit any more
				break;
			}
		}
		
		[typesetLines addObject:newLine];
		fittingLength += lineRange.length;
		
		lineRange.location += lineRange.length;
		previousLine = newLine;
	}
	while (lineRange.location < maxIndex && !shouldTruncateLine);
	
	_lines = typesetLines;
	
	if (![_lines count])
	{
		// no lines fit
		_stringRange = NSMakeRange(0, 0);
		
		return;
	}
	
	// now we know how many characters fit
	_stringRange.location = _requestedStringRange.location;
	_stringRange.length = fittingLength;
	
}

- (void)buildLines
{
	// only build lines if frame is legal
	if (_frame.size.width<=0)
	{
		return;
	}
	
	// note: building line by line with typesetter
	[self _buildLinesWithTypesetter];
}

- (NSArray *)lines
{
	if (!_lines)
	{
		[self buildLines];
	}
	
	return _lines;
}



// draws the HR represented by the layout line
#pragma mark - Calculations

- (NSRange)visibleStringRange
{
	if (!_textFrame)
	{
		return NSMakeRange(0, 0);
	}
	
	if (!_lines)
	{
		// need to build lines to know range
		[self buildLines];
	}
	
	return _stringRange;
}

- (CGRect)frame
{
	if (!_lines)
	{
		[self buildLines];
	}
	
	if (![self.lines count])
	{
		return CGRectZero;
	}
	
	if (_frame.size.height == CGFLOAT_HEIGHT_UNKNOWN)
	{
		// actual frame is spanned between first and last lines
		LMCoreTextLayoutLine *lastLine = [_lines lastObject];
		
		_frame.size.height = ceil(CGRectGetMaxY(lastLine.frame) - _frame.origin.y + 1.5f);
	}
	
	if (_frame.size.width == CGFLOAT_WIDTH_UNKNOWN)
	{
		// actual frame width is maximum value of lines
		CGFloat maxWidth = 0;
		
		for (LMCoreTextLayoutLine *oneLine in _lines)
		{
			CGFloat lineWidthFromFrameOrigin = CGRectGetMaxX(oneLine.frame) - _frame.origin.x;
			maxWidth = MAX(maxWidth, lineWidthFromFrameOrigin);
		}
		
		_frame.size.width = ceil(maxWidth);
	}
	
	return _frame;
}

- (NSAttributedString *)attributedStringFragment
{
	return _attributedStringFragment;
}

- (void)setAttributedStringFragment:(NSAttributedString *) attar {
 
    _attributedStringFragment = attar;
}

- (void)setNumberOfLines:(NSInteger)numberOfLines
{
    if( _numberOfLines != numberOfLines )
	{
		_numberOfLines = numberOfLines;
        // clear lines cache
        _lines = nil;
    }
}

- (void)setLineBreakMode:(NSLineBreakMode)lineBreakMode
{
    if( _lineBreakMode != lineBreakMode )
	{
        _lineBreakMode = lineBreakMode;
        // clear lines cache
        _lines = nil;
    }
}

- (void)setTruncationString:(NSAttributedString *)truncationString
{
    if( ![_truncationString isEqualToAttributedString:truncationString] )
	{
        _truncationString = truncationString;
		
        if( self.numberOfLines > 0 )
		{
            // clear lines cache
            _lines = nil;
        }
    }
}

#pragma -mark utrl

- (CTLineTruncationType)CTLineTruncationTypeFromNSLineBreakMode:(NSLineBreakMode)lineBreakMode
{
#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
    switch (lineBreakMode)
    {
        case UILineBreakModeHeadTruncation:
            return kCTLineTruncationStart;
            
        case UILineBreakModeMiddleTruncation:
            return kCTLineTruncationMiddle;
            
        default:
            return kCTLineTruncationEnd;
    }
#else
    switch (lineBreakMode)
    {
        case NSLineBreakByTruncatingHead:
            return kCTLineTruncationStart;
            
        case NSLineBreakByTruncatingMiddle:
            return kCTLineTruncationMiddle;
            
        default:
            return kCTLineTruncationEnd;
    }
#endif
}




@synthesize numberOfLines = _numberOfLines;
@synthesize lineBreakMode = _lineBreakMode;
@synthesize truncationString = _truncationString;
@synthesize frame = _frame;
@synthesize lines = _lines;

@end
