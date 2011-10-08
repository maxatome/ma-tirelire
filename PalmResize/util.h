#define SafeMemPtrNew MemPtrNew
#define SafeMemPtrFree( p ) if ( ( p ) != NULL ) MemPtrFree( ( p ) )
