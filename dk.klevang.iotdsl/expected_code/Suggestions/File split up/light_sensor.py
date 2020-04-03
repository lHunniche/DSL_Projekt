# Light sensor libraries
from LTR329ALS01 import LTR329ALS01
import board_config as cfg
import filter_methods as fm
import connections as con
import time

def init_light(als_sda=cfg.pins["als_sda"], als_scl=cfg.pins["als_scl"]):
    als = LTR329ALS01(sda=als_sda, scl=als_scl)
    return als
als = init_light()


def get_als_sampling_rate():
    default_light_sampling_rate = cfg.sampling_rates['light']
    lux = get_lux()
    if lux > 200:
        return 0.1
    elif lux > 100:
        return 0.3
    elif lux >= 0:
        return 1.0
    else:
        return default_light_sampling_rate

def get_lux():
    global als
    lux = als.light()[0]
    return lux


def get_light_sample():
    filter_granularity = cfg.filter_granularity["light"]
    intermediate_points = []
    while len(intermediate_points) < filter_granularity:
        light_level = get_lux()
        intermediate_points.append(light_level)
        intermediate_sampling_rate = fm.get_intermediate_sampling_rate(\
            get_als_sampling_rate\
            , filter_granularity)
        time.sleep(intermediate_sampling_rate)
    return fm.median(intermediate_points)


def start_light_sampling():
    endpoints = cfg.endpoints["light"]
    while True:
        light_sample = get_light_sample()
        for url in endpoints:
            body = {
                "light": light_sample
            }
            con.post(url, body)