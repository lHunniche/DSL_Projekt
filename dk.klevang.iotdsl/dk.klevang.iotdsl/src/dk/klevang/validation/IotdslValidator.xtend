/*
 * generated by Xtext 2.20.0
 */
package dk.klevang.validation

import org.eclipse.xtext.validation.Check
import dk.klevang.iotdsl.Board
import java.util.HashSet
import dk.klevang.iotdsl.Sensor
import java.util.HashMap
import dk.klevang.iotdsl.WebServer
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.emf.ecore.EObject
import java.util.List
import dk.klevang.iotdsl.DotReference
import dk.klevang.iotdsl.WebEndpoint
import dk.klevang.iotdsl.Ref

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
						return
					}
					
				}
			}
			checkParentForMissingOverrideSensor(board.extension.parent, seen)
		}
	}
	
	@Check
	def void checkForMissingOverrideInternet(Board board)
	{
		var seen = new HashSet<Board>
		if (board.internet === null || board.internet.override)
		{
			return
		}
		seen.add(board)
		if (parentHasInternet(board, seen)){
			error("Duplicate internet. If overriding from parent, use 'override' keyword", board.internet, null)
		}
	}
	
	def boolean parentHasInternet(Board board, HashSet<Board> seen)
	{
		if (board.extension.parent === null)
		{
			return false
		}
		if (seen.contains(board.extension.parent))
		{
			return false
		}
		if (board.extension.parent.internet !== null)
		{
			return true
		}
		else
		{
			seen.add(board.extension.parent)
			parentHasInternet(board.extension.parent, seen)
		}
	}
	
	
	@Check
	def void checkForDuplicateWebServerName(WebServer server)
	{
		var EObject rootElement = EcoreUtil2.getRootContainer(server, true)
		var List<WebServer> servers = EcoreUtil2.getAllContentsOfType(rootElement, WebServer)
		
		for (WebServer _server : servers)
		if (_server.name.name == server.name.name && _server !== server)
		{
			error("Duplicate server names", server.name, null)
		}
	}
	
	
	@Check
	def void checkForCorrectDotReference(DotReference dot)
	{
		var dotServer = dot.web.name
		var dotEndpoint = dot.endpoint.name
		
		var EObject rootElement = EcoreUtil2.getRootContainer(dot, true)
		var List<WebServer> servers = EcoreUtil2.getAllContentsOfType(rootElement, WebServer)
		
		for (WebServer server : servers)
		{
			if (server.name.name == dotServer)
			{
				var endpointExists = false
				for(Ref ref : server.webEndpoints)
				{
					var endpoint = ref as WebEndpoint
					if (endpoint.name == dotEndpoint)
					{
						endpointExists = true
					}
				}
				if (!endpointExists)
				{
					error("Invalid server/endpoint combination", dot, null)
				}
			}
		}
	}
}






