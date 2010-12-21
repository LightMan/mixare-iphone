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

#import "AugmentedViewController.h"

#import <QuartzCore/QuartzCore.h>

#define VIEWPORT_WIDTH_RADIANS 0.5
#define VIEWPORT_HEIGHT_RADIANS 0.7392

@interface UIViewController(OrientationPatch)
-(UIDeviceOrientation)interfaceOrientation;
@end

@implementation UIViewController(OrientationPatch)

-(UIDeviceOrientation)interfaceOrientation
{
	return [[UIDevice currentDevice] orientation];
}

@end

// Private methods and properties
@interface AugmentedViewController()

@property (nonatomic, retain) UIImagePickerController *cameraController;

@end


@implementation AugmentedViewController

// To filter the little movements of the accelerometer
const float kFilteringFactor = 0.05f;

// -----------------------------------------------------------------------------

@synthesize cameraController = _cameraController;
@synthesize radarView = _radarView;
@synthesize radarScopeView = _radarScopeView;
@synthesize ARViewDelegate = _ARViewdelegate;

@synthesize locationDelegate = _locationDelegate;
@synthesize accelerometerDelegate = _accelerometerDelegate;
@synthesize accelerometerManager = _accelerometerManager;
@synthesize updateTimer = _updateTimer;

@synthesize debugMode = _debugMode;
@synthesize lblDebug = _lblDebug;
@synthesize centerLocation = _centerLocation;
@synthesize poisCoordinates = _poisCoordinates;
@synthesize poisViews = _poisViews;
@synthesize overlayView = _overlayView;

//IBOutlets
@synthesize radiusSlider = _radiusSlider;
@synthesize lblCurrentDistance = _lblCurrentDistance;
@synthesize notificationView = _notificationView;

// -----------------------------------------------------------------------------

@synthesize centerCoordinate = _centerCoordinate;

@synthesize scaleViewsBasedOnDistance, rotateViewsBasedOnPerspective;
@synthesize maximumScaleDistance;
@synthesize minimumScaleFactor, maximumRotationAngle;

@synthesize updateFrequency;


#pragma mark -
#pragma mark Creation and destruction methods

- (void)viewDidLoad {
	[super viewDidLoad];
		
	self.poisCoordinates = [[[NSMutableArray alloc] init] autorelease];
	self.poisViews = [[[NSMutableArray alloc] init] autorelease];
	
	self.updateFrequency = 1 / 20.0;	
	self.scaleViewsBasedOnDistance = YES;
	self.maximumScaleDistance = 0.0;
	self.minimumScaleFactor = 0.6;
	
	self.rotateViewsBasedOnPerspective = YES;
	self.maximumRotationAngle = M_PI / 6.0;
	
	self.wantsFullScreenLayout = NO;
	
	
#if !TARGET_IPHONE_SIMULATOR	
	self.cameraController = [[[UIImagePickerController alloc] init] autorelease];
	self.cameraController.sourceType = UIImagePickerControllerSourceTypeCamera;
	CGAffineTransform cameraTransform = CGAffineTransformMakeScale(1.232, 1.232);
	self.cameraController.cameraViewTransform = cameraTransform;//CGAffineTransformScale(self.cameraController.cameraViewTransform, 1.23f,  1.23f);
	
	self.cameraController.showsCameraControls = NO;
	self.cameraController.navigationBarHidden = YES;
#endif
			
    float radius = [[NSUserDefaults standardUserDefaults] floatForKey:@"radius"];
    if (radius <= 0 || radius > 100){
        self.radiusSlider.value = 5.0;
        self.lblCurrentDistance.text= @"5.0 km";
    }else{
        self.radiusSlider.value = radius;
        NSLog(@"RADIUS VALUE: %f", radius);
        self.lblCurrentDistance.text= [NSString stringWithFormat:@"%.2f km",radius];
    }
				
	if (self.debugMode) {
		self.lblDebug.hidden = NO;
	}
	
//	self.overlayView = [[[UIView alloc] initWithFrame:self.cameraController.view.bounds] autorelease];	
//	[self.view addSubview:self.overlayView];	
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];	
	[self showLoadingViewOnMainThread];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
