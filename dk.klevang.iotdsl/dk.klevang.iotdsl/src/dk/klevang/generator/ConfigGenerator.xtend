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
import dk.klevang.iotdsl.WebEndpoint
import java.util.List
import dk.klevang.iotdsl.WebServer
import dk.klevang.iotdsl.EndpointRef
import dk.klevang.iotdsl.Ref
import java.util.ArrayList

class ConfigGenerator extends AbstractGenerator{
	
	override doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val webServers = resource.allContents.filter(WebServer).toList
		resource.allContents.filter(Board).forEach[generateConfigFile(fsa, webServers)]
	}
	
	
	def generateConfigFile(Board board, IFileSystemAccess2 fsa, List<WebServer> servers) {
		fsa.generateFile(board.name + "_" + board.boardType + "_config.py", board.generateConfig(servers))
	}
	
	
	def CharSequence generateConfig(Board board, List<WebServer> servers) {
		'''
		«board.internet.generateInternetConfigs»


		«board.sensors.generateEndpointConfigs(servers)»


		«board.sensors.generatePins»
		
		
		«board.sensors.generateFilterGranularities»
		
		
		«board.sensors.generateSamplingRates»
		'''
		
	}
	
	def CharSequence generateEndpointConfigs(EList<Sensor> sensors, List<WebServer> servers)
	{	
		'''
		endpoints = {
		«FOR sensor : sensors SEPARATOR ","»
		"«sensor.name»" : [
			«sensor.generateSensorEndpoint(servers)»
			]
		«ENDFOR»
		}
		'''
	}
	
	def CharSequence generateSensorEndpoint(Sensor sensor, List<WebServer> servers)
	{
		val webEndpoints = sensor.endpoints.filter[e | e.dot !== null].toList
		val validServers = servers.filter[server | server.validateServer(webEndpoints)].toList
		val validEndpoints = new ArrayList<String>
		
		for (endpointRef : webEndpoints)
		{
			for (server : validServers)
			{
				for (ref : server.webEndpoints)
				{
					if (endpointRef.dot.endpoint.name == ref.name)
					{
						validEndpoints.add(server.host.host + ":" + server.webPort.port + "/" + ref.name)
					}
				}
			}
		}
		println(validEndpoints)
		
		'''
		«FOR endpoint : validEndpoints SEPARATOR ","»
			"«endpoint»"
		«ENDFOR»
		'''
		/* 
		'''
		«FOR webEndpoint : webEndpoints SEPARATOR ","»
			«FOR webServer : validServers»
				"/«webEndpoint.dot.endpoint.name»"
			«ENDFOR»
		«ENDFOR»
		'''
		 */
	
		
	}
	
	def Boolean validateServer(WebServer server, Iterable<EndpointRef> refs)
	{
		for (EndpointRef endpointRef : refs)
		{
			for (Ref serverRef : server.webEndpoints)
			{
				if (serverRef.name == endpointRef.dot.endpoint.name)
				{
					return true
				} 
			}
		}
		return false
	}
	
	def CharSequence generateInternetConfigs(Internet internet){
		if(internet !== null) {
		'''
			internet = {
				"ssid": «internet.ssid»,
				"passw": «internet.internetPass»
			}
		'''
		}
	}
	
	
	def CharSequence generatePins(EList<Sensor> sensors) {
		'''
		pins = {
			«FOR sensor: sensors SEPARATOR ","»
			«sensor.addPins»
			«ENDFOR»
		}
		'''
	}
	
	def CharSequence addPins(Sensor sensor) {
		'''
		"«sensor.name»_in": 'P«sensor.sensorSettings.pins.pinIn»',
		"«sensor.name»_out": 'P«sensor.sensorSettings.pins.pinOut»'
		'''
	}
	
	
	def CharSequence generateFilterGranularities(EList<Sensor> sensors) {
		
		'''
		filter_granularities = {
			«FOR sensor: sensors SEPARATOR ","»
			«sensor.addGranularity»
			«ENDFOR»
		}
		'''
		
		
	}
	
	
	def CharSequence addGranularity(Sensor sensor) {
		'''
		"«sensor.name»": «sensor.sensorSettings.filter.filterType.value»
		'''
		
	}

	
	def CharSequence generateSamplingRates(EList<Sensor> sensors) {
		'''
		«FOR sensor: sensors»
			«sensor.generateSamplingRates»
		«ENDFOR»
		default_sampling_rate = 0.5
		'''
	}
	
	
	def CharSequence generateSamplingRates(Sensor sensor) {
		'''
		sampling_rates_«sensor.name» = [
			«FOR condition: sensor.conditions SEPARATOR ","»
			{
				"condition": «condition.condition.value»,
				"rate": «condition.frequency.generateFrequency»
			}
			«ENDFOR»
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