  
'''
THIS IS AN EXAMPLE WEBSERVER THAT WILL BE GENERATED (WS1 IN THIS CASE)
'''
from flask import Flask, request, jsonify, make_response
app = Flask(__name__)

@app.route("/tempdata", methods=["POST"])
def tempdata():
  body = response.get_json()
  temp = body.get("temp")
  _file = open("tempdata.csv", "a")
  _file.write(temp + "\n")
  _file.close()
  return "Submitted " + temp + " to file. "

@app.route("/lightdata", methods=["POST"])
def lightdata():
  body = response.get_json()
  light = body.get("light")
  _file = open("lightdata.csv", "a")
  _file.wirte(light + "\n")
  _file.close()
  return "Submitted " + light + " to file."
  pass

