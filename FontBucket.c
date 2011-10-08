/***********************************************************************

FontBucket.c

Purpose:    FontBucket support file. Include this file in your project to
	    support FontBucket.

Copyright � 2000 Hands High Software
All Rights Reserved

The code in this file may be freely copied, distributed and used without 
compensation to	 Hands High Software, Inc. or its permission.


API Version: 1.3

File Version: 1.30

History:

1.11	Modified _WhichFont per Joel Shafer to prevent returning a font of
	a different style.
	Added device check and type to FMType	

1.20	Added Sony support items FB_SONY_SUPPORT.
	Changed HANDERA_SUPPORT to FB_HANDERA_SUPPORT
	Fix FmInit so that it looks for latest version of FB in case one
	is in ROM

1.30	Changed the info functions to return an FmFontInfoType, so that in
	the future if this type expands, it will not require client code
	modifications. Added the fontIndex as a returned piece of info.
	
	
************************************************************************/

#include "PalmOS.h"
#include "FontBucket.h"
#include "FntGlue.h"

#ifdef FB_SONY_SUPPORT
#include "SonyCLIE.h"
#endif

#ifdef FB_HANDERA_SUPPORT
// MAX : s/VGA/Vga/
#include "Vga.h"
#endif

#define kLaunchFlags		   0

#ifdef FB_HANDERA_SUPPORT
    #define kSysFontCount	    8
#else
    #define kSysFontCount	    4
#endif

// private structures

typedef struct {
    UInt16   version;
    UInt16   numberOfFonts;
    UInt16   fontIndex;
    UInt8    fontSize;
    UInt8    fromSublaunch;
    Err	     err;
    FmFontID fmFontId;
    FontID   fontId;
    FontID   first;
    FontID   last;
    Char     name[kMaxFontNameSize];
    Char     style[kMaxFontStyleSize];
    MemHandle h;
} FmParamType, *FmParamPtr;

typedef struct {
    UInt32 first;
    UInt32 last;
} FmInitParamType, *FmInitParamPtr;

typedef struct {
    FontID font;
    char style[2]; // whatever the maximum size is for a system style string in all translations. Should be one character. See FontBucket.r
} FontItemType, *FontItemPtr;

// private statics

#define systemFontMask	    0xff000000L
#define systemFontHiBit	    0x80000000L


// private functions

static void _FmGetSystemFontInfo(FmPtr fmPtr, FontID fontId, FmFontInfoType *info);
static Err _FmCallFontBucket(FmPtr fmPtr,  FmLaunchCodes code,	FmParamType *params);
static FontID _WhichFont(FontItemPtr fntArray, UInt16 count, UInt16 size, const char *style, Boolean *exact);
static FontID _FmToSystemFont(FmPtr fmPtr, FmFontID fmID);
static FmFontID _FmToFmFont(FontID font);

/***********************************************************************

FmInit

Purpose:	Initializes the FontManager.

		Call this once before using any fonts, probably in
		your startup code. This fuction initializes a table in
		the storage heap that stores mappings between FontIDs
		and fonts in the database. The maximum size that this
		table will require is 768 bytes of storage memory.

Preconditions:	

Input:		firstFont   - the first font to use in the range of fonts 
		    defined. Many applications aleady use 128. 129 is
		    used by FontHack, so if you use it and someone has
		    FontHack installed, it may act
		    strange. kDefaultFontStart is the lowest number
		    you should use.  Specify kDefaultFontStart to get
		    the default minimum. Specify kNoFontRangeSpecified
		    the default as well.
		    
		lastFont   - the last font to use in the range of fonts.
		    the maximum is 255. Specify kDefaultFontMax to get
		    the default max.  Specify kNoFontRangeSpecified
		    for no absolute range.
		    
		    Note that you MUST allocate a range of at least 3
		    fonts, and you are encouraged to allocate a range
		    of more.  Also, there is a bug in Palm OS's less
		    than 3.5 that does not count custom fonts
		    correctly. Our work-around requires that we never
		    return the "lastFont" value that you specify, so
		    take that into account too.

		    Also note that Handera mapped its VGA system fonts
		    to 0xE0 and above, so if you use font IDs in that
		    range, you might write over the VGA fonts.
		    
		fromSubLaunch - True if this is getting initialized from
		    a sub-launched application.  If you are
		    initializing normally, set this to false. For the
		    rare case when a sub-launched application makes
		    use of FontBucket, the sub-launched app should set
		    this to true.

Output:		fmPtr - pointer to the FmType struct.

		    This struct is used for all subsequent
		    calls. Treat it as a private token that you must
		    pass to each FontBucket routine.

Returns: errFontInvalidRange if firstFont and lastFont are not within
		the range of kDefaultFontStart to kDefaultFontMax or
		kNoFontRangeSpecified.

************************************************************************/

