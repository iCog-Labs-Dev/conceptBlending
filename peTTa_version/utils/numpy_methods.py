from hyperon import *
import numpy as np


def np_zeros(*args):
    """Create a numpy array of zeros with the specified shape."""
    print("Zeros args:", args)
    shape = args[0]

    zeros_array = np.zeros(shape)
    print("Initial zeros array:", zeros_array)

    return zeros_array

def np_max(*args):
    """Compute the maximum value in a numpy array."""
    ref_point = args[0]
    # print("Reference point for max:", ref_point)
    objs_val = args[1]
    # print("Objects for max:", objs_val)
    axis = args[2]
    # print("Array for max:", ref_point)

    max_value = np.max([ref_point, np.max(objs_val, axis=axis)], axis=axis)
    # print("Max value:", max_value)

    return max_value
