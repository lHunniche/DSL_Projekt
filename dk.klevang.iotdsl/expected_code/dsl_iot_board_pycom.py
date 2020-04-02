from network import WLAN
import urequests

import machine
from machine import Pin
import time
import pycom

# Light sensor libraries
from LTR329ALS01 import LTR329ALS01

import _thread

pycom.heartbeat(False)


#---- ENDPOINTS -----#
light_endpoints = ["http://www.klevang.dk:19409/lightdata"]
temp_endpoints = ["http://www.klevang.dk:19409/tempdata"]

#---- FILTER CONFIGURATIONS ----- #
light_filter_count = 10
temp_filter_count = 20


#----- INTERNET VARIABLES -----#
ssid = 'Xrosby-Wifi'
wifi_pass = 'boguspass'

# -------- SAMPLE RATES -----_#
default_light_sampling_rate = 0.1
default_temp_sampling_rate = 0.1


#----------- INTERNET CONFIGURATIONS ------------#

def connect():
    global wifi_pass
    global ssid
    wlan = WLAN(mode=WLAN.STA)
    nets = wlan.scan()
    for net in nets:
        print(net.ssid)
        if net.ssid == ssid:
            print(ssid, ' found!')
            wlan.connect(net.ssid, auth=(net.sec, wifi_pass), timeout=5000)
            while not wlan.isconnected():
                machine.idle()  # save power while waiting
            print('WLAN connection to ', ssid, ' succesful!')
            break


def post(url, body):
    res = urequests.post(url, headers={
                         "Content-Type": "application/json", "Accept": "application/json"}, json=body)
    res.close()

#----------- LIGHT SENSOR CONFIGURATIONS -------------#


def init_light(als_sda='P22', als_scl='P21'):
    als = LTR329ALS01(sda=als_sda, scl=als_scl)
    return als


als = init_light()


def get_als_sampling_rate():
    global default_light_sampling_rate
    lux = get_lux()
    if lux > 200:
        return 0.1
    elif lux > 50:
        return 0.3
    elif lux > 0:
        return 0.01
    else:
        return default_light_sampling_rate


def get_lux():
    global als
    lux = als.light()[0]
    return lux


def get_light_sample():
    global light_filter_count
    intermediate_points = []
    while len(intermediate_points) < light_filter_count:
        light_level = get_lux()
        intermediate_points.append(light_level)
        sampling_rate = get_als_sampling_rate()
        seconds = 1/sampling_rate
        intermediate_sample_rate = seconds/light_filter_count
        time.sleep(intermediate_sample_rate)
        sorted(intermediate_points)
    index = int(len(intermediate_points)/2)
    return intermediate_points[index]


def mean(sample_list, span):
    start = sample_list.length() - span
    collected = 0.0
    for i in range(start, sample_list.length()):
        collected = + sample_list[i]
    return collected / span


def start_light_sampling():
    global light_endpoints
    while True:
        light_sample = get_light_sample()
        for url in light_endpoints:
            body = {
                "light": light_sample
            }
            post(url, body)

#------- TEMP SENSOR CONFIGURATIONS ------#


def init_temp(temp_sda='P16', temp_scl='P19'):
    adc = machine.ADC()
    apin = adc.channel(pin=temp_sda)
    power = Pin(temp_scl, mode=Pin.OUT)
    power.value(1)
    return apin


apin = init_temp()


def get_temp_sampling_rate():
    global default_temp_sampling_rate
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
    global temp_filter_count
    intermediate_points = []
    while len(intermediate_points) < temp_filter_count:
        temp = get_deg_c()
        intermediate_points.append(temp)
        sampling_rate = get_temp_sampling_rate()
        seconds = 1/sampling_rate
        intermediate_sample_rate = seconds/temp_filter_count
        time.sleep(intermediate_sample_rate)
    return sum(intermediate_points)/len(intermediate_points)


def start_temp_sampling():
    global temp_endpoints
    while True:
        temp_sample = get_temp_sample()
        for url in temp_endpoints:
            body = {
                "temp": temp_sample
            }
            post(url, body)

# MAIN AND RUN METHODS
def init_sensors():
    _thread.start_new_thread(start_light_sampling, ())
    _thread.start_new_thread(start_temp_sampling, ())


def run():
    connect()
    init_sensors()

# if __name__ == "main":
run()
