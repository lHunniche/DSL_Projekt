endpoints = {
    "light": ["http://www.klevang.dk:19409/lightdata"],
    "temp": ["http://www.klevang.dk:19409/tempdata"]
}
filter_granularity = {
    "light": 10,
    "temp": 20
}
internet = {
    'ssid': 'Xrosby-Wifi',
    'passw': 'boguspass'
}
sampling_rates = {
    "light_default": 0.1,
    "temp_default": 0.3
}

pins = {
    "als_sda": 'P22',
    "als_scl": 'P21',
    "temp_sda": 'P16',
    "temp_scl": 'P19'
}



sampling_rates = [
	{
		"rate": 0.5,
		"condition": 200 
	},
	{
		"rate": 0.2,
		"condition": 300
	},
    {
		"rate": 0.2,
		"condition": 100
	}
]

default_sampling_rate = 0.5

def select_sampling_rate():
    measure = 100
    for sampling_rate in sampling_rates.sort(key=lambda x: x["condition"], reverse=True):
        if sampling_rate["condition"] > measure:
            return sampling_rate["rate"]
    return default_sampling_rate