#if !TARGET_IPHONE_SIMULATOR
	[self.cameraController setCameraOverlayView:self.view];
	[[[UIApplication sharedApplication] keyWindow] setRootViewController:self.cameraController];	
	[self presentModalViewController:self.cameraController animated:NO];	
#endif
	
	if (!_updateTimer) {
		_updateTimer = [[NSTimer scheduledTimerWithTimeInterval:self.updateFrequency
														 target:self
													   selector:@selector(updateLocations:)
													   userInfo:nil
														repeats:YES] retain];
	}
	
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;	
	self.radiusSlider = nil;
	self.radarView = nil;
	self.radarScopeView = nil;
	self.lblCurrentDistance = nil;
	self.lblDebug = nil;
}


- (void)dealloc {
	[_centerLocation release];
	[_poisViews release];
	[_poisCoordinates release];
	[_overlayView release];
	
	[_radiusSlider release];
	[_radarView release];
	[_radarScopeView release];
	[_lblCurrentDistance release];
	[_lblDebug release];
	
    [super dealloc];
}

#pragma mark -
#pragma mark Rotating methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	NSLog(@"shouldAutorotateToInterfaceOrientation %d", interfaceOrientation); /* DEBUG LOG */
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	NSLog(@"willRotateToInterfaceOrientation %d", toInterfaceOrientation); /* DEBUG LOG */	
	
	UIView *viewObject = self.view;
	if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
		[viewObject setCenter:CGPointMake(160, 240)];
		CGAffineTransform cgCTM = CGAffineTransformMakeRotation(M_PI * 0.5);
		viewObject.transform = cgCTM;
		viewObject.bounds = CGRectMake(0, 0, 480, 320);		
	} else if (toInterfaceOrientation == UIInterfaceOrientationPortrait) {
		[viewObject setCenter:CGPointMake(160, 240)];
		CGAffineTransform tr = viewObject.transform; // get current transform (portrait)
		tr = CGAffineTransformRotate(tr, - (M_PI / 2.0)); // rotate -90 degrees to go portrait
		viewObject.transform = tr; // set current transform 
		viewObject.bounds = CGRectMake(0, 0, 320, 480);
	}
}

#pragma mark -
#pragma mark Properties methods

- (void)closeCameraView{
	[self.cameraController.view removeFromSuperview];
	[self.cameraController release];
}

- (void)setUpdateFrequency:(double)newUpdateFrequency {
	
	updateFrequency = newUpdateFrequency;
	
	if (!_updateTimer)
		return;
	
	[_updateTimer invalidate];
	[_updateTimer release];
	
	_updateTimer = [[NSTimer scheduledTimerWithTimeInterval:self.updateFrequency
													 target:self
												   selector:@selector(updateLocations:)
												   userInfo:nil
													repeats:YES] retain];
}

- (void)setDebugMode:(BOOL)flag {
	self.lblDebug.hidden = !_debugMode;
}

#pragma mark -
#pragma mark Viewport drawing pois in view methods

- (BOOL)viewportContainsCoordinate:(PoiItem *)coordinate {
	double centerAzimuth = self.centerCoordinate.azimuth;
	double leftAzimuth = centerAzimuth - VIEWPORT_WIDTH_RADIANS / 2.0;
	
	if (leftAzimuth < 0.0) {
		leftAzimuth = 2 * M_PI + leftAzimuth;
	}
	
	double rightAzimuth = centerAzimuth + VIEWPORT_WIDTH_RADIANS / 2.0;
	
	if (rightAzimuth > 2 * M_PI) {
		rightAzimuth = rightAzimuth - 2 * M_PI;
	}
	
	BOOL result = (coordinate.azimuth > leftAzimuth && coordinate.azimuth < rightAzimuth);
	
	if (leftAzimuth > rightAzimuth) {
		result = (coordinate.azimuth < rightAzimuth || coordinate.azimuth > leftAzimuth);
	}
	
	double centerInclination = self.centerCoordinate.inclination;
	double bottomInclination = centerInclination - VIEWPORT_HEIGHT_RADIANS / 2.0;
	double topInclination = centerInclination + VIEWPORT_HEIGHT_RADIANS / 2.0;
	
	//check the height.
	result = result && (coordinate.inclination > bottomInclination && coordinate.inclination < topInclination);
		
//	if (result)
//		NSLog(@"showing POI: %@", [coordinate description]); /* DEBUG LOG */
		
	return result;
}

