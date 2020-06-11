package dk.klevang.auxil

import dk.klevang.iotdsl.Board
import java.util.HashMap
import dk.klevang.iotdsl.Sensor
import org.eclipse.xtext.EcoreUtil2

class ExtensionHandler 
{
	def static prepareExtendedBoard(Board board)
	{
		// if some board has no internet config, but their parent has
		// then create internet for the child, by setting parent's net = child's net
		if (board.internet === null && board.extension.parent.internet !== null)
		{
			board.internet = EcoreUtil2.copy(board.extension.parent.internet)
		}
		
		
		// combine the sensors on the board and their parents board
		var sensorMap = new HashMap<String, Sensor>
		
		for (Sensor s : board.sensors)
		{
			sensorMap.put(s.name, s)
		}
		
		for (Sensor s : board.extension.parent.sensors)
		{
			sensorMap.putIfAbsent(s.name, s)
		}
		
		board.sensors.clear
		for (Sensor sensor : sensorMap.values.toList)
		{
			board.sensors.add(EcoreUtil2.copy(sensor))
		}
	}
	
	def static int getInheritanceDepth(Board board)
	{
		var depth = 0
		var current = board
		
		while (current.extension !== null)
		{
			depth += 1
			current = current.extension.parent
		}
		
		return depth
	}
	
}