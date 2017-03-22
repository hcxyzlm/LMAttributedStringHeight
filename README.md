# LMAttributedStringHeight
自动计算富文本的所占的高度
自动计算富文本的高度，使用了coretext的来计算每一行富文本所占的高度和宽度，可以取得富文本每一行的ctline，每一行文本的范围
使用方法：
1.  LMCoreTextFrameLayout *coreTextLayoutFrame = [[LMCoreTextFrameLayout alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,CGFLOAT_HEIGHT_UNKNOWN) attributedString:str];
    coreTextLayoutFrame.numberOfLines = 0;
    [coreTextLayoutFrame buildLines];
    
    CGFLOAT_HEIGHT_UNKNOWN为不确定高度
    
   self.attributedLab.frame = CGRectMake(0, 50, self.view.frame.size.width, coreTextLayoutFrame.frame.size.height);
   自动计算富文本的高度
