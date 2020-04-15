'''
THIS IS AN EXAMPLE WEBSERVER THAT WILL BE GENERATED (WS1 IN THIS CASE)
'''
from flask import Flask, request, jsonify, make_response
app = Flask(__name__)


@app.route("/lightdata", methods=["POST"])
def get_lightdata():
	_body = request.get_json()
	_args = request.args
	#body_data = _body.get("example")
	#args_data = _args.get("example")
	return "return value", 200
	
	
@app.route("/tempdata", methods=["POST"])
def get_tempdata():
	_body = request.get_json()
	_args = request.args
	#body_data = _body.get("example")
	#args_data = _args.get("example")
	return "return value", 200
	
	

if __name__ == "main":
	app.run(debug=True, host='0.0.0.0', port=19409, threaded=False)
	