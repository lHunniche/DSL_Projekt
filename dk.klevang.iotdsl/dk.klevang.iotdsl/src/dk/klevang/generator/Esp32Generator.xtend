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
			Barometer: println("abe")
			Pier: println("abe")
			Accelerometer: println("abe")
			Humidity: println("abe")
		}
	}
	
	def CharSequence initLight(Sensor sensor)
	{
		
	}
	
	def CharSequence initTemp(Sensor sensor)
	{
		
	}
	
}