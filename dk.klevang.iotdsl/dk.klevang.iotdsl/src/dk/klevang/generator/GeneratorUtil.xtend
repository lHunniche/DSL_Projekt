package dk.klevang.generator

import dk.klevang.iotdsl.AbstractSensor
import dk.klevang.iotdsl.Board
import dk.klevang.iotdsl.Sensor
import java.util.HashMap
import org.eclipse.xtext.EcoreUtil2

class GeneratorUtil {
	static def Board collectInfo(Board board){
		var sensorMap = new HashMap<String, Sensor>
		for (sensor : board.sensors){
			sensorMap.put(sensor.name, sensor)
		}
		
		if(board.parent !== null){
			board.boardType = board.parent.boardType
			board.internet = EcoreUtil2.copy(board.parent.internet)
			
			for (sensor : board.parent.sensors){
				sensorMap.putIfAbsent(sensor.name, sensor)
			}	
		}
		
		board.sensors.clear

			for (sensor: sensorMap.values.toList){
				if(!(sensor instanceof AbstractSensor)){
					board.sensors.add(EcoreUtil2.copy(makeSensor(sensor)))
				}
				
			}
		
		
		
		
		return board
	}
	
	
	static def Sensor makeSensor(Sensor sensor){
		
				if(sensor.parent !== null){
					if(sensor.parent.sensorSettings !== null){
						sensor.sensorSettings = EcoreUtil2.copy(sensor.parent.sensorSettings)
					}
					if(sensor.parent.sensorType !== null){
						sensor.sensorType = sensor.parent.sensorType
					}
				}

		
		
		return sensor
	}
}
	