//
//  CCSSlipStickChart.m
//  CocoaChartsSample
//
//  Created by limc on 11/21/13.
//  Copyright (c) 2013 limc. All rights reserved.
//

#import "CCSSlipStickChart.h"
#import "CCSStickChartData.h"

@interface  CCSSlipStickChart () {
    CCFloat _startDistance1;
    CCFloat _minDistance1;
    CCFloat _doubleTouchInterval;
    CCInt _flag;
    CCFloat _firstX;
    
    
    BOOL _isLongPress;
    BOOL _isMoved;
    BOOL _waitForLongPress;
    
    CGPoint _firstTouchPoint;
}
@end

@implementation CCSSlipStickChart
@synthesize displayNumber = _displayNumber;
@synthesize displayFrom = _displayFrom;
@synthesize minDisplayNumber = _minDisplayNumber;
@synthesize maxDisplayNumber = _maxDisplayNumber;
//@synthesize zoomBaseLine = _zoomBaseLine;
@synthesize maxDisplayNumberToLine = _maxDisplayNumberToLine;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _startDistance1 = 0;
        _minDistance1 = 8;
        _doubleTouchInterval = 100;
        _flag = 1;
        _firstX = 0;
        
        
         _isLongPress = NO;
         _isMoved = NO;
         _waitForLongPress = NO;

    }
    return self;
}

- (void)initProperty {
    //初始化父类的熟悉
    [super initProperty];

    self.displayFrom = 0;
    self.displayNumber = 20;
    self.minDisplayNumber = 20;
    self.maxDisplayNumber = 20;
//    self.zoomBaseLine = CCSStickZoomBaseLineCenter;
    self.maxDisplayNumberToLine = 120;
}

- (void)calcDataValueRange {
    if (self.displayNumber <=0) {
        return;
    }
    CCFloat maxValue = 0;
    CCFloat minValue = CCIntMax;

//    CCSStickChartData *first = [self.stickData objectAtIndex:self.displayFrom];
//    //第一个stick为停盘的情况
//    if (first.high == 0 && first.low == 0) {
//
//    } else {
//        maxValue = first.high;
//        minValue = first.low;
//    }

    //判断显示为方柱或显示为线条
    for (CCUInt i = self.displayFrom; i < [self getDisplayTo]; i++) {
        CCSStickChartData *stick = [self.stickData objectAtIndex:i];
        if (stick.low < minValue) {
            minValue = stick.low;
        }

        if (stick.high > maxValue) {
            maxValue = stick.high;
        }

    }

    self.maxValue = maxValue;
    self.minValue = minValue;
}

- (void)initAxisX {
    NSMutableArray *TitleX = [[NSMutableArray alloc] init];
    if (self.stickData != NULL && [self.stickData count] > 0 && self.displayNumber > 0) {
        CCFloat average = [self getDataDisplayNumber] / self.longitudeNum;
        CCSStickChartData *chartdata = nil;
        if (self.axisYPosition == CCSGridChartYAxisPositionLeft) {
            //处理刻度
            for (CCUInt i = 0; i < self.longitudeNum; i++) {
                CCUInt index = self.displayFrom + (CCUInt) floor(i * average);
                if (index > [self getDisplayTo] - 1) {
                    index = [self getDisplayTo] - 1;
                }
                chartdata = [self.stickData objectAtIndex:index];
                //追加标题
                [TitleX addObject:[NSString stringWithFormat:@"%@", chartdata.date]];
            }
            chartdata = [self.stickData objectAtIndex:[self getDisplayTo] - 1];
            //追加标题
            [TitleX addObject:[NSString stringWithFormat:@"%@", chartdata.date]];
        }
        else {
            //处理刻度
            for (CCUInt i = 0; i < self.longitudeNum; i++) {
                CCUInt index = self.displayFrom + (CCUInt) floor(i * average);
                if (index > [self getDisplayTo] - 1) {
                    index = [self getDisplayTo] - 1;
                }
                chartdata = [self.stickData objectAtIndex:index];
                //追加标题
                [TitleX addObject:[NSString stringWithFormat:@"%@", chartdata.date]];
            }
            chartdata = [self.stickData objectAtIndex:[self getDisplayTo] - 1];
            //追加标题
            [TitleX addObject:[NSString stringWithFormat:@"%@", chartdata.date]];
        }

    }
    self.longitudeTitles = TitleX;
}

