package dk.klevang.generator

import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import dk.klevang.iotdsl.WebServer
import dk.klevang.iotdsl.Sensor
import java.util.List

class WebserverGenerator extends AbstractGenerator {
	
	override doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		resource.allContents.filter(WebServer).forEach[generateServerFiles(resource.allContents.filter(Sensor).toList, fsa)]
	}
	
	
	def generateServerFiles(WebServer server,List<Sensor> sensors, IFileSystemAccess2 fsa) 
	{
		fsa.generateFile(server.name.name + ".py", server.generateServer(sensors))
	}
	
	
	def CharSequence generateServer(WebServer server, List<Sensor> sensors)
	{
	'''
	from flask import Flask, request, jsonify, make_response
	import csv
	import json
	import os
	from datetime import datetime
	app = Flask(__name__)


	«FOR endpoint: server.webEndpoints»
		«FOR sensor : sensors»
			«FOR sensorEndpoint : sensor.getEndpoints»
				«IF sensorEndpoint.getDot.getEndpoint.name == endpoint.name»
					«endpoint.name.generateEndpoint(sensor)»
				«ENDIF»
			«ENDFOR»
		«ENDFOR»
	«ENDFOR»
	
	«generateWriteToFile»
	«generateAfterRequest»
	«server.generateRun»
	'''
	}
	
	def CharSequence generateAfterRequest() 
	{
		'''
		@app.after_request
		def after_request(response):
		    response.headers['Access-Control-Allow-Origin'] = "*"
		    response.headers['Access-Control-Allow-Headers'] = "*"
		    return response
		    
		    
		'''	
	}
	
	def CharSequence generateWriteToFile()
	{
		'''
		def write_to_file(filename, headers, body_data):
			now = datetime.now()
			file_exists = os.path.isfile(filename)
			file = open(filename, 'a')
			writer = csv.DictWriter(file,delimiter=',', lineterminator='\n',fieldnames=headers)
			if(not file_exists):
				print("Writing headers")
				writer.writeheader()
			date_time = now.strftime("%Y-%m-%d %H:%M:%S")
			writer.writerow({headers[0]:body_data, headers[1]:date_time})
			
			
		'''
	}
	
	
	def CharSequence generateEndpoint(String endpoint, Sensor sensor)
	{
	var type = sensor.getSensorType
	'''
	@app.route("/«endpoint»", methods=["POST"])
	def «endpoint»():
		_body = request.get_json()
		_args = request.args
		body_data = _body.get("«sensor.name»")
		filename = "«endpoint».csv"
		write_to_file(filename, ['«type.name»', 'date'], body_data)
		return "return value", 200
		
		
	'''	
	}
	
	
	def CharSequence generateRun(WebServer server)
	{
	'''
	if __name__ == "__main__":
		app.run(debug=True, host='0.0.0.0', port=«server.getWebPort.getPort», threaded=False)
		
	'''	
	}
	
}