- (CGPoint)pointInView:(MarkerView *)realityView forCoordinate:(PoiItem *)coordinate {
	
	CGPoint point;
	
	//x coordinate.
	
	double pointAzimuth = coordinate.azimuth;
	
	//our x numbers are left based.
	double leftAzimuth = self.centerCoordinate.azimuth - VIEWPORT_WIDTH_RADIANS / 2.0;
	
	if (leftAzimuth < 0.0) {
		leftAzimuth = 2 * M_PI + leftAzimuth;
	}
	
	if (pointAzimuth < leftAzimuth) {
		//it's past the 0 point.
		point.x = ((2 * M_PI - leftAzimuth + pointAzimuth) / VIEWPORT_WIDTH_RADIANS) * realityView.frame.size.width;
	} else {
		point.x = ((pointAzimuth - leftAzimuth) / VIEWPORT_WIDTH_RADIANS) * realityView.frame.size.width;
	}
	
	//y coordinate.
	
	double pointInclination = coordinate.inclination;
	
	double topInclination = self.centerCoordinate.inclination - VIEWPORT_HEIGHT_RADIANS / 2.0;
	
	point.y = realityView.frame.size.height - ((pointInclination - topInclination) / VIEWPORT_HEIGHT_RADIANS) * realityView.frame.size.height;
	
	return point;
}

-(CGPoint)rotatePointAboutOrigin:(CGPoint) point angle: (float) angle{
    float s = sinf(angle);
    float c = cosf(angle);
    return CGPointMake(c * point.x - s * point.y, s * point.x + c * point.y);
}

NSComparisonResult LocationSortClosestFirst(PoiItem *s1, PoiItem *s2, void *ignore) {
    if (s1.radialDistance < s2.radialDistance) {
		return NSOrderedAscending;
	} else if (s1.radialDistance > s2.radialDistance) {
		return NSOrderedDescending;
	} else {
		return NSOrderedSame;
	}
}

#pragma mark -
#pragma mark POIs management

- (void)addCoordinate:(PoiItem *)coordinate animated:(BOOL)animated {
	//do some kind of animation?
	[self.poisCoordinates addObject:coordinate];
	
	if (coordinate.radialDistance > self.maximumScaleDistance) {
		self.maximumScaleDistance = coordinate.radialDistance;
	}
	
	//message the delegate.
	[self.poisViews addObject:[self.ARViewDelegate viewForCoordinate:coordinate]];
}

- (void)removeCoordinates:(NSMutableArray *)coordinates {	
	[self.poisCoordinates removeAllObjects];
	[self.poisViews removeAllObjects];
    for (UIView *view in self.overlayView.subviews){
        [view removeFromSuperview];
    }
}

- (void)recalculateDataWithNewLocation:(CLLocation *)newLocation {
	NSLog(@"Recalculating Data with New Location"); /* DEBUG LOG */
	self.centerLocation = newLocation;
	
	for (PhysicalPlace *geoLocation in self.poisCoordinates) {
		if ([geoLocation isKindOfClass:[PhysicalPlace class]]) {
			[geoLocation calibrateUsingOrigin:self.centerLocation];
			
			if (geoLocation.radialDistance > self.maximumScaleDistance) {
				self.maximumScaleDistance = geoLocation.radialDistance;
			}
		}
	}
}

