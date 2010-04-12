cdef extern from "agg2/agg_curves.h":
    struct curve4_div "agg::curve4_div":
        void rewind(unsigned)
        int vertex(double *x, double *y)

    curve4_div* new_curve4_div "new agg::curve4_div" (double x1, double y1,
            double x2, double y2,
            double x3, double y3,
            double x4, double y4)
    void delete_curve4_div "delete " (curve4_div* curve)


cdef unsigned num_vertices(curve4_div *curve)
