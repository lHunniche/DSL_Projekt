/*
 * generated by Xtext 2.20.0
 */
package dk.klevang.generator

import org.eclipse.emf.ecore.resource.Resource


import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import dk.klevang.iotdsl.Board
import dk.klevang.iotdsl.Webserver
import java.util.ArrayList

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class IotdslGenerator extends AbstractGenerator {

	val configGenerator = new ConfigGenerator
	val pycomGenerator = new PycomGenerator
	val esp32Generator = new Esp32Generator
	val generatorList = new ArrayList<AbstractGenerator>();
	
	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		generatorList.add(configGenerator)
		generatorList.add(pycomGenerator)
		generatorList.add(esp32Generator)
		generatorList.forEach[doGenerate(resource, fsa, context)]
	
		//resource.allContents.filter(Board).forEach[generateBoardFiles(fsa)]
		//resource.allContents.filter(Webserver).forEach[generateServerFiles(fsa)]
	}
	
	def generateBoardFiles(Board board, IFileSystemAccess2 access2) 
	{
		//throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	def generateServerFiles(Webserver server, IFileSystemAccess2 fsa) 
	{
		fsa.generateFile(server.name+".py", server.generateServer)
	}
	

	def CharSequence generateServer(Webserver server)
	{
	'''
	from flask import Flask, request, jsonify, make_response
	app = Flask(__name__)


	�FOR endpoint: server.getWebEndpoint.split(";")�
		�endpoint.generateEndpoint�
	�ENDFOR�
	
	�server.generateRun�
	'''
	}
	
	
	def CharSequence generateEndpoint(String endpoint)
	{
	'''
	@app.route(�endpoint�, methods=["POST"])
	def get_�endpoint.replace("\"", "").replace("/", "")�():
		_body = request.get_json()
		_args = request.args
		#body_data = _body.get("example")
		#args_data = _args.get("example")
		return "return value", 200
		
		
	'''	
	}
	
	
	def CharSequence generateRun(Webserver server)
	{
	'''
	if __name__ == "main":
		app.run(debug=True, host='0.0.0.0', port=�server.getWebPort.getPort�, threaded=False)
		
	'''	
	}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
}
