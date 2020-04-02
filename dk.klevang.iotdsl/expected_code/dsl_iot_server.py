'''
THIS IS AN EXAMPLE WEBSERVER THAT WILL BE GENERATED (WS1 IN THIS CASE)
'''
from flask import Flask, request, jsonify, make_response
app = Flask(__name__)


@app.route("/tempdata", methods=["POST"])
def tempdata():
    body = request.get_json()
    temp = str(body.get("temp"))
    _file = open("tempdata.csv", "a")
    _file.write(temp + "\n")
    _file.close()
    return "Submitted " + str(temp) + " to file. "


@app.route("/lightdata", methods=["POST"])
def lightdata():
    body = request.get_json()
    light = str(body.get("light"))
    _file = open("lightdata.csv", "a")
    _file.write(light + "\n")
    _file.close()
    return "Submitted " + light + " to file."


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=8081, threaded=True)  # 19409