- (void)initAxisY {
    //计算取值范围
    [self calcValueRange];

    if (self.maxValue == 0. && self.minValue == 0.) {
        self.latitudeTitles = nil;
        return;
    }

    NSMutableArray *TitleY = [[NSMutableArray alloc] init];
    CCFloat average = (CCUInt) ((self.maxValue - self.minValue) / self.latitudeNum);
    //处理刻度
    for (CCUInt i = 0; i < self.latitudeNum; i++) {
        if (self.axisCalc == 1) {
            CCUInt degree = floor(self.minValue + i * average) / self.axisCalc;
            NSString *value = [[NSNumber numberWithUnsignedInteger:degree]stringValue];
            [TitleY addObject:value];
        } else {
            NSString *value = [NSString stringWithFormat:@"%-.2f", floor(self.minValue + i * average) / self.axisCalc];
            [TitleY addObject:value];
        }
    }
    //处理最大值
    if (self.axisCalc == 1) {
        CCUInt degree = (CCInt) (self.maxValue) / self.axisCalc;
        NSString *value = [[NSNumber numberWithUnsignedInteger:degree]stringValue];
        [TitleY addObject:value];
    }
    else {
        NSString *value = [NSString stringWithFormat:@"%-.2f", (self.maxValue) / self.axisCalc];
        [TitleY addObject:value];
    }

    self.latitudeTitles = TitleY;
}

- (NSString *)calcAxisXGraduate:(CGRect)rect {
    CCFloat value = [self touchPointAxisXValue:rect];
    NSString *result = @"";
    if (self.stickData != NULL && [self.stickData count] > 0) {
//        if (self.axisYPosition == CCSGridChartYAxisPositionLeft) {
            if (value >= 1) {
                result = ((CCSStickChartData *) [self.stickData objectAtIndex:[self getDisplayTo] - 1]).date;
            } else if (value <= 0) {
                result = ((CCSStickChartData *) [self.stickData objectAtIndex:self.displayFrom]).date;
            } else {
                CCUInt index = self.displayFrom + (CCUInt) (self.displayNumber * value);
                if (index > [self getDisplayTo] - 1) {
                    index = [self getDisplayTo] - 1;
                }
                result = ((CCSStickChartData *) [self.stickData objectAtIndex:index]).date;
            }
//        } else {
//            if (value >= 1) {
//                result = ((CCSStickChartData *) [self.stickData objectAtIndex:[self getDisplayTo] - 1]).date;
//            } else if (value <= 0) {
//                result = ((CCSStickChartData *) [self.stickData objectAtIndex:self.displayFrom]).date;
//            } else {
//                CCUInt index = self.displayFrom + (CCUInt) (self.displayNumber * value);
//                if (index > [self getDisplayTo] - 1) {
//                    index = [self getDisplayTo] - 1;
//                }
//                result = ((CCSStickChartData *) [self.stickData objectAtIndex:index]).date;
//            }
//        }
    }
    return result;
}


