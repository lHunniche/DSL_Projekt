from network import WLAN
import urequests

import machine
from machine import Pin
import time
import pycom

# Light sensor libraries
from LTR329ALS01 import LTR329ALS01

import board_config as cfg
import _thread

pycom.heartbeat(False)

def connect():
    passw = cfg.internet["passw"]
    ssid = cfg.internet["ssid"]
    wlan = WLAN(mode=WLAN.STA)
    nets = wlan.scan()
    for net in nets:
        print(net.ssid)
        if net.ssid == ssid:
            print(ssid, ' found!')
            wlan.connect(net.ssid, auth=(net.sec, passw), timeout=5000)
            while not wlan.isconnected():
                machine.idle()  # save power while waiting
            print('WLAN connection to ', ssid, ' succesful!')
            break


def post(url, body):
    res = urequests.post(url, headers={
                         "Content-Type": "application/json", "Accept": "application/json"}, json=body)
    res.close()

#____________ LIGHT SENSOR CONFIGURATIONS _____________#


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

"""
#TODO: Switch to this method
def select_sampling_rate():
    measure = 100
    for sampling_rate in sampling_rates.sort(key=lambda x: x["condition"], reverse=True):
        if sampling_rate["condition"] > measure:
            return sampling_rate["rate"]
    return default_sampling_rate
"""

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
        intermediate_sampling_rate = get_intermediate_sampling_rate(\
            get_als_sampling_rate\
            , filter_granularity)
        time.sleep(intermediate_sampling_rate)
    return median(intermediate_points)


def start_light_sampling():
    endpoints = cfg.endpoints["light"]
    while True:
        light_sample = get_light_sample()
        for url in endpoints:
            body = {
                "light": light_sample
            }
            post(url, body)

#__________ TEMP SENSOR CONFIGURATIONS _____________ #


def init_temp(temp_sda=cfg.pins["temp_sda"], temp_scl=cfg.pins["temp_scl"]):
    adc = machine.ADC()
    apin = adc.channel(pin=temp_sda)
    power = Pin(temp_scl, mode=Pin.OUT)
    power.value(1)
    return apin


apin = init_temp()


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
        intermediate_sampling_rate = get_intermediate_sampling_rate( \
            get_temp_sampling_rate \
            ,filter_granularity)
        time.sleep(intermediate_sampling_rate)
    return mean(intermediate_points)


def start_temp_sampling():
    endpoints = cfg.endpoints["temp"]
    while True:
        temp_sample = get_temp_sample()
        for url in endpoints:
            body = {
                "temp": temp_sample
            }
            post(url, body)


# ____________ UTILITY FUNCTIONS ______________#
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

# _________ MAIN AND RUN METHODS _________ #
def init_sensors():
    _thread.start_new_thread(start_light_sampling, ())
    _thread.start_new_thread(start_temp_sampling, ())


def run():
    connect()
    init_sensors()

run()
