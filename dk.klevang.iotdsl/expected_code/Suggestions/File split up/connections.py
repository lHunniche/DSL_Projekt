from network import WLAN
import urequests
import machine
import board_config as cfg

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