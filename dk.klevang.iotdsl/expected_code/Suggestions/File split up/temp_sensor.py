import board_config as cfg
import machine
import connections as con
from machine import Pin
import filter_methods as fm
import time

apin = init_temp()


def init_temp(temp_sda=cfg.pins["temp_sda"], temp_scl=cfg.pins["temp_scl"]):
    adc = machine.ADC()
    apin = adc.channel(pin=temp_sda)
    power = Pin(temp_scl, mode=Pin.OUT)
    power.value(1)
    return apin

def get_temp_sampling_rate():
    default_temp_sampling_rate = cfg.sampling_rates["temp"]
    celcius = get_deg_c()
    if celcius > 40:
        return 0.2
    elif celcius > 20:
        return 0.5
    elif celcius > 0:
        return 0.03
    else:
        return default_temp_sampling_rate


def get_celcius_from_mv(mv):
    return (mv - 500.0) / 10.0


def get_deg_c():
    mv = apin.voltage()
    deg_c = get_celcius_from_mv(mv)
    return deg_c


def get_temp_sample():
    filter_granularity = cfg.filter_granularity["temp"]
    intermediate_points = []
    while len(intermediate_points) < filter_granularity:
        temp = get_deg_c()
        intermediate_points.append(temp)
        intermediate_sampling_rate = fm.get_intermediate_sampling_rate( \
            get_temp_sampling_rate \
            ,filter_granularity)
        time.sleep(intermediate_sampling_rate)
    return fm.mean(intermediate_points)


def start_temp_sampling():
    endpoints = cfg.endpoints["temp"]
    while True:
        temp_sample = get_temp_sample()
        for url in endpoints:
            body = {
                "temp": temp_sample
            }
            con.post(url, body)