- (void) changeLongPressState:(BOOL)state {
    _waitForLongPress = NO;
    
    if (_isLongPress == NO) {
        _isLongPress = YES;
        
        self.displayCrossXOnTouch = NO;
        self.displayCrossYOnTouch = NO;
        //获取选中点
        self.singleTouchPoint = _firstTouchPoint;
        [self setNeedsDisplay];
        
    }else{
        self.displayCrossXOnTouch = YES;
        self.displayCrossYOnTouch = YES;
        [self setNeedsDisplay];
    }
    
    [self canPerformAction:@selector(changeLongPressState:) withSender:nil];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {


    NSArray *allTouches = [touches allObjects];
    //处理点击事件
    if ([allTouches count] == 1) {
        CGPoint pt1 = [[allTouches objectAtIndex:0] locationInView:self];

        
        self.displayCrossXOnTouch = NO;
        self.displayCrossYOnTouch = NO;
        
         _firstX = pt1.x;
        
        _firstTouchPoint = pt1;
        
        _isLongPress = NO;
        _isMoved = NO;
        _waitForLongPress = YES;
        [self performSelector:@selector(changeLongPressState:) withObject:nil afterDelay:0.5];

        
//        if (_flag == 0) {
//            _firstX = pt1.x;
//            
//        } else {
//            if (fabs(pt1.x - self.singleTouchPoint.x) < 10) {
//                self.displayCrossXOnTouch = NO;
//                self.displayCrossYOnTouch = NO;
//                [self setNeedsDisplay];
//                self.singleTouchPoint = CGPointZero;
//                _flag = 0;
//
//            } else {
//                //获取选中点
//                self.singleTouchPoint = [[allTouches objectAtIndex:0] locationInView:self];
//                //重绘
//                self.displayCrossXOnTouch = YES;
//                self.displayCrossYOnTouch = YES;
//                [self setNeedsDisplay];
//
//                _flag = 1;
//            }
//        }

    } else if ([allTouches count] == 2) {
        self.displayCrossXOnTouch = NO;
        self.displayCrossYOnTouch = NO;
        
        CGPoint pt1 = [[allTouches objectAtIndex:0] locationInView:self];
        CGPoint pt2 = [[allTouches objectAtIndex:1] locationInView:self];

        _startDistance1 = fabs(pt1.x - pt2.x);
    } else {

    }
    
    //调用父类的触摸事件
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {


    NSArray *allTouches = [touches allObjects];
    //处理点击事件
    if ([allTouches count] == 1) {
        
        
        CGPoint pt1 = [[allTouches objectAtIndex:0] locationInView:self];
        
        if (_isLongPress == NO) {
            if (fabs(pt1.x - _firstTouchPoint.x) < 4) {
                //            _firstX = pt1.x;
                if (_waitForLongPress) {
                    NSLog(@"Waiting for LongPress");
                }else{
                    _isLongPress = YES;
                    NSLog(@"LongPress");
                }
            }else{
                NSLog(@"Moved");
//                _firstX = pt1.x;
                _waitForLongPress = NO;
                _isMoved = YES;
                [self canPerformAction:@selector(changeLongPressState:) withSender:nil];
                //            _isLongPress = NO;
            }
            self.displayCrossXOnTouch = NO;
            self.displayCrossYOnTouch = NO;
            [self setNeedsDisplay];
            
        }else if(_isMoved == NO){
            self.displayCrossXOnTouch = YES;
            self.displayCrossYOnTouch = YES;
            [self setNeedsDisplay];

        }
        
        if (_isMoved) {
            
            self.displayCrossXOnTouch = NO;
            self.displayCrossYOnTouch = NO;
            
            CGPoint pt1 = [[allTouches objectAtIndex:0] locationInView:self];
            CCFloat stickWidth = [self getDataStickWidth];

            if (pt1.x - _firstX > stickWidth) {
                [self moveLeft];
            } else if (pt1.x - _firstX < -stickWidth) {
                [self moveRight];
            }

            
            _firstX = pt1.x;
            
            //获取选中点
            self.singleTouchPoint = [[allTouches objectAtIndex:0] locationInView:self];
            
            [self setNeedsDisplay];
            
            //设置可滚动
            //[self performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:0];

//            if (self.coChart) {
//                ((CCSSlipStickChart *)self.coChart).displayFrom = self.displayFrom;
//                ((CCSSlipStickChart *)self.coChart).displayNumber = self.displayNumber;
//                [self.coChart setNeedsDisplay];
//            }

        }
        
        
//        if (_flag == 0) {
////            CGPoint pt1 = [[allTouches objectAtIndex:0] locationInView:self];
////            CCFloat stickWidth = ((self.frame.size.width - self.axisMarginLeft - self.axisMarginRight) / self.displayNumber) - 1;
////
////            
////            if (_isLongPress) {
////                if (pt1.x - _firstX < 15) {
////                    NSLog(@"LongPress");
////                }
////            }
////            
////            if (pt1.x - _firstX > stickWidth) {
////                if (self.displayFrom > 2) {
////                    self.displayFrom = self.displayFrom - 2;
////                }
////            } else if (pt1.x - _firstX < -stickWidth) {
////                if ([self getDisplayTo] + 2 < [self.stickData count]) {
////                    self.displayFrom = self.displayFrom + 2;
////                }
////            }
////
////            _firstX = pt1.x;
////
////            [self setNeedsDisplay];
////            //设置可滚动
////            //[self performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:0];
////            
////            if (self.coChart) {
////                ((CCSSlipStickChart *)self.coChart).displayFrom = self.displayFrom;
////                ((CCSSlipStickChart *)self.coChart).displayNumber = self.displayNumber;
////                [self.coChart setNeedsDisplay];
////            }
//        } else {
//            //获取选中点
//            self.singleTouchPoint = [[allTouches objectAtIndex:0] locationInView:self];
//            //设置可滚动
//            //[self performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:0];
//            [self setNeedsDisplay];
//        }
        //        }
    } else if ([allTouches count] == 2) {
        //限制为单指十字线
        if (self.displayCrossXOnTouch == YES && self.displayCrossYOnTouch == YES) {
            self.displayCrossXOnTouch = NO;
            self.displayCrossYOnTouch = NO;
            
            [self setNeedsDisplay];
        }
        
        CGPoint pt1 = [[allTouches objectAtIndex:0] locationInView:self];
        CGPoint pt2 = [[allTouches objectAtIndex:1] locationInView:self];

        CCFloat endDistance = fabs(pt1.x - pt2.x);
        //放大
        if (endDistance - _startDistance1 > _minDistance1) {
            [self zoomOut];
            _startDistance1 = endDistance;

            [self setNeedsDisplay];
        } else if (endDistance - _startDistance1 < -_minDistance1) {
            [self zoomIn];
            _startDistance1 = endDistance;

            [self setNeedsDisplay];
        }

    } else {
        //限制为单指十字线
        if (self.displayCrossXOnTouch == YES && self.displayCrossYOnTouch == YES) {
            self.displayCrossXOnTouch = NO;
            self.displayCrossYOnTouch = NO;
            
            [self setNeedsDisplay];
        }
    }
    
    //调用父类的触摸事件
    [super touchesMoved:touches withEvent:event];

}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    //调用父类的触摸事件
    [super touchesEnded:touches withEvent:event];
    
    [self canPerformAction:@selector(changeLongPressState:) withSender:nil];

    _startDistance1 = 0;

    _flag = 1;
    
    NSLog(@"end");
    _isLongPress = NO;
    _isMoved = NO;
    _waitForLongPress = YES;
    
    self.displayCrossXOnTouch = NO;
    self.displayCrossYOnTouch = NO;
    

    [self setNeedsDisplay];
}


- (void) drawData:(CGRect)rect{
    if (self.displayNumber > self.maxDisplayNumberToLine) {
        [self drawDataAsLine:rect];
    }else{
        //绘制数据
        [self drawSticks:rect];
    }
}

- (void)drawDataAsLine:(CGRect)rect {
    if (self.stickData != NULL && [self.stickData count] > 0) {
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetLineWidth(context, 1.0f);
        CGContextSetAllowsAntialiasing(context, YES);
        CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] CGColor] );
        // 点线距离
        CCFloat lineLength = [self getDataStickWidth ];
        //起始点
        CCFloat startX = super.axisMarginLeft + lineLength / 2;
        
        //遍历并绘制线条
        for (CCUInt j = self.displayFrom; j < [self getDisplayTo]; j++) {
            CCSStickChartData *data = [self.stickData objectAtIndex:j];
            
            
//            CCFloat highY = ((1 - (data.high - self.minValue) / (self.maxValue - self.minValue)) * (rect.size.height - self.axisMarginBottom) - self.axisMarginTop);
            
            CCFloat highY = [self computeValueY:data.high inRect:rect];
            
            //绘制线条路径
            if (j == self.displayFrom) {
                CGContextMoveToPoint(context, startX, highY);
            } else {
                
                CCSStickChartData *dataPre = [self.stickData objectAtIndex:j-1];
                if (dataPre.high != 0) {
                    CGContextAddLineToPoint(context, startX, highY);
                } else {
                    CGContextMoveToPoint(context, startX - lineLength / 2, highY);
                    CGContextAddLineToPoint(context, startX, highY);
                }
            }
            //X位移
            startX = startX + lineLength;
        }
        
        //绘制路径
        CGContextStrokePath(context);
    }
}


