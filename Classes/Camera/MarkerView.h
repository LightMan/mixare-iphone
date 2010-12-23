/*
 * Copyright (C) 2010- Peer internet solutions
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
 * this program. If not, see <http://www.gnu.org/licenses/>
 */

#import <UIKit/UIKit.h>
#import "PoiItem.h"

@protocol MarkerViewDelegate;

@interface MarkerView: UIView {

@private
    UIView *_viewTouched;
    NSString *_url;
	BOOL _touchesMoved;
	PoiItem *_poiItem;
	
	id<MarkerViewDelegate> _delegate;
	
	UILabel* _lblTitle;
	UIButton* _btnDetail;

// -----------------------------------------------------------------------------
	UIView *loadView;
}

@property (nonatomic, retain) UIView *viewTouched;
@property (nonatomic, retain) PoiItem *poiItem;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, assign) id<MarkerViewDelegate> delegate;

@property (nonatomic, retain) IBOutlet UILabel* lblTitle;
@property (nonatomic, retain) IBOutlet UIButton* btnDetail;

- (IBAction)btnDetailPressed;

@end

@protocol MarkerViewDelegate

@optional
- (void)markerViewPressed:(MarkerView*)markerView;

@end