- (void)updateLocations:(NSTimer *)timer {
	//update locations!
	if (!self.poisViews || self.poisViews.count == 0)
		return;
	
	self.lblDebug.text = [self.centerCoordinate description];
	
	int index = 0;
    NSMutableArray * radarPointValues= [[NSMutableArray alloc]initWithCapacity:[self.poisCoordinates count]];


	BOOL test = YES;

	for (PoiItem *item in self.poisCoordinates) {
		
		MarkerView *viewToDraw = [self.poisViews objectAtIndex:index];
		
		if ([self viewportContainsCoordinate:item]) {
			
			CGPoint loc = [self pointInView:self.overlayView forCoordinate:item];
			if (test) {
				test = NO;
				NSLog(@"Punto de la vista (%.f,%.f), My Azimuth %f", loc.x, loc.y, self.centerCoordinate.azimuth); /* DEBUG LOG */
			}
			
			CGFloat scaleFactor = 1.5;
			if (self.scaleViewsBasedOnDistance) {
				scaleFactor = 1.0 - self.minimumScaleFactor * (item.radialDistance / self.maximumScaleDistance);
			}
			
			float width = viewToDraw.bounds.size.width * scaleFactor;
			float height = viewToDraw.bounds.size.height * scaleFactor;
			
			viewToDraw.frame = CGRectMake(loc.x - width / 2.0, loc.y-height / 2.0, width, height);
			
			CATransform3D transform = CATransform3DIdentity;
			
			//set the scale if it needs it.
			if (self.scaleViewsBasedOnDistance) {
				//scale the perspective transform if we have one.
				transform = CATransform3DScale(transform, scaleFactor, scaleFactor, scaleFactor);
			}
			
			if (self.rotateViewsBasedOnPerspective) {
				transform.m34 = 1.0 / 300.0;
				
				double itemAzimuth = item.azimuth;
				double centerAzimuth = self.centerCoordinate.azimuth;
				if (itemAzimuth - centerAzimuth > M_PI) centerAzimuth += 2*M_PI;
				if (itemAzimuth - centerAzimuth < -M_PI) itemAzimuth += 2*M_PI;
				
				double angleDifference = itemAzimuth - centerAzimuth;
				transform = CATransform3DRotate(transform, self.maximumRotationAngle * angleDifference / (VIEWPORT_HEIGHT_RADIANS / 2.0) , 0, 1, 0);
			}
			
			viewToDraw.layer.transform = transform;
			
			//if we don't have a superview, set it up.
			if (!(viewToDraw.superview)) {
				[self.overlayView addSubview:viewToDraw];
				[self.overlayView sendSubviewToBack:viewToDraw];
			}
		} else {
			[viewToDraw removeFromSuperview];
			viewToDraw.transform = CGAffineTransformIdentity;
		}
        CGPoint loc = [self pointInView:self.overlayView forCoordinate:item];
        item.radarPos = loc;
//        if( fmod((locationManager.heading.trueHeading+item.azimuth),360)==0){
//            item.azimuth= locationManager.heading.trueHeading+item.azimuth;
//        }else{
//            item.azimuth=fmod((locationManager.heading.trueHeading+item.azimuth),360);
//        }
        [radarPointValues addObject:item];
		index++;
	}
	
    float radius = [[[NSUserDefaults standardUserDefaults] objectForKey:@"radius"] floatValue];
    
	if(radius <= 0 || radius > 100){
        radius = 5.0;
    }
    
    self.radarView.pois = radarPointValues;
    self.radarView.radius = radius;
    [self.radarView setNeedsDisplay];
	
	[radarPointValues release];	
}