- (void)drawSticks:(CGRect)rect {
    // 蜡烛棒宽度
    CCFloat stickWidth = [self getDataStickWidth] - 0.5;

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetLineWidth(context, 1.0f);
    CGContextSetStrokeColorWithColor(context, self.stickBorderColor.CGColor);
    CGContextSetFillColorWithColor(context, self.stickFillColor.CGColor);

    if (self.stickData != NULL && [self.stickData count] > 0) {

        if (self.axisYPosition == CCSGridChartYAxisPositionLeft) {
            // 蜡烛棒起始绘制位置
            CCFloat stickX = self.axisMarginLeft + 1;
            //判断显示为方柱或显示为线条
            for (CCUInt i = self.displayFrom; i < [self getDisplayTo]; i++) {
                CCSStickChartData *stick = [self.stickData objectAtIndex:i];

//                CCFloat highY = ((1 - (stick.high - self.minValue) / (self.maxValue - self.minValue)) * (rect.size.height - self.axisMarginBottom) - super.axisMarginTop);
//                CCFloat lowY = ((1 - (stick.low - self.minValue) / (self.maxValue - self.minValue)) * (rect.size.height - self.axisMarginBottom) - self.axisMarginTop);
                CCFloat highY = [self computeValueY:stick.high inRect:rect];
                CCFloat lowY = [self computeValueY:stick.low inRect:rect];

                if (stick.high == 0) {
                    //没有值的情况下不绘制
                } else {
                    //绘制数据，根据宽度判断绘制直线或方柱
                    if (stickWidth >= 1) {
                        CGContextAddRect(context, CGRectMake(stickX, highY, stickWidth, lowY - highY));
                        //填充路径
                        CGContextFillPath(context);
                    } else {
                        CGContextMoveToPoint(context, stickX, highY);
                        CGContextAddLineToPoint(context, stickX, lowY);
                        //绘制线条
                        CGContextStrokePath(context);
                    }
                }

                //X位移
                stickX = stickX + 0.5 + stickWidth;
            }
        } else {
            // 蜡烛棒起始绘制位置
            CCFloat stickX = rect.size.width - self.axisMarginRight - 1 - stickWidth;
            //判断显示为方柱或显示为线条
            for (CCUInt i = 0; i < self.displayNumber; i++) {
                //获取index
                CCUInt index = [self getDisplayTo] - 1 - i;
                CCSStickChartData *stick = [self.stickData objectAtIndex:index];

                CCFloat highY = [self computeValueY:stick.high inRect:rect];
                CCFloat lowY = [self computeValueY:stick.low inRect:rect];
            
//                CCFloat highY =  ((1 - (stick.high - self.minValue) / (self.maxValue - self.minValue)) * (rect.size.height - self.axisMarginBottom) - super.axisMarginTop);
//                CCFloat lowY = ((1 - (stick.low - self.minValue) / (self.maxValue - self.minValue)) * (rect.size.height - self.axisMarginBottom) - self.axisMarginTop);
                

                if (stick.high == 0) {
                    //没有值的情况下不绘制
                } else {
                    //绘制数据，根据宽度判断绘制直线或方柱
                    if (stickWidth >= 1) {
                        CGContextAddRect(context, CGRectMake(stickX, highY, stickWidth, lowY - highY));
                        //填充路径
                        CGContextFillPath(context);
                    } else {
                        CGContextMoveToPoint(context, stickX, highY);
                        CGContextAddLineToPoint(context, stickX, lowY);
                        //绘制线条
                        CGContextStrokePath(context);
                    }
                }
                //X位移
                stickX = stickX - 0.5 - stickWidth;
            }
        }

    }
}

