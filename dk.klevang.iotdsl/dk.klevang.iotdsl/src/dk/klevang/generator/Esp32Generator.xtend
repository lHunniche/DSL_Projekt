package dk.klevang.generator

import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import dk.klevang.iotdsl.Board
import org.eclipse.emf.common.util.EList
import dk.klevang.iotdsl.Sensor
import dk.klevang.iotdsl.Light
import dk.klevang.iotdsl.Temp
import dk.klevang.iotdsl.Barometer
import dk.klevang.iotdsl.Pier
import dk.klevang.iotdsl.Accelerometer
import dk.klevang.iotdsl.Humidity

class Esp32Generator extends AbstractGenerator{
	
	override doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		resource.allContents.filter(Board).forEach[generateBoardFiles(fsa)]
	}
	
	def generateBoardFiles(Board board, IFileSystemAccess2 fsa) 
	{
		if(board.boardType == "Esp32"){
		fsa.generateFile(board.name + "_" + board.boardType + ".py", board.generateFileContent)
		}
	}
	
	def CharSequence generateFileContent(Board board)
	{
		'''
		«board.generateImports»
		«board.generateInternetConnection»
		«board.sensors.generateInitSensors»
		
		
		def init_sensors():
			«FOR sensor : board.sensors»
			_thread.start_new_thread(start_«sensor.name»_sampling)
			«ENDFOR»
		
		def run():
			connect()
			init_sensors()
		
		if __name__ == "main":
			run()
		'''
	}
	
	def CharSequence generateImports(Board board)
	{
	'''
	«IF board.internet !== null»
	from network import WLAN
	import urequests
	«ENDIF»
	
	import machine
	from machine import Pin
	import time
	from bh1750 import BH1750 #NEEDS TO BE ON THE BOARD https://github.com/PinkInk/upylib/tree/master/bh1750
	
	import «board.name»_«board.boardType»_config as cfg
	import _thread
	'''
	}
	
	def CharSequence generateInternetConnection(Board board)
	{
		if (board.internet === null)
		{
			return ''''''
		}
		else
		{
			'''

			def connect():
			    passw = cfg.internet["passw"]
			    ssid = cfg.internet["ssid"]
			    wlan = WLAN(mode=WLAN.STA)
			    nets = wlan.scan()
			    for net in nets:
			        print(net.ssid)
			        if net.ssid == ssid:
			            print(ssid, ' found!')
			            wlan.connect(net.ssid, auth=(net.sec, wifi_pass), timeout=5000)
			            while not wlan.isconnected():
			                machine.idle() # save power while waiting
			            print('WLAN connection to ', ssid,' succesful!')
			            break
			            
			def post(url, body):
			    res = urequests.post(url, headers={"Content-Type": "application/json","Accept": "application/json"}, json=body)
			    res.close()  
			'''
		}
		
	}
	
	def CharSequence generateInitSensors(EList<Sensor> sensors)
	{
		'''
		«FOR sensor: sensors»
		«sensor.initSensor»
		«ENDFOR»
		'''
	}
	
	def CharSequence initSensor(Sensor sensor)
	{
		switch sensor.sensorType {
			Light: sensor.initLight
			Temp: sensor.initTemp
			Barometer: sensor.initBarometer
			Pier: sensor.initPier
			Accelerometer: sensor.initAccelerometer
			Humidity: sensor.initHumidity
		}
	}
	

	def CharSequence initLight(Sensor sensor)	
	{	
	'''
	
	def init_light(als_sda = «sensor.sensorSettings.pins.pinOut», als_scl = «sensor.sensorSettings.pins.pinIn»):
		als = BH1750(I2C(sda=als_sda,scl=als_scl)) 
		return als
	
	def get_lux():
		lux = round(sensor.luminance(BH1750.ONCE_HIRES_1))
		return lux
	
	«sensor.getSamplingRate»
	
	«sensor.generateSampleFunction»
	'''
	
	}
	def CharSequence initTemp(Sensor sensor)
	{
	'''
	
	def init_temp(temp_sda = «sensor.sensorSettings.pins.pinOut», temp_scl = «sensor.sensorSettings.pins.pinIn»):
		adc = machine.ADC()  
		adc.atten(ADC.ATTN_6DB)
		adc.width(ADC.WIDTH_12BIT)
		apin = adc.channel(pin=temp_sda) 
		power = Pin(temp_scl, mode=Pin.OUT)
		power.value(1)
		return apin
		
	apin = init_temp()
	
	def get_celcius_from_mv(mv):
		voltage_conversion=((mv*2)/4096)
		return ((voltage_conversion-0.5)/0.01)
	
	def get_deg_c():
		mv = apin.read()
		deg_c = get_celcius_from_mv(mv)
		return deg_c
	
	«sensor.getSamplingRate»
	
	«sensor.generateSampleFunction»
	'''
	}
	
	def CharSequence initBarometer(Sensor sensor)
	{
		'''
		 NOT YET SUPPORTED
		'''
	}
	
	def CharSequence initPier(Sensor sensor)
	{
		'''
		 NOT YET SUPPORTED
		'''
	}
	
	def CharSequence initHumidity(Sensor sensor)
	{
		'''
		 NOT YET SUPPORTED
		'''
	}
	
	def CharSequence initAccelerometer(Sensor sensor)
	{
		'''
		 NOT YET SUPPORTED
		'''
	}
	
	def CharSequence getSamplingRate(Sensor sensor)
	{
	var first = sensor.conditions.get(0)
	'''
	
	def get_als_sampling_rate():
		global als
	
		if als.light() «first.condition.op» «first.condition.value» :
			return «first.frequency.value»
		«FOR c: sensor.conditions»
		«IF c.condition != first.condition»
		elif als.light() «c.condition.op» «c.condition.value» :
			return «c.frequency.value»	
		«ENDIF» 
		«ENDFOR»
	'''
	}
	
	
	def CharSequence mean (Sensor sensor)
	{
	'''
	def mean(sample_list, span):
		start = sample_list.length() - span
		collected = 0.0
		for i in range(start, sample_list.length()):
			collected =+ sample_list[i]
		return collected / span
	
	'''	
	} 
	
	
	def CharSequence generateSampleFunction(Sensor sensor)
	{
		switch sensor.sensorType {
			Light: sensor.LightSampleFunction
			Temp: sensor.TempSampleFunction
			Barometer: sensor.BarometerSampleFunction
			Pier: sensor.PierSampleFunction
			Accelerometer: sensor.AccelerometerSampleFunction
			Humidity: sensor.HumiditySampleFunction
		}
	}
	
	def CharSequence LightSampleFunction(Sensor sensor)	
	{
	'''
	def get_light_sample():
		global light_filter_count
		intermediate_points = []
		while len(intermediate_points) < light_filter_count:
			light_level = get_lux()
			intermediate_points.append(light_level)
			time.sleep(get_als_sampling_rate())
			sorted(intermediate_points)
		return intermediate_points[len(intermediate_points)/2]
	
	def start_light_sampling():
		while True:
			light_sample = get_light_sample()
			for url in light_endpoints:
				body = {
					"light": light_sample
				}
				post(url, body)
	'''
	}
	
	def CharSequence TempSampleFunction(Sensor sensor)	
	{
	'''
	def get_temp_sample():
		global temp_filter_count
		intermediate_points = []
		while len(intermediate_points) < temp_filter_count:
			temp_level = get_deg_c()
			intermediate_points.append(temp_level)
			time.sleep(get_temp_sampling_rate())
		return sum(intermediate_points)/len(intermediate_points)
	
	def start_«sensor.name»_sampling():
		global temp_endpoints
		while True:
			temp_sample = get_temp_sample()
			for url in temp_endpoints:
				body = {
					"temp": temp_sample
				}
				post(url, body)	 
	'''
	}
	
	def CharSequence BarometerSampleFunction(Sensor sensor)	
	{
		'''
		 NOT YET SUPPORTED
		'''
	}
	
	def CharSequence PierSampleFunction(Sensor sensor)	
	{
		'''
		 NOT YET SUPPORTED
		'''
	}
	
	def CharSequence AccelerometerSampleFunction(Sensor sensor)	
	{
		'''
		 NOT YET SUPPORTED
		'''
	}
	
	def CharSequence HumiditySampleFunction(Sensor sensor)	
	{
		'''
		 NOT YET SUPPORTED
		'''
	}

	
}