#pragma mark -
#pragma mark locationManager delegates and methods

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
//	NSLog(@"Augmented View Controller True Heading %.f", newHeading.trueHeading); /* DEBUG LOG */
	
	self.centerCoordinate.azimuth = fmod(newHeading.magneticHeading, 360.0) * (2 * (M_PI / 360.0));
    if([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft){
        if(self.centerCoordinate.azimuth < (3*M_PI/2))
            self.centerCoordinate.azimuth += (M_PI/2);
        else
            self.centerCoordinate.azimuth = fmod(self.centerCoordinate.azimuth + (M_PI/2),360);
    }
	
    int gradToRotate = newHeading.trueHeading-90-22.5;
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft){
        gradToRotate+= 90;
    }
    if (gradToRotate < 0){
        gradToRotate= 360 + gradToRotate;
    }
	self.radarScopeView.referenceAngle = gradToRotate;
    [self.radarScopeView setNeedsDisplay];
}

- (void)startListening:(CLLocationManager *)locationManager {
	//we want every move.
	locationManager.headingFilter = kCLHeadingFilterNone;
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	[locationManager startUpdatingHeading];
	
	if (self.accelerometerManager == nil) {
		self.accelerometerManager = [UIAccelerometer sharedAccelerometer];
	}
	self.accelerometerManager.updateInterval = 0.01;
	self.accelerometerManager.delegate = self;
	
	if (self.centerCoordinate == nil) {
		self.centerCoordinate = [PoiItem coordinateWithRadialDistance:0 inclination:0 azimuth:0];
	}
}

- (void)stopListening:(CLLocationManager *)locationManager {
	[locationManager stopUpdatingHeading];
}

#pragma mark -
#pragma mark Accelerometer delegate

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	static UIAccelerationValue rollingX, rollingZ;
	// -1 face down 1 face up.
	//update the center coordinate.
		
	//this should be different based on orientation.
	if([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft){
        rollingZ  = (acceleration.z * kFilteringFactor) + (rollingZ  * (1.0 - kFilteringFactor));
        rollingX = (acceleration.x * kFilteringFactor) + (rollingX * (1.0 - kFilteringFactor));
    }else{
        rollingZ  = (acceleration.z * kFilteringFactor) + (rollingZ  * (1.0 - kFilteringFactor));
        rollingX = (acceleration.y * kFilteringFactor) + (rollingX * (1.0 - kFilteringFactor));
	}
	if (rollingZ > 0.0) {
		self.centerCoordinate.inclination = atan(rollingX / rollingZ) + M_PI / 2.0;
	} else if (rollingZ < 0.0) {
		self.centerCoordinate.inclination = atan(rollingX / rollingZ) - M_PI / 2.0;// + M_PI;
	} else if (rollingX < 0) {
		self.centerCoordinate.inclination = M_PI/2.0;
	} else if (rollingX >= 0) {
		self.centerCoordinate.inclination = 3 * M_PI/2.0;
	}
	
	if (self.accelerometerDelegate && [self.accelerometerDelegate respondsToSelector:@selector(accelerometer:didAccelerate:)]) {
		//forward the acceleromter.
		[self.accelerometerDelegate accelerometer:accelerometer didAccelerate:acceleration];
	}
}

#pragma mark -
#pragma mark controls methods

- (IBAction)closeButtonPressed {
	[self.ARViewDelegate viewDidClose];
}

- (IBAction)radiusSliderChanged:(UISlider*)slider {
	self.lblCurrentDistance.text= [NSString stringWithFormat:@"%.2f km",slider.value];
}

- (IBAction)radiusSliderTouchUp:(UISlider*)slider {
	[self showLoadingViewOnMainThread];
	[self performSelector:@selector(sliderValueChanged:) withObject:slider];
}

- (void)sliderValueChanged:(UISlider*)slider {
	[self.ARViewDelegate sliderValueChanged:slider];	
}

#pragma mark -
#pragma mark loading view

- (void)showLoadingView {
	self.notificationView.hidden = NO;	
}

- (void)hideLoadingView {
	self.notificationView.hidden = YES;	
}

- (void)showLoadingViewOnMainThread {
	[self performSelectorOnMainThread:@selector(showLoadingView) withObject:nil waitUntilDone:YES];
}

- (void)hideLoadingViewOnMainThread {
	[self performSelectorOnMainThread:@selector(hideLoadingView) withObject:nil waitUntilDone:YES];
}

@end
