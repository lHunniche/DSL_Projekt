def median(intermediate_points):
    sorted(intermediate_points)
    index = int(len(intermediate_points)/2)
    return intermediate_points[index]

def mean(intermediate_points):
    return sum(intermediate_points)/len(intermediate_points)


def get_intermediate_sampling_rate(sample_rate_function, count):
        sampling_rate = sample_rate_function()
        seconds = 1/sampling_rate
        intermediate_sampling_rate = seconds/count
        return intermediate_sampling_rate