- (void)calcSelectedIndex {
    //X在系统范围内、进行计算
    if (self.axisYPosition == CCSGridChartYAxisPositionLeft) {
        if (self.singleTouchPoint.x > self.axisMarginLeft
            && self.singleTouchPoint.x < self.frame.size.width) {
            CCFloat stickWidth = [self getDataStickWidth];
            CCFloat valueWidth = self.singleTouchPoint.x - self.axisMarginLeft;
            if (valueWidth > 0) {
                CCUInt index = (CCUInt) (valueWidth / stickWidth);
                //如果超过则设置位最大
                if (index >= self.displayNumber) {
                    index = self.displayNumber - 1;
                }
                //设置选中的index
                self.selectedStickIndex = self.displayFrom + index;
                
            }
        }
    } else {
        if (self.singleTouchPoint.x > self.axisMarginLeft
            && self.singleTouchPoint.x < self.frame.size.width - self.axisMarginRight) {
            CCFloat stickWidth = 1.0 * [self getDataStickWidth];
            CCFloat valueWidth = self.singleTouchPoint.x - self.axisMarginLeft;
            if (valueWidth > 0) {
                CCUInt index = (CCUInt) (valueWidth / stickWidth);
                //如果超过则设置位最大
                if (index >= self.displayNumber) {
                    index = self.displayNumber - 1;
                }
                //设置选中的index
                self.selectedStickIndex = self.displayFrom + index;

            }
        }
    }
    
}

