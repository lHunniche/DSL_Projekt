package dk.klevang.generator

import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IGeneratorContext
import dk.klevang.iotdsl.Board
import dk.klevang.iotdsl.Internet
import dk.klevang.iotdsl.Sensor
import org.eclipse.emf.common.util.EList
import dk.klevang.iotdsl.Frequency

class ConfigGenerator extends AbstractGenerator{
	
	override doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		resource.allContents.filter(Board).forEach[generateConfigFile(fsa)]
	}
	
	
	def generateConfigFile(Board board, IFileSystemAccess2 fsa) {
		fsa.generateFile(board.name + "_" + board.boardType + "_config.py", board.generateConfig)
	
	}
	
	
	def CharSequence generateConfig(Board board) {
		'''
		�board.internet.generateInternetConfigs�


		�board.sensors.generatePins�
		
		
		�board.sensors.generateFilterGranularities�
		
		
		�board.sensors.generateSamplingRates�
		'''
		
	}
	
	
	def CharSequence generateInternetConfigs(Internet internet){
		if(internet !== null) {
		'''
			internet = {
				"ssid": �internet.ssid�,
				"passw": �internet.internetPass�
			}
		'''
		}
	}
	
	
	def CharSequence generatePins(EList<Sensor> sensors) {
		'''
		pins = {
			�FOR sensor: sensors SEPARATOR ","�
			�sensor.addPins�
			�ENDFOR�
		}
		'''
	}
	
	def CharSequence addPins(Sensor sensor) {
		'''
		"�sensor.name�_in": 'P�sensor.sensorSettings.pins.pinIn�',
		"�sensor.name�_out": 'P�sensor.sensorSettings.pins.pinOut�'
		'''
	}
	
	
	def CharSequence generateFilterGranularities(EList<Sensor> sensors) {
		
		'''
		filter_granularities = {
			�FOR sensor: sensors SEPARATOR ","�
			�sensor.addGranularity�
			�ENDFOR�
		}
		'''
		
		
	}
	
	
	def CharSequence addGranularity(Sensor sensor) {
		'''
		"�sensor.name�": �sensor.sensorSettings.filter.filterType.value�
		'''
		
	}

	
	def CharSequence generateSamplingRates(EList<Sensor> sensors) {
		'''
		�FOR sensor: sensors�
			�sensor.generateSamplingRates�
		�ENDFOR�
		default_sampling_rate = 0.5
		'''
	}
	
	
	def CharSequence generateSamplingRates(Sensor sensor) {
		'''
		sampling_rates_�sensor.name� = [
			�FOR condition: sensor.conditions SEPARATOR ","�
			{
				"condition": �condition.condition.value�,
				"rate": �condition.frequency.generateFrequency�
			}
			�ENDFOR�
		]
		'''
	}
	
	
	def double generateFrequency(Frequency frequency) {
		return calcFrequency(frequency.value, frequency.unit)
	
	}
	
	
	def double calcFrequency(int value, String unit) {
		
		if(unit == "second") {
			return value as double;
		}
		else if(unit == "minute") {
			return (value as double)/60;
		}
		else if(unit == "hour"){
			return (value as double)/60/60
		}
		else {
			return 0.5;
		}
	}
	
	
	

}