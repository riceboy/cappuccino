/*
 * CPButton.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "_CPImageAndTextView.j"
@import "CGGeometry.j"

@import "CPControl.j"

#include "CoreGraphics/CGGeometry.h"


CPScaleProportionally   = 0;
CPScaleToFit            = 1;
CPScaleNone             = 2;

/*
    @global
    @group CPCellImagePosition
*/
CPNoImage       = 0;
/*
    @global
    @group CPCellImagePosition
*/
CPImageOnly     = 1;
/*
    @global
    @group CPCellImagePosition
*/
CPImageLeft     = 2;
/*
    @global
    @group CPCellImagePosition
*/
CPImageRight    = 3;
/*
    @global
    @group CPCellImagePosition
*/
CPImageBelow    = 4;
/*
    @global
    @group CPCellImagePosition
*/
CPImageAbove    = 5;
/*
    @global
    @group CPCellImagePosition
*/
CPImageOverlaps = 6;

/*
    @global
    @class CPButton
*/
CPOnState       = 1;
/*
    @global
    @class CPButton
*/
CPOffState      = 0;
/*
    @global
    @class CPButton
*/
CPMixedState    = -1;

/*
    @global
    @group CPBezelStyle
*/
CPRoundedBezelStyle             = 1;
/*
    @global
    @group CPBezelStyle
*/
CPRegularSquareBezelStyle       = 2;
/*
    @global
    @group CPBezelStyle
*/
CPThickSquareBezelStyle         = 3;
/*
    @global
    @group CPBezelStyle
*/
CPThickerSquareBezelStyle       = 4;
/*
    @global
    @group CPBezelStyle
*/
CPDisclosureBezelStyle          = 5;
/*
    @global
    @group CPBezelStyle
*/
CPShadowlessSquareBezelStyle    = 6;
/*
    @global
    @group CPBezelStyle
*/
CPCircularBezelStyle            = 7;
/*
    @global
    @group CPBezelStyle
*/
CPTexturedSquareBezelStyle      = 8;
/*
    @global
    @group CPBezelStyle
*/
CPHelpButtonBezelStyle          = 9;
/*
    @global
    @group CPBezelStyle
*/
CPSmallSquareBezelStyle         = 10;
/*
    @global
    @group CPBezelStyle
*/
CPTexturedRoundedBezelStyle     = 11;
/*
    @global
    @group CPBezelStyle
*/
CPRoundRectBezelStyle           = 12;
/*
    @global
    @group CPBezelStyle
*/
CPRecessedBezelStyle            = 13;
/*
    @global
    @group CPBezelStyle
*/
CPRoundedDisclosureBezelStyle   = 14;
/*
    @global
    @group CPBezelStyle
*/
CPHUDBezelStyle                 = -1;


/*
    @global
    @group CPButtonType
*/
CPMomentaryLightButton   = 0;
/*
    @global
    @group CPButtonType
*/
CPPushOnPushOffButton    = 1;
/*
    @global
    @group CPButtonType
*/
CPToggleButton           = 2;
/*
    @global
    @group CPButtonType
*/
CPSwitchButton           = 3;
/*
    @global
    @group CPButtonType
*/
CPRadioButton            = 4;
/*
    @global
    @group CPButtonType
*/
CPMomentaryChangeButton  = 5;
/*
    @global
    @group CPButtonType
*/
CPOnOffButton            = 6;
/*
    @global
    @group CPButtonType
*/
CPMomentaryPushInButton  = 7;
/*
    @global
    @group CPButtonType
*/
CPMomentaryPushButton    = 0;
/*
    @global
    @group CPButtonType
*/
CPMomentaryLight         = 7;


var CPHUDBezelStyleTextColor = nil;

var _CPButtonClassName                          = nil,
    _CPButtonBezelStyleSizes                    = {},
    _CPButtonBezelStyleIdentifiers              = {},
    _CPButtonBezelStyleHighlightedIdentifier    = @"Highlighted";

/*! @class CPButton

    CPButton is a subclass of CPControl that
    intercepts mouse-down events and sends an action message to a
    target object when it's clicked or pressed.
*/
@implementation CPButton : CPControl
{
    int                 _tag;
    int                 _state;
    BOOL                _allowsMixedState;
    
    CPString            _title;
    CPString            _alternateTitle;
    
    CPImage             _image;
    CPImage             _alternateImage;

    // Display Properties
    CPThemedValue       _bezelInset;
    CPThemedValue       _contentInset;
    
    CPThemedValue       _bezelColor;

    // Layout Views
    CPView              _bezelView;
    _CPImageAndTextView _contentView;
    
    // NS-style Display Properties
    CPBezelStyle        _bezelStyle;
    BOOL                _isBordered;
    CPControlSize       _controlSize;
}