Err FmInit(FmPtr fmPtr,	 FontID firstFont,  FontID lastFont, Boolean fromSubLaunch)
{
  UInt32  value;
  FmParamType params;
  DmSearchStateType state;
  Err err = 0;
  UInt32 romVersion;
    
  FtrGet (sysFtrCreator, sysFtrNumROMVersion, &romVersion);
  err = FtrGet(sysFtrCreator, sysFtrNumEncoding, &value);
    
  if (value == charEncodingCP932){ // Japenese , double byte chars
    fmPtr->localID = 0;
  } else {
    params.first   = firstFont;
    params.last    = lastFont;
    params.fromSublaunch = fromSubLaunch;
    params.err     = 0;
    params.version = kFontBucketVersion;

      
    // needs to be card independent, in case they put it on a Handspring card
    err = DmGetNextDatabaseByTypeCreator(true, &state, sysFileTApplication, 'FMGR', true, &fmPtr->card, &fmPtr->localID);
	
    fmPtr->device = fmStd;
	
#ifdef FB_HANDERA_SUPPORT
    {
      UInt32 version;
	    
      if (_TRGVGAFeaturePresent (&version)) {
	fmPtr->device = fmHandera;
      }
    }
#endif
	
#ifdef FB_SONY_SUPPORT
    {
      SonySysFtrSysInfoType *sonyInfo;

      if (romVersion < sysMakeROMVersion(5,0,0,0,0) &&	// We support OS 5 hi-res, so we don't care about the rest really
	  FtrGet(sonySysFtrCreator, sonySysFtrNumSysInfoP, (UInt32*)&sonyInfo) == 0 &&    
	  sonyInfo && 
	  (sonyInfo->libr & sonySysFtrSysInfoLibrHR) && 
	  (SysLibFind (sonySysLibNameHR, &fmPtr->sonyHiResLib) == 0)) {
	fmPtr->device = fmSony;
      } else {
	fmPtr->sonyHiResLib = 0;
      }
    }
#endif
				       
    if (!err) {
      err = _FmCallFontBucket (fmPtr, FmInitFontLaunchCode, &params);
    }
	
    if (err != 0) {
      fmPtr->localID = 0;
    } 
  }
  return err;
} /* FmInit */

/***********************************************************************

FmSelectFont

Purpose:	Puts up the FontManager font dialog or the standard font dialog
		if the localID is 0.

Preconditions:	

Input:		fmPtr - FontBucket token (See FmInit)
		fmFontID - The previously selected Id, or kNoFmFontID (Initial value).
		This will be highlighted in the font selector dialog.
		    
Output:		fmFontID - The newly selected font. 

Return:		True  - If the selectedID was changed
		False - If the selectedID stayed the same

************************************************************************/

