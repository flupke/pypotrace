from nose.tools import assert_raises, assert_equal
import numpy as np
import potrace


def test_errors():
    assert_raises(TypeError, potrace.Bitmap, None)
    assert_raises(TypeError, potrace.Bitmap, [1, 2, 3])
    assert_raises(TypeError, potrace.Bitmap, (1, 2, 3))


def test_trace():
    data = np.zeros((32, 32), np.uint32)
    data[8:32-8, 8:32-8] = 1
    bmp = potrace.Bitmap(data)
    path = bmp.trace()
    ref_points = [(8.0, 8.0),
            (16.0, 8.0),
            (24.0, 8.0),
            (24.0, 16.0),
            (24.0, 24.0),
            (16.0, 24.0),
            (8.0, 24.0),
            (8.0, 16.0)
        ]
    points = []
    for curve in path:
        for segment in curve:
            assert segment.is_corner
            points.append(segment.c)
            points.append(segment.end_point)
    assert_equal(points, ref_points)


def test_tree():
    data = np.zeros((32, 32), np.uint32)
    data[8:32-8, 8:32-8] = 1
    data[10:32-10, 10:32-10] = 0
    bmp = potrace.Bitmap(data)
    path = bmp.trace()
    assert_equal(len(path.curves_tree), 1)
    assert_equal(len(path.curves_tree[0].children), 1)
    assert_equal(len(path.curves_tree[0].children[0].children), 0)


if __name__ == "__main__":
    test_errors()
    test_trace()