+ (id)themedAttributes
{
    return [CPDictionary dictionaryWithObjects:[_CGInsetMakeZero(), _CGInsetMakeZero(), nil]
                                       forKeys:[@"bezel-inset", @"content-inset", @"bezel-color"]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        // Should we instead override the defaults?
        [self setValue:CPCenterTextAlignment forThemedAttributeName:@"alignment"];
        [self setValue:CPCenterVerticalTextAlignment forThemedAttributeName:@"vertical-alignment"];
        [self setValue:CPImageLeft forThemedAttributeName:@"image-position"];
        [self setValue:CPScaleNone forThemedAttributeName:@"image-scaling"];
        
        _controlSize = CPRegularControlSize;
        
//        [self setBezelStyle:CPRoundRectBezelStyle];
        [self setBordered:YES];
    }
    
    return self;
}

// Setting the state
/*!
    Returns <code>YES</code> if the button has a 'mixed' state in addition to on and off.
*/
- (BOOL)allowsMixedState
{
    return _allowsMixedState;
}

/*!
    Sets whether the button can have a 'mixed' state.
    @param aFlag specifies whether a 'mixed' state is allowed or not
*/
- (void)setAllowsMixedState:(BOOL)aFlag
{
    _allowsMixedState = aFlag;
}

/*!
    Sets the button to its next state.
*/
- (void)setNextState
{
    if (_state == CPOffState)
        _state = CPOnState;
    else
        _state = (_state >= CPOnState && _allowsMixedState) ? CPMixedState : CPOffState;
}

/*!
    Sets the button's state to <code>aState</code>.
    @param aState Possible states are any of the CPButton globals:
    <code>CPOffState, CPOnState, CPMixedState</code>
*/
- (void)setState:(int)aState
{
    _state = aState;
}

/*!
    Returns the button's current state
*/
- (int)state
{
    return _state;
}