Boolean FmSelectFont (FmPtr fmPtr, FmFontID* fmFontId) 
{
    UInt32	    originalFontID;
    Boolean	    changed = false;
    FmParamType	    params; 
    Err		    err;   
    Boolean	    isInSonyHiRes = false;
 
 
    #ifdef FB_SONY_SUPPORT
	if (fmPtr->sonyHiResLib) {
	    UInt32 width, height, depth;
	    Boolean color;
	    
	    HRWinScreenMode (fmPtr->sonyHiResLib, winScreenModeGet, &width, &height, &depth, &color);
	    if (width == 320) {
		isInSonyHiRes = true;
	    }
	}
    #endif
   
    originalFontID = *fmFontId;

    if (fmPtr->localID 
    
	#ifdef FB_SONY_SUPPORT
	    && !(isInSonyHiRes && fmPtr->preventSonyHiRes)  // FB will work in hi res mode if the app is ready for it
	#endif
    
	    ) {
	
	params.fmFontId = *fmFontId;   
	params.version = kFontBucketVersion;
	params.err = 0;

	err = _FmCallFontBucket (fmPtr, FmSelectFontLaunchCode, &params);
	    
	if (!err) {
	    *fmFontId = params.fmFontId;
	    if (originalFontID != *fmFontId) {
		changed = true;
	    }
	} 
    } else {
	FontID sysFontId;
	
	#ifdef FB_SONY_SUPPORT
	    if (isInSonyHiRes && fmPtr->preventSonyHiRes) {
		isInSonyHiRes = false;
	    }
	    
	    if (isInSonyHiRes) {
	        // MAX ajout du "enum"
		sysFontId = (FontID) HRFontSelect (fmPtr->sonyHiResLib, (enum hrFontID)_FmToSystemFont (fmPtr, *fmFontId));
	    }
	#endif
	
	if (!isInSonyHiRes) {
	    sysFontId = FontSelect(_FmToSystemFont (fmPtr, *fmFontId));
	}
	
	*fmFontId = _FmToFmFont(sysFontId);
	if (originalFontID != *fmFontId) {
	    changed = true;
	}
    }
    
    return changed;    
} /* FmSelectFont */

/***********************************************************************

FmUseFont

Purpose: Returns a unique FontID that is mapped to the FmFontId passed
	       in. It also allocates locks the font down in memory.


Preconditions:	

Input:		fmPtr - FontBucket token. (See FmInit)
		    
		fmFontId - obtained from the FmSelectFont call or some
		    other call.  This id will be mapped to the
		    returned FontID in the table that was created by
		    the FmInit call.

Output:		fontID ( call FntSetFont with this fontID )

Returns:	Error if the function failed. 

		Might return errFontTableOutOfSlots if you have used
		more fonts than our available without calling
		FmFreeFont on them. You can use a maximum of 126 fonts
		at any one time.
		
		Also dmErrUniqueIdNotFound resulting if the FmFontId
		could not be found.
		

************************************************************************/

Err FmUseFont(FmPtr fmPtr, FmFontID fmFontId, FontID *fontID)
{
    FmParamType	    params;
    Err		    err = 0;

	

    if (fmPtr->localID) {
	params.fmFontId	  = fmFontId;
	params.fontId	  = FntGlueGetDefaultFontID(defaultSmallFont);
	params.err	  = 0;
	params.version	  = kFontBucketVersion;
	
	*fontID = FntGlueGetDefaultFontID(defaultSmallFont);
	
	err = _FmCallFontBucket (fmPtr, FmUseFontLaunchCode, &params);
	
	if (!err) {
	    *fontID = params.fontId;
	}
    } else {
	*fontID = _FmToSystemFont (fmPtr, fmFontId);
    }
    return err;
} /* FmUseFont */

/***********************************************************************

FmFreeFont

Purpose: Free's a font from the FmUseFont's internal table of active
		fonts. You must call this on every font you use before
		exiting the application.
		
		Don't free a font that is in use. In particular, if a
		field is using the font, don't free it, even if you
		never draw the field again, because when the field
		gets deallocated, the system tries to validate it, and
		the font change could cause the validation code to
		crash. The right thing to do is to set the field's
		font to some other font before freeing the font.

Preconditions:	

Input:		fmPtr - FontBucket token. (See FmInit)
		    
		fontId - the FontID you wish to free ( obtained using
		FmUseFont )

Output:		none

Returns:	Error. dmErrUniqueIdNotFound resulting if the FmFontId
		could not be found.

************************************************************************/

Err FmFreeFont(FmPtr fmPtr, FontID fontId)
{
    FmParamType	 params;
    Err		 err = 0;	    

    if (fmPtr->localID) {
	params.err = 0;
	params.fontId = fontId;
	params.version = kFontBucketVersion;
	
	err = _FmCallFontBucket (fmPtr, FmFreeFontLaunchCode, &params);
    }
    return err; 
} /* FmFreeFont */

