package dk.klevang.generator

import org.eclipse.xtext.generator.IFileSystemAccess2
import dk.klevang.iotdsl.WebServer
import java.util.List

class WebserverGenerator
{
	
	def generateFiles(List<WebServer> webServers, IFileSystemAccess2 fsa) 
	{
		webServers.forEach[generateServerFiles(fsa)]
	}
	
	
	def generateServerFiles(WebServer server, IFileSystemAccess2 fsa) 
	{
		fsa.generateFile("servers/" + server.name.name + ".py", server.generateServer)
	}
	
	
	def CharSequence generateServer(WebServer server)
	{
	'''
	from flask import Flask, request, jsonify, make_response
	app = Flask(__name__)


	«FOR endpoint: server.webEndpoints»
		«endpoint.name.generateEndpoint»
	«ENDFOR»
	
	«server.generateRun»
	'''
	}
	
	
	def CharSequence generateEndpoint(String endpoint)
	{
	'''
	@app.route("/«endpoint»", methods=["POST"])
	def «endpoint»():
		_body = request.get_json()
		_args = request.args
		#body_data = _body.get("example")
		#args_data = _args.get("example")
		return "return message", 200
		
		
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