- (void)setTitle:(CPString)aTitle
{
    if (_title === aTitle)
        return;
    
    _title = aTitle;
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (CPString)title
{
    return _title;
}

- (void)setAlternateTitle:(CPString)aTitle
{
    if (_alternateTitle === aTitle)
        return;
    
    _alternateTitle = aTitle;

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (CPString)alternateTitle
{
    return _alternateTitle;
}

- (void)setImage:(CPImage)anImage
{
    if (_image === anImage)
        return;
    
    _image = anImage;
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (CPImage)image
{
    return _image;
}

/*!
    Sets the button's image which is used in its alternate state.
    @param anImage the image to be used while the button is in an alternate state
*/
- (void)setAlternateImage:(CPImage)anImage
{
    if (_alternateImage === anImage)
        return;
    
    _alternateImage = anImage;
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns the image used when the button is in an alternate state.
*/
- (CPImage)alternateImage
{
    return _alternateImage;
}

/*!
    Highlights the receiver based on <code>aFlag</code>.
    @param If <code>YES</code> the button will highlight, <code>NO</code> the button will unhighlight.
*/
- (void)highlight:(BOOL)aFlag
{
    [super highlight:aFlag];
    
    [self drawBezelWithHighlight:aFlag];
}

/*!
    Sets button's tag.
    @param aTag the button's new tag
*/
- (void)setTag:(int)aTag
{
    _tag = aTag;
}

/*!
    Returns the button's tag.
*/
- (int)tag
{
    return _tag;
}

- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    [self highlight:YES];
    
    return [super startTrackingAt:aPoint];
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    [self highlight:NO];
    
    [super stopTracking:lastPoint at:aPoint mouseIsUp:mouseIsUp];
}

/* @ignore */
- (void)drawBezelWithHighlight:(BOOL)shouldHighlight
{   return;
    _bezelBorderNeedsUpdate = ![self window];
    
    if (_bezelBorderNeedsUpdate)
        return;
    
    [self setBackgroundColorWithName:shouldHighlight ? CPControlHighlightedBackgroundColor : CPControlNormalBackgroundColor];
}

- (CPView)createBezelView
{
    var view = [[CPView alloc] initWithFrame:_CGRectMakeZero()];

    [view setHitTests:NO];
    
    return view;
}

- (CPView)createContentView
{
    var view = [[_CPImageAndTextView alloc] initWithFrame:_CGRectMakeZero()];
    
    return view;
}

- (CGRect)contentRectForBounds:(CGRect)bounds
{
    var contentInset = [self currentValueForThemedAttributeName:@"content-inset"];

    if (_CGInsetIsEmpty(contentInset))
        return bounds;

    bounds.origin.x += contentInset.left;
    bounds.origin.y += contentInset.top;
    bounds.size.width -= contentInset.left + contentInset.right;
    bounds.size.height -= contentInset.top + contentInset.bottom;
    
    return bounds;
}

- (CGRect)bezelRectForBounds:(CFRect)bounds
{
    if (![self isBordered])
        return _CGRectMakeZero();

    var bezelInset = [self currentValueForThemedAttributeName:@"bezel-inset"];

    if (_CGInsetIsEmpty(bezelInset))
        return bounds;
    
    bounds.origin.x += bezelInset.left;
    bounds.origin.y += bezelInset.top;
    bounds.size.width -= bezelInset.left + bezelInset.right;
    bounds.size.height -= bezelInset.top + bezelInset.bottom;
    
    return bounds;
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "bezel-view")
        return [self bezelRectForBounds:[self bounds]];
    
    else if (aName === "content-view")
        return [self contentRectForBounds:[self bounds]];
    
    return [super rectForEphemeralSubviewNamed:aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "bezel-view")
    {
        var view = [[CPView alloc] initWithFrame:_CGRectMakeZero()];

        [view setHitTests:NO];
        
        return view;
    }
    else
        return [[_CPImageAndTextView alloc] initWithFrame:_CGRectMakeZero()];

    return [super createEphemeralSubviewNamed:aName];
}

- (void)layoutSubviews
{
    var bezelView = [self layoutEphemeralSubviewNamed:@"bezel-view"
                                           positioned:CPWindowBelow
                      relativeToEphemeralSubviewNamed:@"content-view"];
      
    if (bezelView)
        [bezelView setBackgroundColor:[self currentValueForThemedAttributeName:@"bezel-color"]];
    
    var contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                             positioned:CPWindowAbove
                        relativeToEphemeralSubviewNamed:@"bezel-view"];

    if (contentView)
    {
        [contentView setText:((_controlState & CPControlStateHighlighted) && _alternateTitle) ? _alternateTitle : _title];
        [contentView setImage:((_controlState & CPControlStateHighlighted) && _alternateImage) ? _alternateImage : _image];
    
        [contentView setFont:[self currentValueForThemedAttributeName:@"font"]];
        [contentView setTextColor:[self currentValueForThemedAttributeName:@"text-color"]];
        [contentView setAlignment:[self currentValueForThemedAttributeName:@"alignment"]];
        [contentView setVerticalAlignment:[self currentValueForThemedAttributeName:@"vertical-alignment"]];
        [contentView setLineBreakMode:[self currentValueForThemedAttributeName:@"line-break-mode"]];
        [contentView setTextShadowColor:[self currentValueForThemedAttributeName:@"text-shadow-color"]];
        [contentView setTextShadowOffset:[self currentValueForThemedAttributeName:@"text-shadow-offset"]];
        [contentView setImagePosition:[self currentValueForThemedAttributeName:@"image-position"]];
        [contentView setImageScaling:[self currentValueForThemedAttributeName:@"image-scaling"]];
    }
}

@end

@implementation CPButton (NS)

- (void)setBezelStyle:(unsigned)aBezelStyle
{
}

- (unsigned)bezelStyle
{
}

- (void)setBordered:(BOOL)shouldBeBordered
{
    if ((!!(_controlState & CPControlStateBordered)) === shouldBeBordered)
        return;
    
    if (shouldBeBordered)
        _controlState |= CPControlStateBordered;
    else
        _controlState &= ~CPControlStateBordered;

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (BOOL)isBordered
{
    return !!(_controlState & CPControlStateBordered);
}

@end


var CPButtonImageKey                = @"CPButtonImageKey",
    CPButtonAlternateImageKey       = @"CPButtonAlternateImageKey",
    CPButtonTitleKey                = @"CPButtonTitleKey",
    CPButtonAlternateTitleKey       = @"CPButtonAlternateTitleKey",
    CPButtonContentInsetKey         = @"CPButtonContentInsetKey",
    CPButtonBezelInsetKey           = @"CPButtonBezelInsetKey",
    CPButtonBezelColorKey           = @"CPButtonBezelColorKey",
    CPButtonImageAndTitleViewKey    = @"CPButtonImageAndTitleViewKey",
    CPButtonImagePositionKey        = @"CPButtonImagePositionKey",
    CPButtonImageScalingKey         = @"CPButtonImageScalingKey",
    CPButtonIsBorderedKey           = @"CPButtonIsBorderedKey",
    CPButtonBezelStyleKey           = @"CPButtonBezelStyleKey",
    CPButtonImageAndTitleViewKey    = @"CPButtonImageAndTitleViewKey";

@implementation CPButton (CPCoding)

/*!
    Initializes the button by unarchiving data from <code>aCoder</code>.
    @param aCoder the coder containing the archived CPButton.
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    
    if (self)
    {
        _controlSize = CPRegularControlSize;

        [self setImage:[aCoder decodeObjectForKey:CPButtonImageKey]];
        [self setAlternateImage:[aCoder decodeObjectForKey:CPButtonAlternateImageKey]];
        
        [self setTitle:[aCoder decodeObjectForKey:CPButtonTitleKey]];
        [self setAlternateTitle:[aCoder decodeObjectForKey:CPButtonAlternateTitleKey]];
        
        [self setNeedsLayout];
        [self setNeedsDisplay:YES];
    }
    
    return self;
}

/*!
    Archives this button into the provided coder.
    @param aCoder the coder to which the button's instance data will be written.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_image forKey:CPButtonImageKey];
    [aCoder encodeObject:_alternateImage forKey:CPButtonAlternateImageKey];
    
    [aCoder encodeObject:_title forKey:CPButtonTitleKey];
    [aCoder encodeObject:_alternateTitle forKey:CPButtonAlternateTitleKey];
    
    [aCoder encodeInt:_bezelStyle forKey:CPButtonBezelStyleKey];
}

@end