/***********************************************************************

FmClose

Purpose:	Frees memory allocated for the font table during FmInit.
		If you do not call FmFreeFont on each font, it will
		return an error, but will still free the memory.
		
		Call this function when your application quits.

Preconditions:	

Input:		fmRetPtr - Holds any error generated by this call. (See FmInit)
		    Possible Error : errFontNotFree resulting if 
		    the fonts use count and free count do not match.

Output:		none

Returns:	none

************************************************************************/

Err FmClose (FmPtr fmPtr)
{
    FmParamType params;
    Err		err = 0;

    if (fmPtr->localID) {
	params.err = 0;
	params.version = kFontBucketVersion;

	err = _FmCallFontBucket (fmPtr, FmCloseLaunchCode, &params);
    }

    return err;
} /* FmClose */

/***********************************************************************

FmValidFont

Purpose: Determines if the given id is still vaild ( does it still
		exist on the device ). You can call this during your
		startup code, to verify that the font you saved from
		the previous user session is still a valid font.
		
		Note that if for some reason FontBucket gets removed
		by the user, this will always return valid, because
		any saved FmFontIDs will be converted to stdFont in
		this case.

Preconditions:	none

Input:		fmPtr - Input token. (See FmInit)
		    
		fmFontId   - the FontID to be validated

Output:		none

Returns:	Error.

		Possible Error: dmErrUniqueIdNotFound resulting if the
		FmFontId could not be found.


************************************************************************/

Err FmValidFont(FmPtr fmPtr, FmFontID fmFontId)
{
    FmParamType	 params;
    Err		 err = 0;
	
    if (fmPtr->localID) {
	params.err = 0;
	params.fmFontId = fmFontId;
	params.version	= kFontBucketVersion;

	err = _FmCallFontBucket (fmPtr, FmValidateFontLaunchCode, &params);
    }
    return 0;
} /* FmValidFont */

/***********************************************************************

FmFontName

Purpose:	A convience method to retrieve the name of the font for
		a specific id.

Preconditions:	

Input:		fmPtr	 - FontBucket token. (See FmInit)

		id	 - the selectedId obtained from ( FmSelectFont )

		name	 - a pointer to the buffer to hold the name of the
			   font.  Allocate at least kMaxFontName
			   bytes.

Output:		none

Returns:	Error if an error occurred.

************************************************************************/

Err FmFontName (FmPtr fmPtr, FmFontID fmFontId, Char *name)
{
    FmParamType	 params;
    Err		 err = 0;
    FontID	 fontId;
    
    *name = 0;
    if (fmPtr->localID) {
	params.err = 0;
	params.fmFontId = fmFontId;
	params.version	= kFontBucketVersion;
	
	err = _FmCallFontBucket (fmPtr, FmNameLaunchCode, &params);
	
	if (!err) {
	    StrCopy(name, params.name);
	}
    } else {
	FmFontInfoType info;
	
	fontId = _FmToSystemFont (fmPtr, fmFontId);
	
	_FmGetSystemFontInfo (fmPtr, fontId, &info);
	
	StrCopy (name, info.fontName);
    }
    return err;
} /* FmFontName */

/***********************************************************************

FmGetFMFontIdFromName

Purpose: A convience method to retrieve the selectedID of the font for
		a specific name. If the font is not found, the closest
		possible font will by found using the following
		algorithm and errFontNotFound will be returned:
		
		1) If fonts matching the name (not case sensitive)
		   exist, it will choose one of those fonts. Otherwise
		   it will select a system font.
		   
		2) If it can then find fonts with matching sizes, it
		   will choose one of those fonts. Otherwise, it will
		   attempt to find a font that is larger. If no larger
		   font exists, it will find one smaller.
		   
		3) It will then try to find a font with a matching
		   style. If none exists, it will match the first one
		   it comes to, which would be the plain version of
		   the font if one exists.

Preconditions:	none

Input:		fmPtr	 - FontBucket token. (See FmInit)
		name	 - a pointer to the NULL terminated string
		style	 - a style, set to NULL to ignore

		size	 - the pixel size, if you need to match by pixel
			   size too. Set to zero to ignore.

		Note, to search by style, you must also specify a
		size. If you specify a size of 0, the style will be
		ignored and only the name will be matched with the
		first occurrence of that name.
		
Output:		fmFontID - the corresponding fmFontID, or zero if none
			 matces.

Returns:	errFontNotFound if not found.
		A different error if some other problem happens.

************************************************************************/

