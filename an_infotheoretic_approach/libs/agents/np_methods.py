from hyperon import *
import numpy as np

def parse_to_list(s: str):
        # remove surrounding parentheses
        s = s.strip("()")
        print("Parsing string to list:", s)
        # split by whitespace
        elements = s.split()
        
        # try to convert each element to int/float if possible, else keep as string
        def convert(x):
            try:
                return int(x)
            except ValueError:
                try:
                    return float(x)
                except ValueError:
                    return x  # leave as string if not numeric
        
        return [convert(el) for el in elements]

def list_to_parse(lst: list) -> str:
    def convert(item):
        if isinstance(item, list):  # recurse for nested lists
            return "(" + " ".join(convert(el) for el in item) + ")"
        else:  # scalar values
            return str(item)
    
    return "(" + " ".join(convert(el) for el in lst) + ")"


def np_dirichlet_sample(metta: MeTTa, *args):
    """Sample from a Dirichlet distribution given concentration parameters."""
    print("Dirichlet sample args:", args)
    conc_param, num_samples = args[0], args[1]

    conc_param = parse_to_list(str(conc_param))
    num_samples = int(str(num_samples))

    samples = np.random.dirichlet(conc_param, num_samples)

    samples = list_to_parse(samples.tolist())

    samples = metta.parse_all(samples)

    return [ValueAtom(samples)]

def np_zeros(metta: MeTTa, *args):
    """Create a numpy array of zeros with the specified shape."""
    print("Zeros args:", args)
    shape = args[0]
    shape = int(str(shape))

    zeros_array = np.zeros(shape)
    print("Initial zeros array:", zeros_array)

    zeros_array = list_to_parse(zeros_array.tolist())
    print("Zeros array as string:", zeros_array)

    zeros_array = metta.parse_all(zeros_array)

    return [ValueAtom(zeros_array)]
