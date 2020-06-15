package dk.klevang.generator

import dk.klevang.iotdsl.BaseSensor
import dk.klevang.iotdsl.Board
import dk.klevang.iotdsl.OverrideSensor
import dk.klevang.iotdsl.Sensor
import org.eclipse.emf.common.util.EList
import dk.klevang.iotdsl.OverrideBoard
import dk.klevang.iotdsl.BaseBoard

class GeneratorUtil {
	
	static def Board collectInfo(Board board){
		var Board _board
		var EList<Sensor> _sensors
		
		if(board instanceof BaseBoard){
			//Do Nothing
		}
		else if(board instanceof OverrideBoard){
			_board.boardType = board.parent.boardType
			_board.name = board.name
			_board.internet = board.internet
			for (sensor : board.parent.sensors){
				_sensors.add(sensor)
			}	
		}
		else{
			_board.boardType = board.boardType
			_board.name = board.name
			_board.internet = board.internet
			for (sensor : board.sensors){
				_sensors.add(sensor)
			}
		}
			
		
		for (sensor: makeSensors(_sensors)){
			_board.sensors.add(sensor)
		}
		
		
		return _board
	}
	
	
	static def EList<Sensor> makeSensors(EList<Sensor> sensors){
		var EList<Sensor> validSensors
		
		for(sensor:sensors){
			if(sensor instanceof BaseSensor){
				//Do nothing
			}
			else if(sensor instanceof OverrideSensor){
				sensor.sensorSettings = sensor.parent.sensorSettings
				sensor.sensorType = sensor.parent.sensorType
				validSensors.add(sensor)
			}
			else{
				validSensors.add(sensor)
			}
		}
		
		
		return validSensors
	}
}
