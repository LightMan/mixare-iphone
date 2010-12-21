/* Copyright (C) 2010- Peer internet solutions
 * 
 * This file is part of mixare.
 * 
 * This program is free software: you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License as published by 
 * the Free Software Foundation, either version 3 of the License, or 
 * (at your option) any later version. 
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License 
 * for more details. 
 * 
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see <http://www.gnu.org/licenses/> */

#import <UIKit/UIKit.h>
#import "MarkerView.h"
#import <CoreLocation/CoreLocation.h>
#import "RadarView.h"
#import "PoiItem.h"
#import "RadarScopeView.h"

@protocol ARViewDelegate

- (MarkerView *)viewForCoordinate:(PoiItem *)coordinate;
- (void)viewDidClose;
- (void)sliderValueChanged:(UISlider*)slider;

@end


@interface AugmentedViewController : UIViewController <UIAccelerometerDelegate, CLLocationManagerDelegate> {		
	BOOL scaleViewsBasedOnDistance;
	double maximumScaleDistance;
	double minimumScaleFactor;
	
	//defaults to 20hz;
	double updateFrequency;
	
	BOOL rotateViewsBasedOnPerspective;
	double maximumRotationAngle;
	
@private
	
	BOOL _debugMode;
	NSTimer *_updateTimer;
		
// -----------------------------------------------------------------------------
	UIImagePickerController *_cameraController;
	RadarView *_radarView;
    RadarScopeView * _radarScopeView;
	UIAccelerometer *_accelerometerManager;
	PoiItem *_centerCoordinate;
	CLLocation *_centerLocation;	

	id<ARViewDelegate> _ARViewdelegate;
	id<UIAccelerometerDelegate> _accelerometerDelegate;
	id<CLLocationManagerDelegate> _locationDelegate;	
	
	NSMutableArray *_poisCoordinates;
	NSMutableArray *_poisViews;
	MarkerView *_overlayView;
	
	//IBOutlets
	UISlider* _radiusSlider;	
	UILabel* _lblCurrentDistance;	
    UIView *_notificationView;	
	UILabel *_lblDebug;
}

@property (nonatomic) BOOL debugMode;

@property (nonatomic, retain) UIAccelerometer *accelerometerManager;
@property (nonatomic, retain) PoiItem *centerCoordinate;
@property (nonatomic, retain) CLLocation *centerLocation;

@property (nonatomic, retain) NSMutableArray *poisCoordinates;
@property (nonatomic, retain) NSMutableArray *poisViews;
@property (nonatomic, retain) NSTimer *updateTimer;

@property (nonatomic, assign) id<ARViewDelegate> ARViewDelegate;
@property (nonatomic, assign) id<UIAccelerometerDelegate> accelerometerDelegate;
@property (nonatomic, assign) id<CLLocationManagerDelegate> locationDelegate;

//IBOutlets
@property (nonatomic, retain) IBOutlet UISlider *radiusSlider;
@property (nonatomic, retain) IBOutlet RadarView* radarView;
@property (nonatomic, retain) IBOutlet RadarScopeView* radarScopeView;
@property (nonatomic, retain) IBOutlet UILabel* lblCurrentDistance;
@property (nonatomic, retain) IBOutlet UIView *notificationView;
@property (nonatomic, retain) IBOutlet UILabel *lblDebug;

@property (nonatomic, retain) IBOutlet MarkerView *overlayView;

//IBActions
- (IBAction)radiusSliderChanged:(UISlider*)slider;
- (IBAction)closeButtonPressed;
- (IBAction)radiusSliderTouchUp:(UISlider*)slider;

//Public methods
- (void)closeCameraView;
- (void)showLoadingViewOnMainThread;
- (void)hideLoadingViewOnMainThread;


// -----------------------------------------------------------------------------

@property BOOL scaleViewsBasedOnDistance;
@property double maximumScaleDistance;
@property double minimumScaleFactor;

@property BOOL rotateViewsBasedOnPerspective;
@property double maximumRotationAngle;

@property double updateFrequency;

//adding coordinates to the underlying data model.
- (void)addCoordinate:(PoiItem *)coordinate animated:(BOOL)animated;
//removing coordinates
- (void)removeCoordinates:(NSArray *)coordinates;

- (CGPoint)rotatePointAboutOrigin:(CGPoint) point angle:(float) angle;

- (void)startListening:(CLLocationManager *)locationManager;
- (void)stopListening:(CLLocationManager *)locationManager;
- (void)updateLocations:(NSTimer *)timer;
- (CGPoint)pointInView:(UIView *)realityView forCoordinate:(PoiItem *)coordinate;

- (BOOL)viewportContainsCoordinate:(PoiItem *)coordinate;
- (void)recalculateDataWithNewLocation:(CLLocation *)newLocation;


@end
