//
//  UICompassView.m
//  Mixare
//
//  Created by David Jorge on 22/12/10.
//  Copyright 2010 Peer GmbH. All rights reserved.
//

#import "UICompassView.h"
#import "PoiItem.h"

@implementation UICompassView

//@synthesize startTransform = _startTransform;
@synthesize currentHeading = _currentHeading;
@synthesize destinationPoi = _destinationPoi;

@synthesize imgDirectionArrow = _imgDirectionArrow;

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect {
//    // Drawing code.
//	
//	myImageView.transform = CGAffineTransformMakeRotation(3.14159265); //rotation in radians
//	
//   self.startTransform = self.transform; //this has to be saved to prevent some kind of rounding error from gradually rotating the view
////        [UIView beginAnimations:@"selectionAnimation" context:nil];
////        [UIView setAnimationDelegate:self];
////        [UIView setAnimationDuration:0.1];
////        [UIView setAnimationRepeatCount:2];
////        [UIView setAnimationRepeatAutoreverses:YES];
//	self.transform = CGAffineTransformRotate(self.transform, (2 * M_PI / 180) );
////        [UIView commitAnimations];	
//}

- (void)dealloc {
	[_imgDirectionArrow release];
	[_destinationPoi release];
	
    [super dealloc];
}

- (void)setCurrentHeading:(CGFloat)heading {
	CGFloat angleRad = self.destinationPoi.azimuth - degreesToRadians(heading - 90);
	if (angleRad < 0)
		angleRad += 2*M_PI;
	NSLog(@"heading %.2f, poi azimuth %.2f, angleRad %.2f", heading, radiansToDegrees(self.destinationPoi.azimuth), radiansToDegrees(angleRad) ); /* DEBUG LOG */
	self.imgDirectionArrow.transform = CGAffineTransformMakeRotation(angleRad); //rotation in radians	
}

@end
