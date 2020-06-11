package dk.klevang.generator

import org.eclipse.xtext.generator.IFileSystemAccess2
import dk.klevang.iotdsl.Board
import org.eclipse.emf.common.util.EList
import dk.klevang.iotdsl.Sensor
import dk.klevang.iotdsl.Light
import dk.klevang.iotdsl.Temp
import dk.klevang.iotdsl.FilterType
import java.util.Set
import dk.klevang.auxil.BoardTemplates
import java.util.List

class PycomGenerator{
	
	def generateFiles(List<Board> boards, IFileSystemAccess2 fsa) 
	{
		boards.forEach[generateBoardFiles(fsa)]
	}
	
	def generateBoardFiles(Board board, IFileSystemAccess2 fsa) 
	{
		if (board.boardType == "Pycom")
		{
			if (!board.isAbstract)
			{
				fsa.generateFile(board.name + "/" + board.name + "_" + board.boardType + ".py", board.generateFileContent)
			}
			
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
	

	def CharSequence generateSamplingLoops(EList<Sensor> sensors)
	{
		BoardTemplates.generateSamplingLoops(sensors)
	}
	
	
	def CharSequence generateSensorInitFunctions(EList<Sensor> sensors)
	{
		BoardTemplates.generateSensorInitFunctions(sensors)
	}
	

	def CharSequence generateMainFunction(Board board)
	{
		BoardTemplates.generateMainFunction(board)
	}
	

	def CharSequence generateIntermediateSampleFunction() 
	{
		BoardTemplates.generateIntermediateSampleFunction()
	}
	
	
	def CharSequence generateFilterFunction(Set<String> filterTypes)
	{
		BoardTemplates.generateFilterFunction(filterTypes)
	}
	
	
	def CharSequence generateImports(Board board)
	{
		'''
		«IF board.internet !== null || board.extension !== null && board.extension.parent.internet !== null»
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
		 
		 
		«BoardTemplates.generatePostRequestFunction»


		'''
	}
	

	def CharSequence generateSampling(Sensor sensor)
	{
		'''
		«BoardTemplates.generateSampling(sensor)»
		«sensor.generateSingleMeasurement»
		'''
		
	}
	
	
	def CharSequence generateSingleMeasurement(Sensor sensor) 
	{
		switch sensor.sensorType{
			Light: sensor.generateSingleLightMeasurement
			Temp: sensor.generateSingleTempMeasurement
		}
	}
	
	
	def CharSequence generateSingleLightMeasurement(Sensor sensor) 
	{
		'''
		def single_measurement_from_«sensor.name»():
			return als.light()[0]
		'''
	}
	
	
	def CharSequence generateSingleTempMeasurement(Sensor sensor) 
	{
		'''
		def single_measurement_from_«sensor.name»():
			return get_deg_c()
		'''
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
		switch sensor.sensorType 
		{
			Light: sensor.initLight
			Temp: sensor.initTemp
		}
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
	
	
	def CharSequence generateSampleFunction(Sensor sensor)
	{
		switch sensor.sensorType {
			Light: sensor.generateLightSampleFunction
			Temp: sensor.generateTempSampleFunction
		}
	}
	
	def CharSequence generateLightSampleFunction(Sensor sensor)
	{
		BoardTemplates.generateLightSampleFunction(sensor)
	}
	
	
	def CharSequence generateTempSampleFunction(Sensor sensor)
	{
		BoardTemplates.generateTempSampleFunction(sensor)
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
	
}