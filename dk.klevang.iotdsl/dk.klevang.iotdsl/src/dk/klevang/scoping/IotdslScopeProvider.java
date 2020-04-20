/*
 * generated by Xtext 2.20.0
 */
package dk.klevang.scoping;

import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.scoping.IScope;
import org.eclipse.xtext.scoping.Scopes;

import dk.klevang.iotdsl.DotReference;
import dk.klevang.iotdsl.Sensor;
import dk.klevang.iotdsl.WebEndpoint;
import dk.klevang.iotdsl.Webserver;

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
public class IotdslScopeProvider extends AbstractIotdslScopeProvider {
	
	@Override
	public IScope getScope(EObject context, EReference reference) {
		System.out.println("Looking for reference on: " + context);
		System.out.println("This is a reference: " + reference);
		System.out.println("\n");
	    // We want to define the Scope for the Element's superElement cross-reference
	    if (context instanceof DotReference) {
	    	//System.out.println("Web: " + ((DotReference) context).getWeb());
	    	//System.out.println("Endpoint: " + ((DotReference) context).getEndpoint());
	        // Collect a list of candidates by going through the model
	        // EcoreUtil2 provides useful functionality to do that
	        // For example searching for all elements within the root Object's tree
	        EObject rootElement = EcoreUtil2.getRootContainer(context);
	        List<WebEndpoint> candidates = EcoreUtil2.getAllContentsOfType(rootElement, WebEndpoint.class);
	        // Create IEObjectDescriptions and puts them into an IScope instance
	        return Scopes.scopeFor(candidates);
	    }
	    else if (context instanceof WebEndpoint) {
	    	
	    }
	    return super.getScope(context, reference);
	}

}
