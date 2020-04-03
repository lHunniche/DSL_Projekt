import pycom
import board_config as cfg
import _thread
import filter_methods as fm
import temp_sensor as temp_sensor
import light_sensor as light_sensor
import connections as con

pycom.heartbeat(False)

def init_sensors():
    _thread.start_new_thread(light_sensor.start_light_sampling, ())
    _thread.start_new_thread(temp_sensor.start_temp_sampling, ())


def run():
    con.connect()
    init_sensors()

run()
