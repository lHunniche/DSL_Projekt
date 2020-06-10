package dk.klevang.auxil

import org.eclipse.emf.common.util.EList
import dk.klevang.iotdsl.Sensor
import dk.klevang.iotdsl.Board
import java.util.Set

class BoardTemplates {
	
	def static CharSequence generateSamplingLoops(EList<Sensor> sensors)
	{
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
		
		
	def static CharSequence generateSensorInitFunctions(EList<Sensor> sensors){
		if (sensors.empty)
		{
			return 
			'''
			def init_sensors():
				pass
				
				
			'''
		} 
		
		'''
		def init_sensors():
			«FOR sensor: sensors»
			_thread.start_new_thread(start_«sensor.name»_sampling, ())
			«ENDFOR»
			
			
		'''
	}
	
	
	def static CharSequence generateMainFunction(Board board){
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
			«IF board.internet === null && board.sensors.empty»
			pass
			«ENDIF»
			
			
		'''
	}
	
	
	def static CharSequence generateIntermediateSampleFunction() {
		
		'''
		def get_intermediate_sampling_rate(sample_rate_function, count):
			sampling_rate = sample_rate_function()
			seconds = 1/sampling_rate
			intermediate_sampling_rate = seconds/count
			return intermediate_sampling_rate
			
			
		'''
	}
	
	
	def static CharSequence generateFilterFunction(Set<String> filterTypes)
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
	
	
	def static CharSequence generatePostRequestFunction()
	{
		'''
		def post(url, body):
			res = urequests.post(url, headers={"Content-Type": "application/json", "Accept": "application/json"}, json=body)
			res.close()
		'''
	}
	
	
	def static CharSequence generateSampling(Sensor sensor)
	{
		'''
		# This is the method that selects the appropriate sample rate for your «sensor.name»
		def select_«sensor.name»_sampling_rate():
			measure = single_measurement_from_«sensor.name»()
			return cfg.sampling_rates_«sensor.name»(measure)
		    
		    
		'''
	}
	
	
	
	def static CharSequence generateLightSampleFunction(Sensor sensor)
	{
		'''
		def sample_from_«sensor.name»():
			filter_granularity = cfg.filter_granularities["«sensor.name»"]
			intermediate_points = []
			while len(intermediate_points) < filter_granularity:
				light_level = single_measurement_from_«sensor.name»()
			 	intermediate_points.append(light_level)
				intermediate_sampling_rate = get_intermediate_sampling_rate(\
				            select_«sensor.name»_sampling_rate\
				            , filter_granularity)
				time.sleep(intermediate_sampling_rate)
			return «sensor.sensorSettings.filter.filterType.type»(intermediate_points)
			
			
		'''
	}
	
	def static CharSequence generateTempSampleFunction(Sensor sensor)
	{
		'''
		def sample_from_«sensor.name»():
			filter_granularity = cfg.filter_granularities["«sensor.name»"]
			intermediate_points = []
			while len(intermediate_points) < filter_granularity:
				temp = single_measurement_from_«sensor.name»()
			 	intermediate_points.append(temp)
				intermediate_sampling_rate = get_intermediate_sampling_rate(\
				            select_«sensor.name»_sampling_rate\
				            , filter_granularity)
				time.sleep(intermediate_sampling_rate)
			return «sensor.sensorSettings.filter.filterType.type»(intermediate_points)
		
		
		'''
	}

	
	
	
	
	
	
	
		
}