Err FmGetFMFontIdFromName (FmPtr fmPtr, const Char *name, FmFontID* fmFontId, const Char* style /* = NULL */, UInt16 size /* = 0 */)
{
    FmParamType params;
    Err		err = 0;
    Char fontString[kMaxFontNameSize];
    
    if (fmPtr->localID) {
	params.err = 0;
	StrCopy (params.name, name);
	*fmFontId = 0;
	
	params.version = kFontBucketVersion;
	params.fontSize = size;
	params.err = 0;
	
	if (style) {
	    StrCopy (params.style, style);
	} else {
	    params.style[0] = 0;
	}
	
	err = _FmCallFontBucket (fmPtr, FmIdLaunchCode, &params);
	
	*fmFontId = params.fmFontId;	// even if there is an error, it will return something close
	
	return err;
    } else {
	FontID font;
	Boolean matched, exact;
    
	FontItemType fnt[kSysFontCount];
	    
	// match a system font	
	SysCopyStringResource (fontString, PalmFontNameString);	    
	matched = (StrCaselessCompare (name, fontString) == 0);
	
	if (size == 0) {
	    // don't check the size, just return first font
	    font = stdFont;
	    *fmFontId = _FmToFmFont(font);
	    
	    if (matched) {
		return 0;
	    } else {
		return errFontNotFound;
	    }
	}
	else {
	    fnt[0].font = stdFont;
	    fnt[0].style[0] = 0;
	    fnt[1].font = boldFont;
	    SysCopyStringResource (fnt[1].style, BoldStyleString);
	    fnt[2].font = largeFont;
	    fnt[2].style[0] = 0;
	    fnt[3].font = largeBoldFont;
	    SysCopyStringResource (fnt[3].style, BoldStyleString);
	    
#ifdef FB_HANDERA_SUPPORT
	    if (fmPtr->device == fmHandera) {
		// Handera fonts are just system fonts, so we use the same font name
		fnt[4].font = VgaBaseToVgaFont(stdFont);
		fnt[4].style[0] = 0;
		fnt[5].font = VgaBaseToVgaFont(boldFont);
		SysCopyStringResource (fnt[5].style, BoldStyleString);
		fnt[6].font = VgaBaseToVgaFont(largeFont);
		fnt[6].style[0] = 0;
		fnt[7].font = VgaBaseToVgaFont(largeBoldFont);
		SysCopyStringResource (fnt[7].style, BoldStyleString);
	    }
#endif

	    font = _WhichFont (fnt, kSysFontCount, size, style, &exact);

	    *fmFontId = _FmToFmFont(font);
	    
	    if (matched && exact) {
		return 0;
	    } else {
		return errFontNotFound;
	    }
	} // else
    } // else
} /* FmGetFMFontIdFromName */ 

/***********************************************************************

_WhichFont

Purpose:	Chooses between the fonts in array, trying to match the
		given parameters. Returns the closest font matched. Also
		returns true in exact if an exact match was found.

Preconditions:	The font array is ordered smallest to largest. Also, you
		must have at least one item in the array.

Input:		fnt Array of font descriptions
		count	    Number of items in the array
		size	    Size to match

		style	    Style to match...uses the first character to do
			    the match

Output:		exact	    Whether the chosen font was an exact match

Returns:	font	    The fontID chosen from the font array

************************************************************************/

