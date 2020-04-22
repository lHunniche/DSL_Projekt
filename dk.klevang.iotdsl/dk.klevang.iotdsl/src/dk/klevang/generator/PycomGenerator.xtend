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
import dk.klevang.iotdsl.FilterType
import java.util.List
import java.util.Set

class PycomGenerator extends AbstractGenerator{
	
	override doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		resource.allContents.filter(Board).forEach[generateBoardFiles(fsa)]
	}
	
	def generateBoardFiles(Board board, IFileSystemAccess2 fsa) 
	{
		if (board.boardType == "Pycom")
		{
			fsa.generateFile(board.name + "_" + board.boardType + ".py", board.generateFileContent)
		}
	}
	
	def CharSequence generateFileContent(Board board)
	{
		'''
		«board.generateImports»
		«board.generateInternetConnection»
		«board.sensors.generateInitSensors»
		«board.eAllContents.filter(FilterType).map[FilterType f | f.type].toSet.generateFilterFunction»
		«generateIntermediateSampleFunction»
		«board.generateMainFunction»
		«board.sensors.generateSensorInitFunctions»
		«board.sensors.generateSamplingLoops»
		run()
		'''
	}
	
	def CharSequence generateSamplingLoops(EList<Sensor> sensors){
		'''
		«FOR sensor: sensors»
		def start_«sensor.name»_sampling():
			endpoints = cfg.endpoints["«sensor.name»"]
			while True:
				«sensor.name»_sample = sample_from_«sensor.name»()
				for url in endpoints:
					body = {
						"«sensor.name»": «sensor.name»_sample
					}
					post(url, body)
					
					
		«ENDFOR»
		
		'''
	}
	
	def CharSequence generateSensorInitFunctions(EList<Sensor> sensors){
		'''
		def init_sensors():
			«FOR sensor: sensors»
			_thread.start_new_thread(start_«sensor.name»_sampling, ())
			«ENDFOR»
			
			
		'''
	}
	
	def CharSequence generateMainFunction(Board board){
		'''
		def run():
			«IF board.internet !== null»
			connect()
			«ELSE»
			#connect()
			«ENDIF»
			«IF !board.sensors.empty»
			init_sensors()
			«ELSE»
			#init_sensors()
			«ENDIF»
			
			
		'''
	}
	
	def CharSequence generateIntermediateSampleFunction() {
		
		'''
		def get_intermediate_sampling_rate(sample_rate_function, count):
			sampling_rate = sample_rate_function()
			seconds = 1/sampling_rate
			intermediate_sampling_rate = seconds/count
			return intermediate_sampling_rate
			
			
		'''
	}
	

	def CharSequence generateFilterFunction(Set<String> filterTypes)
	{
		'''
		«FOR filterType: filterTypes»
			«IF filterType == "mean"»
				def mean(intermediate_points):
					return sum(intermediate_points)/len(intermediate_points)
					
					
			«ELSEIF filterType == "median"»
				def median(intermediate_points):
				    sorted(intermediate_points)
				    index = int(len(intermediate_points)//2)
				    return intermediate_points[index]
				    
				    
			«ELSE»
				#Filter types go here
			«ENDIF»
		«ENDFOR»
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
		import pycom

		from LTR329ALS01 import LTR329ALS01
		
		import «board.name»_«board.boardType»_config as cfg
		import _thread
		
		pycom.heartbeat(False)
		
		
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
			            wlan.connect(net.ssid, auth=(net.sec, passw), timeout=5000)
			            while not wlan.isconnected():
			                machine.idle()  # save power while waiting
			            print('WLAN connection to ', ssid, ' succesful!')
			            break
			 
			 
			def post(url, body):
				res = urequests.post(url, headers={"Content-Type": "application/json", "Accept": "application/json"}, json=body)
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
	
	def CharSequence generateSampling(Sensor sensor)
	{
		'''
		# This is the method that selects the appropriate sample rate for your «sensor.name»
		def select_«sensor.name»_sampling_rate():
			measure = single_measurement_from_«sensor.name»()
			cfg.sampling_rates_«sensor.name».sort(key=lambda x: x["condition"], reverse=True)
			for sampling_rate in cfg.sampling_rates_«sensor.name»:
				if sampling_rate["condition"] < measure:
					return sampling_rate["rate"]
			return cfg.default_sampling_rate
		    
		«sensor.generateSingleMeasurement»
		    
		    
		'''
	}
	
	def CharSequence generateSingleMeasurement(Sensor sensor) {
		switch sensor.sensorType{
			Light: sensor.generateSingleLightMeasurement
			Temp: sensor.generateSingleTempMeasurement
		}
	}
	
	def CharSequence generateSingleLightMeasurement(Sensor sensor) {
		'''
		def single_measurement_from_«sensor.name»():
			return als.light()[0]
		'''
	}
	
	def CharSequence generateSingleTempMeasurement(Sensor sensor) {
		'''
		def single_measurement_from_«sensor.name»():
			return get_deg_c()
		'''
	}
	
	
	
	
	
	def CharSequence initLight(Sensor sensor)
	{
		'''
		# This method initialises the Light sensor on your PyCom device
		def init_light(als_sda=cfg.pins["«sensor.name»_in"], als_scl=cfg.pins["«sensor.name»_out"]):
		    als = LTR329ALS01(sda=als_sda, scl=als_scl)
		    return als
		    
		als = init_light()
		
		
		«sensor.generateSampling»
		
		
		«sensor.generateSampleFunction»
		'''
	}
	
	def CharSequence generateSampleFunction(Sensor sensor)
	{
		switch sensor.sensorType {
			Light: sensor.generateLightSampleFunction
			Temp: sensor.generateTempSampleFunction
			Barometer: sensor.generateBarometerSampleFunction
			Pier: sensor.generatePierSampleFunction
			Accelerometer: sensor.generateAccelerometerSampleFunction
			Humidity: sensor.generateHumiditySampleFunction
		}
	}
	
	def CharSequence generateLightSampleFunction(Sensor sensor)
	{
		'''
		def sample_from_«sensor.name»():
			filter_granularity = cfg.filter_granularities["«sensor.name»"]
			intermediate_points = []
			while len(intermediate_points) < filter_granularity:
				light_level = als.light()[0]
			 	intermediate_points.append(light_level)
				intermediate_sampling_rate = get_intermediate_sampling_rate(\
				            select_«sensor.name»_sampling_rate\
				            , filter_granularity)
				time.sleep(intermediate_sampling_rate)
			return «sensor.sensorSettings.filter.filterType.type»(intermediate_points)
			
			
		'''
	}
	
	
	def CharSequence generateTempSampleFunction(Sensor sensor)
	{
		'''
		def sample_from_«sensor.name»():
			filter_granularity = cfg.filter_granularities["«sensor.name»"]
			intermediate_points = []
			while len(intermediate_points) < filter_granularity:
				temp = get_deg_c()
			 	intermediate_points.append(temp)
				intermediate_sampling_rate = get_intermediate_sampling_rate(\
				            select_«sensor.name»_sampling_rate\
				            , filter_granularity)
				time.sleep(intermediate_sampling_rate)
			return «sensor.sensorSettings.filter.filterType.type»(intermediate_points)
		
		
		'''
	}
	
	def CharSequence generateHumiditySampleFunction(Sensor sensor)
	{
		'''
		#HUMIDITY NOT YET SUPPORTED, SORRY
		'''
	}
	
	def CharSequence generatePierSampleFunction(Sensor sensor)
	{
		'''
		#PIER NOT YET SUPPORTED, SORRY
		'''
	}
	
	def CharSequence generateAccelerometerSampleFunction(Sensor sensor)
	{
		'''
		#ACCELEROMETER NOT YET SUPPORTED, SORRY
		'''
	}
	
	def CharSequence generateBarometerSampleFunction(Sensor sensor)
	{
		'''
		#BAROMETER NOT YET SUPPORTED, SORRY
		'''
	}
	
	def CharSequence somemethod(Board board)
	{
		
	}
	
	def CharSequence initTemp(Sensor sensor)
	{
		'''
		# This method initialises the Temperature sensor on your PyCom device
		def init_temp(temp_sda=cfg.pins["«sensor.name»_in"], temp_scl=cfg.pins["«sensor.name»_out"]):
		    adc = machine.ADC()
		    apin = adc.channel(pin=temp_sda)
		    power = Pin(temp_scl, mode=Pin.OUT)
		    power.value(1)
		    return apin
		
		apin = init_temp()
		
		«initTempUtil»
		
		«sensor.generateSampling»
		
		«sensor.generateSampleFunction»
		'''
	}
	
	def CharSequence initTempUtil(){
		'''
		def get_celcius_from_mv(mv):
		    return (mv - 500.0) / 10.0
		
		def get_deg_c():
		    mv = apin.voltage()
		    deg_c = get_celcius_from_mv(mv)
		    return deg_c
		'''
	}
	
	
	def CharSequence initBarometer(Sensor sensor)
	{
		'''
		#BAROMETER NOT YET SUPPORTED, SORRY
		'''
	}
	
	
	def CharSequence initPier(Sensor sensor)
	{
		'''
		#PIER NOT YET SUPPORTED, SORRY
		'''
	}
	
	
	def CharSequence initAccelerometer(Sensor sensor)
	{
		'''
		#ACCELEROMETER NOT YET SUPPORTED, SORRY
		'''
	}
	
	
	def CharSequence initHumidity(Sensor sensor)
	{
		'''
		#HUMIDITY NOT YET SUPPORTED, SORRY
		'''
	}
	
	
	
	
	
}