- (void) moveLeft {
    
    if (self.displayNumber < self.minDisplayNumber){
        return;
    }
    if (self.displayFrom < 2) {
        self.displayFrom = 0;
    }else{
        self.displayFrom = self.displayFrom - 2;
    }
    
//    if (self.displayFrom > 2) {
//        self.displayFrom = self.displayFrom - 2;
//    }
    
    if (self.chartDelegate && [self.chartDelegate respondsToSelector:@selector(CCSChartDisplayChangedFrom:from:number:)]) {
        [self.chartDelegate CCSChartDisplayChangedFrom:self from:self.displayFrom number:self.displayNumber];
    }
    
}

- (void) moveRight {
    
    if (self.displayNumber < self.minDisplayNumber){
        return;
    }
    if ([self getDisplayTo] + 2 > self.maxDisplayNumber) {
        if(self.displayFrom == self.maxDisplayNumber - self.displayNumber){
        }else{
            self.displayFrom = self.maxDisplayNumber - self.displayNumber;
        }
    }else{
        self.displayFrom = self.displayFrom + 2;
    }
    
//    if ([self getDisplayTo] + 2 < [self.stickData count]) {
//        self.displayFrom = self.displayFrom + 2;
//    }
    
    if (self.chartDelegate && [self.chartDelegate respondsToSelector:@selector(CCSChartDisplayChangedFrom:from:number:)]) {
        [self.chartDelegate CCSChartDisplayChangedFrom:self from:self.displayFrom number:self.displayNumber];
    }
}

- (void)zoomOut {
    if (self.displayNumber > self.minDisplayNumber) {
        
        if (self.displayNumber == self.minDisplayNumber){
            
        }else {
            CCInt resultDisplayNumber = self.displayNumber - 2;
            CCInt resultDisplayFrom = self.displayFrom + 2 / 2;
            
            if (resultDisplayNumber <= self.minDisplayNumber) {
                self.displayNumber = self.minDisplayNumber;
            } else {
                self.displayNumber = resultDisplayNumber;
            }
            
            if (resultDisplayFrom >= self.maxDisplayNumber - self.minDisplayNumber){
                self.displayFrom = self.maxDisplayNumber - self.minDisplayNumber;
            }else{
                self.displayFrom = resultDisplayFrom;
            }
        }
        
        //处理displayNumber越界
        if (self.displayNumber < self.minDisplayNumber) {
            self.displayNumber = self.minDisplayNumber;
        }

        //处理displayFrom越界
        if ([self getDisplayTo] >= [self.stickData count]) {
            self.displayFrom = [self.stickData count] - self.displayNumber;
        }
        
        if (self.chartDelegate && [self.chartDelegate respondsToSelector:@selector(CCSChartDisplayChangedFrom:from:number:)]) {
            [self.chartDelegate CCSChartDisplayChangedFrom:self from:self.displayFrom number:self.displayNumber];
        }
        
    }
}

