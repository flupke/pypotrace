from potrace._potrace cimport *

cdef str page_svg(potrace_path_s *plist, potrace_bitmap_s *bm)