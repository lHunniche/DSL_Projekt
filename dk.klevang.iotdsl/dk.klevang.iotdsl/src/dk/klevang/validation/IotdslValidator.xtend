/*
 * generated by Xtext 2.20.0
 */
package dk.klevang.validation

import org.eclipse.xtext.validation.Check
import dk.klevang.iotdsl.Condition
import dk.klevang.iotdsl.Board
import java.util.HashSet
import dk.klevang.iotdsl.Sensor
import java.util.HashMap

/** 
 * This class contains custom validation rules. 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class IotdslValidator extends AbstractIotdslValidator {
	
	@Check def void checkForCyclicInheritance(Board board)
	{
		var seen = new HashSet<Board>
		seen.add(board)
		
		checkParentForCyclicInheritance(board.extension.parent, seen)
	}
	
	def void checkParentForCyclicInheritance(Board parent, HashSet<Board> seen)
	{
		if (parent === null)
		{
			return
		}
		if (seen.contains(parent))
		{
			error("Cyclic inheritance not allowed.", parent.extension, null)
			return
		}
		seen.add(parent)
		checkParentForCyclicInheritance(parent.extension.parent, seen)
	}
	
	
	@Check def void checkForMissingOverrideSensor(Board board)
	{
		var seen = new HashMap<String, Sensor>
		for (Sensor sensor : board.sensors)
		{
			seen.put(sensor.name, sensor)
		}
		
		checkParentForMissingOverrideSensor(board, seen)
	}
	
	
	def void checkParentForMissingOverrideSensor(Board board, HashMap<String, Sensor> seen)
	{
		if (board.extension.parent !== null)
		{
			for (Sensor sensor : board.extension.parent.sensors)
			{
				var existing = seen.putIfAbsent(sensor.name, sensor)
				if (existing !== null)
				{
					if (!existing.override)
					{
						error("Duplicate sensor. If overriding from parent, use 'override' keyword", existing, null)
					}
					
				}
			}
			checkParentForMissingOverrideSensor(board.extension.parent, seen)
		}
	}
	
	@Check
	def void checkForMissingOverrideInternet(Board board)
	{
		if (board.internet === null || board.internet.override)
		{
			return
		}
		if (parentHasInternet(board)){
			error("Duplicate internet. If overriding from parent, use 'override' keyword", board.internet, null)
		}
	}
	
	def boolean parentHasInternet(Board board)
	{
		if (board.extension.parent === null)
		{
			return false
		}
		if (board.extension.parent.internet !== null)
		{
			return true
		}
		else
		{
			parentHasInternet(board.extension.parent)
		}
	}
}







