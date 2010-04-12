cdef extern from "agg2/agg_basics.h":
    enum path_commands_e:
        path_cmd_stop "agg::path_cmd_stop"
        path_cmd_move_to "agg::path_cmd_move_to"
        path_cmd_line_to "agg::path_cmd_line_to"
        path_cmd_curve3 "agg::path_cmd_curve3"
        path_cmd_curve4 "agg::path_cmd_curve4"
        path_cmd_curveN "agg::path_cmd_curveN"
        path_cmd_catrom "agg::path_cmd_catrom"
        path_cmd_ubspline "agg::path_cmd_ubspline"
        path_cmd_end_poly "agg::path_cmd_end_poly"
        path_cmd_mask "agg::path_cmd_mask"

