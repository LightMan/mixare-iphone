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
	int oldHeading;
	NSTimer *_updateTimer;
	
	MarkerView *ar_overlayView;
	
	NSMutableArray *ar_coordinates;
	NSMutableArray *ar_coordinateViews;

// -----------------------------------------------------------------------------
	UIImagePickerController *_cameraController;
	RadarView *_radarView;
    RadarScopeView * _radarScopeView;
	CLLocationManager *_locationManager;
	UIAccelerometer *_accelerometerManager;
	PoiItem *_centerCoordinate;
	UILabel *_lblDebug;

	id<ARViewDelegate> _ARViewdelegate;
	id<CLLocationManagerDelegate> _locationDelegate;
	id<UIAccelerometerDelegate> _accelerometerDelegate;
	

	//IBOutlets
	UISlider* _radiusSlider;	
	UILabel* _lblCurrentDistance;	
    UIView *_notificationView;	
}

@property (nonatomic) BOOL debugMode;
@property (nonatomic, retain) UILabel *lblDebug;

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) UIAccelerometer *accelerometerManager;
@property (nonatomic, retain) PoiItem *centerCoordinate;

@property (nonatomic, assign) id<ARViewDelegate> ARViewDelegate;
@property (nonatomic, assign) id<CLLocationManagerDelegate> locationDelegate;
@property (nonatomic, assign) id<UIAccelerometerDelegate> accelerometerDelegate;

//IBOutlets
@property (nonatomic, retain) IBOutlet UISlider *radiusSlider;
@property (nonatomic, retain) IBOutlet RadarView* radarView;
@property (nonatomic, retain) IBOutlet RadarScopeView* radarScopeView;
@property (nonatomic, retain) IBOutlet UILabel* lblCurrentDistance;
@property (nonatomic, retain) IBOutlet UIView *notificationView;

//IBActions
- (IBAction)radiusSliderChanged:(UISlider*) slider;
- (IBAction)closeButtonPressed;

//Public methods
- (void)closeCameraView;
- (void)showLoadingView;
- (void)hideLoadingView;
- (void)setAsLocationManagerController:(CLLocationManager *)manager withDelegate:(id<CLLocationManagerDelegate>)delegate;


// -----------------------------------------------------------------------------

@property (readonly) NSArray *coordinates;

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

- (void)startListening;
- (void)stopListening;
- (void)updateLocations:(NSTimer *)timer;
- (CGPoint)pointInView:(UIView *)realityView forCoordinate:(PoiItem *)coordinate;

- (BOOL)viewportContainsCoordinate:(PoiItem *)coordinate;


@end
