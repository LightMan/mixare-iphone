//
//  UICompassView.h
//  Mixare
//
//  Created by David Jorge on 22/12/10.
//  Copyright 2010 Peer GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PoiItem.h"

@interface UICompassView : UIView {
@private
	CGFloat _currentHeading; // 0 points UP
	
//	CGAffineTransform _startTransform;	

	PoiItem *_destinationPoi;	
	UIImageView *_imgDirectionArrow;
	
}

@property (nonatomic) CGFloat currentHeading;
@property (nonatomic, retain) PoiItem *destinationPoi;
//@property (nonatomic) CGAffineTransform startTransform;

@property (nonatomic, retain) IBOutlet UIImageView *imgDirectionArrow;

@end