static FontID _WhichFont(FontItemPtr fnt, UInt16 count, UInt16 size, const char *style, Boolean *exact)
{
    //Tries to match the requested font
    //returns the font with the nearest size that has the matching style

    UInt16 firstOfSize = 0,
	   foundSize = 0,
	   i;
    FontID oldFont;
    UInt16 compareSize;

#if 0				/* MAX */
    Boolean matchedSize = false,
	    matchedStyle = false;
#endif
    
    for (i = 0; i < count; i++) {
	if (fnt[i].font == largeFont) {
	    compareSize = 12;	// hardcode this value, because largeBoldFont is a 12 point, and we want them to match
	} else {
	    oldFont = FntSetFont (fnt[i].font);
	    compareSize = FntBaseLine();
	    FntSetFont (oldFont);
	}

	    
	if (compareSize > size) {
	    break;
	} else if(style[0] == fnt[i].style[0]) {    // assume we only need to match first char
	    //Style *MUST* match
		foundSize=compareSize;
		firstOfSize = i;
	    
	}
    }
    
    *exact=(foundSize==size);
    
    return fnt[firstOfSize].font;
    
} /* _WhichFont */


/***********************************************************************

FmGetFMFontID

Purpose:	A convience method to retrieve the selectedId. ( see FmUseFont ) 

Preconditions:	

Input:		fmPtr - (See FmInit)
		fontID	 - a valid fontID .
		
Output:		fmFontID    The corresponding FmFontID

Returns:	Error

************************************************************************/

Err FmGetFMFontID(FmPtr fmPtr, FontID fontID, FmFontID* fmFontId)
{
    FmParamType params;
    Err		err = 0;
	       
    if (fmPtr->localID) {
	params.fontId = fontID;
	params.err    = 0;
	params.version = kFontBucketVersion;
	
	err = _FmCallFontBucket (fmPtr, FmFontIdLaunchCode, &params);
	    
	if (!err) {
	    *fmFontId = params.fmFontId;
	}
    } else {
	*fmFontId = _FmToFmFont(fontID);
    }
    return err;
} /* FmGetFMFontID */

/***********************************************************************

FmGetFontCount

Purpose:	A convenience method for retreiving the number of
		valid fonts availiable.

Preconditions:	

Input:		fmPtr - (See FmInit)

Output:		none

Returns:	none

************************************************************************/

UInt16 FmGetFontCount(FmPtr fmPtr)
{
    FmParamType params;
    Err		err;
    
    if (fmPtr->localID) {
	params.err = 0;
	params.numberOfFonts = 0;
	
	err = _FmCallFontBucket (fmPtr, FmNumberOfFontsLaunchCode, &params);

	if (err != 0) {
	    params.numberOfFonts = 0;
	}
    } else {
	params.numberOfFonts = 4;
	
    #ifdef FB_HANDERA_SUPPORT
	if (fmPtr->device == fmHandera) {
	    params.numberOfFonts = 8;
	}
    #endif
	    
    }
    
    return params.numberOfFonts;
} /* FmGetFontCount */

/***********************************************************************

FmGetIndexedFontInfo

Purpose: A convience method for obtaining info on a particular
		font. Use in conjunction with FmGetFontCount to
		iterate through all valid fonts.
		

Preconditions:	

Input:		fmPtr - (See FmInit)
		index - the index of the font
		fontName - the name of the font. Pass NULL if you
			 do not want to retreive this value.
		fontSize - the pt. size of the font. Pass NULL if
			 you do not want to retreive this value.
		fmFontID -  the fmFontID for this font. Pass NULL if
			 you do not want to retreive this value.

Output:		none

Returns:	Error

************************************************************************/

Err FmGetIndexedFontInfo(FmPtr fmPtr, UInt16 index, FmFontInfoType *info)
{
    FmParamType params;
    Err		err = 0;
    
    if (fmPtr->localID) {
	params.err = 0;
	params.fontIndex = index;
	
	err = _FmCallFontBucket (fmPtr, FmInfoLaunchCode, &params);
	
	if (!err) {
	    info->fontSize = params.fontSize;
	    info->fmFontID = params.fmFontId;
	    StrCopy (info->fontName, params.name);
	    StrCopy (info->fontStyle, params.style);
	    info->fontIndex = params.fontIndex;
	}
    
    } else {
	switch (index){
	    
	    case 0: 
	    case 1:
	    case 2: // index happens to match the fontID in these cases
		_FmGetSystemFontInfo (fmPtr, (FontID)index, info);
		break;
				
	    case 3: 
		_FmGetSystemFontInfo (fmPtr, largeBoldFont, info);
		break;
		
	    default:
		#ifdef FB_HANDERA_SUPPORT
		    if (fmPtr->device == fmHandera) {
			switch (index) {
			    case 4:
				_FmGetSystemFontInfo (fmPtr, VgaBaseToVgaFont(stdFont), info);
				break;
				
			    case 5:
				_FmGetSystemFontInfo (fmPtr, VgaBaseToVgaFont(boldFont), info);
				break;
				
			    case 6:
				_FmGetSystemFontInfo (fmPtr, VgaBaseToVgaFont(largeFont), info);
				break;
				
			    case 7:
				_FmGetSystemFontInfo (fmPtr, VgaBaseToVgaFont(largeBoldFont), info);
				break;
			}
		    }
		#endif
		break;
	}
    }
    
    return err;
} /* FmGetIndexedFontInfo */


