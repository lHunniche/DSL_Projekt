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
import dk.klevang.iotdsl.FilterType
import java.util.Set
import dk.klevang.auxil.BoardTemplates
import java.util.List

class Esp32Generator
{
	
	def generateFiles(List<Board> boards, IFileSystemAccess2 fsa) 
	{
		boards.forEach[generateBoardFiles(fsa)]
	}
	
	def generateBoardFiles(Board board, IFileSystemAccess2 fsa) 
	{
		if (board.boardType == "Esp32")
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
		«IF board.internet !== null || board.extension.parent.internet !== null»
		from network import WLAN, STA_IF
		import urequests
		«ENDIF»

		import machine
		from machine import Pin, I2C, ADC
		import time
		
		#Light sensor libraries
		from bh1750 import BH1750 #NEEDS TO BE ON THE BOARD https://github.com/PinkInk/upylib/tree/master/bh1750
		
		import «board.name»_«board.boardType»_config as cfg
		import _thread
		
		'''
	}
	
	def CharSequence generateInternetConnection(Board board)
	{
		if (board.internet === null && board.extension.parent.internet === null)
		{
			return ''''''
		}
		else
		{
		'''
		def connect():
			passw = cfg.internet["passw"]
			ssid = cfg.internet["ssid"]
			wlan = WLAN(STA_IF)
			wlan.active(True)
			nets = wlan.scan()

			for net in nets:
				if str(net[0]) == "b'{}'".format(ssid):
					print(ssid, ' found!')
				wlan.connect(ssid, passw)
				while not wlan.isconnected():
					machine.idle()  # save power while waiting
				print('WLAN connection to ', ssid, ' succesful!')
				break

		«BoardTemplates.generatePostRequestFunction»

			'''
		}
		
	}
	
	
	def CharSequence generateSampling(Sensor sensor)
	{
		'''
		«BoardTemplates.generateSampling(sensor)»
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
			return round(als.luminance(BH1750.ONCE_HIRES_1))
		'''
	}
	
	
	def CharSequence generateSingleTempMeasurement(Sensor sensor) {
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
		# This method initialises the Light sensor on your Esp32 device
		def init_light(als_sda=cfg.pins["«sensor.name»_in"], als_scl=cfg.pins["«sensor.name»_out"]):
			als = BH1750(I2C(sda=Pin(int(als_sda), Pin.IN),scl=Pin(int(als_scl), Pin.OUT)))
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
			adc = machine.ADC(Pin(int(temp_sda),Pin.IN))  
			adc.atten(ADC.ATTN_6DB)
			adc.width(ADC.WIDTH_12BIT)
			power = Pin(int(temp_scl), Pin.OUT)
			power.value(1)
			return adc
		      		
		apin = init_temp()
		
		«initTempUtil»
		
		«sensor.generateSampling»
		
		«sensor.generateSampleFunction»
		'''
	}
	
	
	def CharSequence generateSampleFunction(Sensor sensor)
	{
		switch sensor.sensorType 
		{
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
		    voltage_conversion=((mv*2)/4096)
		    return ((voltage_conversion-0.5)/0.01)
		
		def get_deg_c():
		  	mv = apin.read()
		  	deg_c = get_celcius_from_mv(mv)
		  	return deg_c
		'''
	}
	
	
	
	
	
}