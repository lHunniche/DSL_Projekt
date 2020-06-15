/*
 * generated by Xtext 2.20.0
 */
package dk.klevang.scoping;

import java.util.ArrayList;
import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.scoping.IScope;
import org.eclipse.xtext.scoping.Scopes;

import dk.klevang.iotdsl.BaseSensor;
import dk.klevang.iotdsl.Board;
import dk.klevang.iotdsl.IotdslPackage.Literals;
import dk.klevang.iotdsl.Program;
import dk.klevang.iotdsl.ProgramElement;
import dk.klevang.iotdsl.DotReference;
import dk.klevang.iotdsl.Ref;
import dk.klevang.iotdsl.Sensor;

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
public class IotdslScopeProvider extends AbstractIotdslScopeProvider {
	
	@Override
	public IScope getScope(EObject context, EReference reference) {
	    // We want to define the Scope for the Element's superElement cross-reference
	    if (context instanceof DotReference) {
	    	
	    	
	    	//System.out.println("Web: " + ((DotReference) context).getWeb());
	    	//System.out.println("Endpoint: " + ((DotReference) context).getEndpoint());
	        // Collect a list of candidates by going through the model
	        // EcoreUtil2 provides useful functionality to do that
	        // For example searching for all elements within the root Object's tree
	    	
	    	
	        EObject rootElement = EcoreUtil2.getRootContainer(context);
	        List<Ref> candidates = EcoreUtil2.getAllContentsOfType(rootElement, Ref.class);
	        // Create IEObjectDescriptions and puts them into an IScope instanceWebEndpoint.cl
	        return Scopes.scopeFor(candidates);
	    }
	    else if (context instanceof Board && reference == Literals.OVERRIDE_BOARD__PARENT){
	    	Program program = (Program) EcoreUtil2.getRootContainer(context.eContainer());
	    	ArrayList<Board> candidates = new ArrayList<Board>();

            for (ProgramElement element : program.getProgramElements()) {
                if (element instanceof Board) {
                    candidates.add(((Board) element));
                }
            }
            return Scopes.scopeFor(candidates);

	    }
	    else if(context instanceof Sensor && reference == Literals.OVERRIDE_SENSOR__PARENT){
	    	Program program = (Program) EcoreUtil2.getRootContainer(context.eContainer());
	    	ArrayList<Sensor> candidates = new ArrayList<Sensor>();

	    	for (ProgramElement element : program.getProgramElements()) {
	    		if (element instanceof BaseSensor) {
	    			candidates.add(((Sensor) element));
	    		}
	    	}
	    	return Scopes.scopeFor(candidates);
	    }
	    return super.getScope(context, reference);
	}

}