/***********************************************************************

FmGetFontInfo

Purpose:	Return information about the given font

Preconditions:	

Input:		fmPtr	    Font info block
		fmFontID    The font to find the info on

Output:		The info parameters will be filled in as follows:
		    fontName	The name of the font, NULL to ignore
		    fontStyle	The style of the font, NULL to ignore
		    fontSize	The size of the font, NULL to ignore
		    fontIndex	Index of font, you can use this to
				iterate past the font.

Returns:	none

************************************************************************/

Err FmGetFontInfo(FmPtr fmPtr, FmFontID fmFontID, FmFontInfoType* info)
{
    FmParamType params;
    Err		err = 0;
    
    if (fmPtr->localID) {
	params.err = 0;
	params.fmFontId = fmFontID;
	
	err = _FmCallFontBucket (fmPtr, FmInfoByIDLaunchCode, &params);
	
	if (!err) {
	    info->fontSize = params.fontSize;
	    StrCopy (info->fontName, params.name);
	    StrCopy (info->fontStyle, params.style);
	    info->fontIndex = params.fontIndex;
	}
    
    } else {
	
	FontID font = _FmToSystemFont (fmPtr, fmFontID);

	_FmGetSystemFontInfo (fmPtr, font, info);
    }
    
    return err;
} /* FmGetFontInfo */

/***********************************************************************

FmGetFamilyNames

Purpose:	Return a handle that contains a packed string of all the
		font family names in alphabetic order.

Preconditions:	

Input:		fmPtr	FontManager structure

Output:		none

Returns: Newly created handle that contains the strings. This handle
		may be in storage memory and it is up to you to free
		it.  NULL if there was an error such that the handle
		could not even be created. An incomplete list may be
		returned if memory runs out half way.

************************************************************************/

MemHandle FmGetFamilyNames(FmPtr fmPtr)
{
    MemHandle hRet = NULL;
    FmParamType params;
    Err err;
    
    if (fmPtr->localID) {
	params.err = 0;
	
	err = _FmCallFontBucket (fmPtr, FMFaceListLaunchCode, &params);
	
	if (!err) {
	    hRet = params.h;
	}
    
    } else {
	char buf[10];
	char *p;
	
	SysCopyStringResource (buf, PalmFontNameString);
	
	// no FontBucket installed.
	hRet = MemHandleNew (StrLen (buf) + 1);
	if (hRet) {
	    p = (char*)MemHandleLock (hRet);
	    StrCopy (p, buf);
	    MemHandleUnlock (hRet);
	}	
    }
    
    return hRet;
} /* FmGetFamilyNames */



/***********************************************************************

_FmGetSystemFontInfo

Purpose:	Retrieves info for a system font. Does it without
		calling into FontBucket. 

Preconditions:	

Input:		fmPtr	FontManager structure
		fontID	font to find the info for

Output:		name	    Name of font
		style	    Style of font
		fontSize    Size of font
		fmFontID    fmFontID

Returns:	none

************************************************************************/

