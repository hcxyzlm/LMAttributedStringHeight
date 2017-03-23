//
//  ViewController.m
//  LMAttributedStringHeight
//
//  Created by zhuo on 2017/3/22.
//  Copyright © 2017年 zhuo. All rights reserved.
//

#import "ViewController.h"
#import "LMCoreTextFrameLayout.h"
#import "LMCoreTextLayoutLine.h"

@interface ViewController ()

@property (nonatomic, strong) UILabel *attributedLab;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.attributedLab = [[UILabel alloc] init];
    self.attributedLab.font = [UIFont systemFontOfSize:14];
    self.attributedLab.numberOfLines = 0;
    self.attributedLab.lineBreakMode = NSLineBreakByTruncatingTail;
    
    
    [self.view addSubview:self.attributedLab];
    
    [self createAttributedLab];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)createAttributedLab {
    
    
    NSString *desc = @"我们的身体是一座流动房子，不但装满粮食和文字，更装满了灵魂和爱欲，用以抵抗消亡。英国《卫报》评其为“中国具潜力作者”， 一部经得起反复阅读的小说。\
    \
    【内容简介】\
    《你家有龙多少回》是孙一圣首部中短篇小说集，共12篇作品。题材有现实罪案，有魔幻传奇。他以奇特的想象力，精妙的结构，硬冷而古雅的语言，构建了一个个迷一样的故事。他的作品常以严密的逻辑打破日常的认知与空间，以不可能为可能，具有强烈而奇幻的真实感，形成瑰丽的故事世界。在每一个可能的分差小径，你可能都会发现他布下的一个陷阱或是冰山下的世界。\
    不论是《猴者》中成为猴子的父亲，《死者》中死在了纸上的孙世平，还是《因父之名》中的强奸犯，《恶龙》的去往远方的青年，那些隐藏在叙事下的意味，是顺理成章的出其不意，更是个人与世界的对抗。\
    \
    作者在后记中这么说：\
    龙不是神话传说里的，也不是我们想象出来的。你看这茫茫麦田，一垄一垄麦子跑过去，再回来，金碧辉煌，麦穗灿若鳞片。“垄”字怎么写？土字头上一条龙。这龙是我们一垄一垄种出来的，种出了土地的脊梁，我们收割的也不是麦子，而是龙。由此，我们的书名定为《你家有龙多少回》。\
    \
    【作者简介】\
    孙一圣，85后，山东菏泽人，现居北京。\
    有小说发在《上海文学》《人民文学》《文艺风赏》《天南》（已停刊）等杂志。还有若干小说译成英文发在美国的《WordsWithoutBorders（文字无国界）》、《AsymptoteJournal（渐近线）》、《人民文学》英文版《PATHLIGHT(路灯)》等杂志。曾获得“2015年紫金·人民文学之星奖”、“南方日报月度作家”等。";
    
    
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:desc attributes:[self attributesForText]];
    
    LMCoreTextFrameLayout *coreTextLayoutFrame = [[LMCoreTextFrameLayout alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,CGFLOAT_HEIGHT_UNKNOWN) attributedString:str];
    coreTextLayoutFrame.numberOfLines = 0;
    [coreTextLayoutFrame buildLines];
    
    // 取得长度
    
    self.attributedLab.attributedText = str;
    
    self.attributedLab.frame = CGRectMake(0, 50, self.view.frame.size.width, CGRectGetHeight(coreTextLayoutFrame.frame));
    
    
}

- (NSDictionary *)attributesForText {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    
    paragraphStyle.minimumLineHeight = 17;
    
    return @{NSFontAttributeName : [UIFont systemFontOfSize:14],
             (NSString *)kCTParagraphStyleAttributeName : paragraphStyle,
             NSForegroundColorAttributeName: [UIColor blackColor]};
}


@end