- (void)zoomIn {
    if (self.displayNumber < self.minDisplayNumber) {
        return;
    }
    if (self.displayNumber < [self.stickData count] - 1) {
        if (self.displayFrom ==0 && self.displayNumber == self.maxDisplayNumber){
        }else {
            CCInt resultDisplayNumber = self.displayNumber + 2;
            CCInt resultDisplayFrom = self.displayFrom - 2 / 2;
            
            if (resultDisplayFrom <= 0) {
                self.displayFrom = 0;
                if (resultDisplayNumber >= self.maxDisplayNumber) {
                    self.displayNumber = self.maxDisplayNumber;
                } else {
                    self.displayNumber = resultDisplayNumber;
                }
            } else {
                self.displayFrom = resultDisplayFrom;
                if (resultDisplayNumber >= self.maxDisplayNumber) {
                    self.displayNumber = self.maxDisplayNumber;
                    self.displayFrom = 0;
                } else{
                    if(resultDisplayFrom + resultDisplayNumber >= self.maxDisplayNumber){
                        self.displayNumber = resultDisplayNumber;
                        self.displayFrom = self.maxDisplayNumber - resultDisplayNumber;
                    } else{
                        self.displayNumber = resultDisplayNumber;
                    }
                }
            }
        }
        
        if ([self getDisplayTo] >= [self.stickData count]) {
            self.displayNumber = [self.stickData count] - self.displayFrom;
        }
        
        if (self.chartDelegate && [self.chartDelegate respondsToSelector:@selector(CCSChartDisplayChangedFrom:from:number:)]) {
            [self.chartDelegate CCSChartDisplayChangedFrom:self from:self.displayFrom number:self.displayNumber];
        }
    
    }
}

- (void) setDisplayFrom:(CCInt)displayFrom
{
//    if (displayFrom > 0 && displayFrom < self.maxDisplayNumber - self.minDisplayNumber) {
//        if (displayFrom + self.displayNumber <= self.maxDisplayNumber) {
//            _displayFrom = displayFrom;
//        }
//    }
    
    if(displayFrom > 0){
        _displayFrom = displayFrom;
    }
}

-(void) setDisplayNumber:(CCInt)displayNumber
{
//    if (!self.stickData) {
//        return;
//    }
//    
//    if (_displayNumber >0  && displayNumber >= self.minDisplayNumber && displayNumber <= self.maxDisplayNumber) {
//        if (self.displayFrom + displayNumber <= self.maxDisplayNumber) {
//            _displayNumber = displayNumber;
//        }
//    }
    if(displayNumber > 0){
        _displayNumber = displayNumber;
    }
    
}

- (void) setStickData:(NSArray *)stickData
{
    if (stickData == nil) {
        NSLog(@"Stick data is nil");
        return;
    }
    CCInt datasize = [stickData count];
    if (datasize == 0) {
        NSLog(@"Stick data size is Zero");
        return;
    }
    
    _stickData = stickData;
    
    if (self.minDisplayNumber > datasize) {
        self.maxDisplayNumber = datasize;
        self.displayFrom = 0;
        self.displayNumber = datasize;
    }else{
        //右侧显示
        self.displayFrom = datasize - self.displayNumber;
        self.maxDisplayNumber = datasize;
        
    }
    
//    self.maxValue = CCIntMin;
//    self.minValue = CCIntMax;
}


-(CCInt) getDataDisplayNumber{
    return self.displayNumber > self.minDisplayNumber ? self.displayNumber:self.minDisplayNumber;
}

-(CCInt) getDisplayTo{
    return self.displayFrom + self.displayNumber;
}

-(CGFloat) getStickWidth{
    return (self.frame.size.width - self.axisMarginLeft - self.axisMarginRight) / self.displayNumber;
}

-(CGFloat) getDataStickWidth{
    return (self.frame.size.width - self.axisMarginLeft - self.axisMarginRight) / [self getDataDisplayNumber];
}

-(void) bindSelectedIndex
{
    CCFloat stickWidth = [self getDataStickWidth];
    CGFloat pointX = self.axisMarginLeft +(self.selectedStickIndex - self.displayFrom + 0.5) * stickWidth;
    
    
    _singleTouchPoint = CGPointMake(pointX,self.singleTouchPoint.y);
}

@end