static void _FmGetSystemFontInfo(FmPtr fmPtr, FontID fontId, FmFontInfoType *info)
{
    FontID oldFont;
    
    oldFont = FntSetFont (fontId);
    info->fontSize = FntBaseLine();
    FntSetFont (oldFont);
    
    info->fmFontID = _FmToFmFont(fontId);
    info->fontStyle[0] = 0; // start with empty string
    SysCopyStringResource (info->fontName, PalmFontNameString); // default to Palm font name for now.

    switch (fontId){
	case stdFont:
	    info->fontIndex = 0;
	    break;
	    
	case boldFont:
	    SysCopyStringResource (info->fontStyle, BoldStyleString);
	    info->fontIndex = 1;
	    break;
	    
	case largeFont:
	    info->fontIndex = 2;
	    info->fontSize = 12;    // its really 11, but for font family support we fake it as 12
	    break;

	case largeBoldFont:
	    SysCopyStringResource (info->fontStyle, BoldStyleString);
	    info->fontIndex = 3;
	    break;
	    
	default:
	    #ifdef FB_HANDERA_SUPPORT
		if (fmPtr->device == fmHandera) {
		    SysCopyStringResource (info->fontName, VGAFontNameString);
		    if (fontId == VgaBaseToVgaFont (stdFont)) {
			info->fontIndex = 4;
		    }
		    else if (fontId == VgaBaseToVgaFont (boldFont)) {
			info->fontIndex = 5;
			SysCopyStringResource (info->fontStyle, BoldStyleString);
		    } else if (fontId == VgaBaseToVgaFont (largeFont)) {
			info->fontIndex = 6;
		    } else if (fontId == VgaBaseToVgaFont (largeBoldFont)) {
			SysCopyStringResource (info->fontStyle, BoldStyleString);
			info->fontIndex = 7;
		    }
		}
	    #endif
	    break;
    }
} /* _FmGetSystemFontInfo */


/***********************************************************************

_FmCallFontBucket

Purpose:	Calls into FontBucket. Putting this code here reduces
		redundancy and makes the footprint smaller.

Preconditions:	

Input:		none

Output:		none

Returns:	none

************************************************************************/

static Err _FmCallFontBucket(FmPtr fmPtr,  FmLaunchCodes code,	FmParamType *params)
{
    Err err;
    UInt32  result;
    
    err = SysAppLaunch(fmPtr->card, fmPtr->localID, kLaunchFlags, code, params, &result);
    if (err != 0) {
	return err;
    } else if (result != 0) {
	return result;
    } else if (params->err != 0) {
	return params->err;
    }
    return 0;
} /* _FmCallFontBucket */


/***********************************************************************

_FmToSystemFont

Purpose:	Convert an FmFontID to FontID. Deals with Handera's system
		fonts, which maps VGA fonts to 0xE0 and above (OOOPS!).
		
		Our solution is to invert the high bit. This will
		prevent the system from being able to issue a font ID
		of 0x80 (which it better NOT do, since that at a
		minimum is reserved for applications.)

Preconditions:	

Input:		fmFontID    The fmFontID

Output:		none

Returns:	FontID equivalent.

************************************************************************/

static FontID _FmToSystemFont(FmPtr fmPtr, FmFontID fmFontID)
{
    FontID font;
    
    if (fmFontID & systemFontMask) {
	 font = (FontID)(((fmFontID ^ systemFontHiBit) & systemFontMask) >> 24);
    }
    else {
	// this is a font bucket font, so just return the standard system font
	font = FntGlueGetDefaultFontID(defaultSmallFont);
	
#ifdef FB_HANDERA_SUPPORT
	if (fmPtr->device == fmHandera) {
	    font = VgaBaseToVgaFont (font);
	}
#endif

#ifdef FB_SONY_SUPPORT
	if (fmPtr->sonyHiResLib && !fmPtr->preventSonyHiRes) {	// FB will work in hi res mode if the app is ready for it
	    if (fmFontID == 0) {
		font = (FontID)hrStdFont;   // if we expect to handle sony hi res, then this is really the default font
	    }
	}
#endif
    }
    
    return font;
} /* _FmToSystemFont */

/***********************************************************************

_FmToFmFont

Purpose:	Convert a system font to an FmFontID.

Preconditions:	

Input:		FontID

Output:		none

Returns:	FmFontID

************************************************************************/

static FmFontID _FmToFmFont(FontID font)
{
    return (((UInt32)font) << 24) ^ systemFontHiBit;
} /* _FmToFmFont */

//
// Local variables:
// tab-width: 4
// end:
