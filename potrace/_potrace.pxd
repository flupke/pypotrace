cdef extern from "potracelib.h":

    int POTRACE_TURNPOLICY_BLACK
    int POTRACE_TURNPOLICY_WHITE
    int POTRACE_TURNPOLICY_LEFT
    int POTRACE_TURNPOLICY_RIGHT
    int POTRACE_TURNPOLICY_MINORITY
    int POTRACE_TURNPOLICY_MAJORITY
    int POTRACE_TURNPOLICY_RANDOM

    int POTRACE_CURVETO
    int POTRACE_CORNER

    int POTRACE_STATUS_OK
    int POTRACE_STATUS_INCOMPLETE

    ctypedef unsigned long potrace_word
    
    struct potrace_progress_s:
        void (*callback)(double progress, void *privdata)
        void *data
        double min, max
        double epsilon

    struct potrace_param_s:
        int turdsize
        int turnpolicy
        double alphamax
        int opticurve
        double opttolerance
        potrace_progress_s progress

    struct potrace_bitmap_s:
        int w, h
        int dy
        potrace_word *map

    struct potrace_dpoint_s:
        double x, y
    
    struct potrace_curve_s:
        int n
        int *tag
        potrace_dpoint_s *c[3]
    
    struct potrace_path_s:
        int area              
        int sign                         
        potrace_curve_s curve
        potrace_path_s *next
        potrace_path_s *childlist 
        potrace_path_s *sibling   
        void *priv

    struct potrace_state_s:
        int status                       
        potrace_path_s *plist
        void *priv 

    potrace_param_s *potrace_param_default()
    void potrace_param_free(potrace_param_s *p)
    potrace_state_s *potrace_trace(potrace_param_s *param, 
            potrace_bitmap_s *bm)
    void potrace_state_free(potrace_state_s *st)
    char *potrace_version()
