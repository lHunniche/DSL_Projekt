package dk.klevang.generator

import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IGeneratorContext
import java.util.ArrayList
import dk.klevang.iotdsl.Board
import dk.klevang.iotdsl.Internet
import dk.klevang.iotdsl.Sensor
import org.eclipse.emf.common.util.EList
import dk.klevang.iotdsl.Frequency
import java.util.List
import dk.klevang.iotdsl.WebServer
import dk.klevang.iotdsl.EndpointRef
import dk.klevang.iotdsl.Ref
import dk.klevang.iotdsl.Condition
import dk.klevang.iotdsl.And

import dk.klevang.iotdsl.BooleanExp
import dk.klevang.iotdsl.Or
import dk.klevang.iotdsl.Equality
import dk.klevang.iotdsl.impl.AndImpl
import dk.klevang.iotdsl.impl.OrImpl
import dk.klevang.iotdsl.impl.EqualityImpl
import dk.klevang.iotdsl.IntConstant
import dk.klevang.iotdsl.BoolConstant
import dk.klevang.iotdsl.ThisConstant

class ConfigGenerator extends AbstractGenerator{
	var Board _board 
	
	override doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val webServers = resource.allContents.filter(WebServer).toList
		resource.allContents.filter(Board).forEach[generateConfigFile(fsa, webServers)]
	}
	
	
	def generateConfigFile(Board board, IFileSystemAccess2 fsa, List<WebServer> servers) {
		fsa.generateFile(board.name + "_" + board.boardType + "_config.py", board.generateConfig(servers))
	}
	
	
	def CharSequence generateConfig(Board board, List<WebServer> servers) {
		_board= board
		
		'''
		«board.internet.generateInternetConfigs»


		«board.sensors.generateEndpointConfigs(servers)»


		«board.sensors.generatePins»
		
		
		«board.sensors.generateFilterGranularities»
		
		«board.sensors.generateSamplingRates»
		
		'''
		//«board.sensors.generateSamplingRates» SKAL MED IGEN NÅR BOOLEAN EXP VIRKER
		
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
		«IF _board.boardType == 'Pycom'»
		"«sensor.name»_in": 'P«sensor.sensorSettings.pins.pinIn»',
		"«sensor.name»_out": 'P«sensor.sensorSettings.pins.pinOut»'
		
		«ELSEIF _board.boardType == 'Esp32'»
		"«sensor.name»_in": '«sensor.sensorSettings.pins.pinIn»',
		"«sensor.name»_out": '«sensor.sensorSettings.pins.pinOut»'
		
		«ENDIF»
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
		default_sampling_rate = 0.5
		
		«FOR sensor: sensors»
			«sensor.generateSamplingRates»
		«ENDFOR»
		'''
	}
	
	
	def CharSequence generateSamplingRates(Sensor sensor) {
		
		var conditionStrings = new ArrayList<String>
		var rates = new ArrayList<Double>
	
		for (Condition cond : sensor.conditions)
		{
			conditionStrings.add(printBoolExp(cond.getBoolExp))
			var freq = cond.frequency.generateFrequency
			
			//rounding to 3 digits
			freq = ((freq * 1000) as int) 
			freq = freq / 1000
			  
			rates.add(freq)
		}
		
		//key is index, value is boolean expression
		
		'''
		def sampling_rates_«sensor.name»(sensor_value):
			cond_rate_list = []
			
			«FOR pair: conditionStrings.indexed»
				def condition_«pair.key+1»(sensor_value):
					return «pair.value»
				cond_rate_list.append((condition_«pair.key+1», «rates.get(pair.key)»))
				
			«ENDFOR»
			for exp, rate in cond_rate_list:
				if exp(sensor_value) == True:
					return rate
			return default_sampling_rate
			
			
		'''
		
		//return '''#here goes a sample rate :)'''
	}
	
	def String printBoolExp(BooleanExp exp) {
	
		return "" + switch exp {
			And: exp.left.printBoolExp + " and " + exp.right.printBoolExp
			Or: exp.left.printBoolExp + " or " + exp.right.printBoolExp
			Equality: exp.left.printBoolExp + " " + exp.op + " " + exp.right.printBoolExp
			IntConstant: exp.value
			BoolConstant: if (exp.value == 'true') "True" else "False"
			ThisConstant: "sensor_value"
			default: ""
		}
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