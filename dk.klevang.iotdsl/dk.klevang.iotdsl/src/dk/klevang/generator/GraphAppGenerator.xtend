package dk.klevang.generator

import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import dk.klevang.iotdsl.GraphApp
import dk.klevang.iotdsl.Graph
import java.util.HashSet
import java.util.List
import dk.klevang.iotdsl.Sensor
import org.eclipse.emf.common.util.EList
import dk.klevang.iotdsl.Line

class GraphAppGenerator extends AbstractGenerator{
	
	override doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		resource.allContents.filter(GraphApp).forEach[generateGraphApp(fsa,resource.allContents.filter(Sensor).toList)]
	}
	
	def generateGraphApp(GraphApp app, IFileSystemAccess2 fsa, List<Sensor> sensors) {
		fsa.generateFile("index.html", app.generateHtml)
		fsa.generateFile("index.js", app.generateJS(sensors))
		fsa.generateFile("index.css", app.generateCSS)
	}
	
	
	def CharSequence generateHtml(GraphApp app) {
		
		var sensors = new HashSet<String>
		var graphs = app.graphs;
		
		for(Graph graph : graphs) {
			sensors.add(graph.graphType.sensor.name)
		}
		'''
		<!DOCTYPE html>
		<html>
		
		<head>
		    <title>Graphs For IoT</title>
		    <link rel="stylesheet" type="text/css" href="index.css">
		    <!DOCTYPE html>
		    <link href="https://fonts.googleapis.com/css2?family=Roboto&display=swap" rel="stylesheet">
		    <meta charset="utf-8">
		    <!-- Load d3.js -->
		    <script src="https://d3js.org/d3.v4.js"></script>
		    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
		</head>
		
		<body>
			
			«FOR sensorName : sensors»
			<div class="chart-group">
				«FOR graph: app.graphs»	
					«IF graph.graphType.sensor.name == sensorName»
					<div class="chart" id="«graph.graphType.sensor.name»-«graph.graphType.type»-graph"></div>
					«ENDIF»
				«ENDFOR»
			</div>
			«ENDFOR»
		</body>
		<script src="index.js"></script>
		
		</html>
		
		'''
	}
	
	
	def CharSequence generateJS(GraphApp app, List<Sensor> sensors) {
		
		var typeSet = new HashSet<String>
		var graphs = app.graphs;
		
		for(Graph graph : graphs) {
			typeSet.add(graph.graphType.type)
		}
		
		'''
		document.addEventListener('DOMContentLoaded', function () {
		
		    /*
		    Pie charts is created with code and inspiration from https://www.d3-graph-gallery.com/graph/pie_annotation.html
		    Line charts is created with code and inspiration from https://www.d3-graph-gallery.com/graph/line_basic.html
		
		    */
		
		    let chartWidth = 900
		    let chartHeight= 400
		    let maxElements = 200


		«FOR type : typeSet»
			«IF type == "pie"»
			«generatePieInitFunction»
			«generateDataGroupFunction»
			«generateValueToObjFunction»
			«generateZeroFilterFunction»
			«ENDIF»
		«ENDFOR»
		«FOR graph : graphs»
			«IF graph.graphType.type == 'line'»
				«FOR sensor : sensors»
				«IF graph.graphType.sensor.name == sensor.name»
					«generateLineGraph(graph,sensor.getSensorType.name, sensor.getEndpoints.get(0).getDot.getEndpoint.name)»
				«ENDIF»
				«ENDFOR»
			«ENDIF»
		«ENDFOR»
		
		
		
		«generateInit(graphs)»
		init()
		
		}, false);
		
		
		'''
	}
	
	def CharSequence generateInit(EList<Graph> graphs) {
		
	
		
		'''
		let init = () => {
			«FOR graph : graphs»
				«IF graph.graphType.type == "line"»
				init«graph.graphType
				.sensor
				.sensorType
				.name
				.substring(0, 1)
				.toUpperCase() 
				+ graph
				.graphType
				.sensor
				.sensorType
				.name
				.substring(1)»LineChart()
				«ENDIF»
			«IF graph.graphType.type == "pie"»
	initPieChart("«graph.graphType.sensor.endpoints.get(0).getDot.getEndpoint.name».csv",
				«IF graph.graphType.sensor.sensorType.name == "temp"»
							[10,20,30,40,50],
							{"<10": 0,
							            "10-20": 0,
							            "20-30": 0,
							            "30-40": 0,
							            "50<": 0
							            },
							
							«ELSEIF graph.graphType.sensor.sensorType.name == "light"»
			[10,100,300,400,600],
			{ "<10":0,
			"10-100":0,
			"100-300": 0,
			"300-400": 0,
			"600<":0
			},
			«ENDIF»
			"«graph.graphType.sensor.name»-pie-graph",
			«IF graph.graphType.color == "colorfull"»
			d3.schemeCategory10
			«ELSEIF graph.graphType.color == "blue"»
			d3.schemeCategory20c
			«ENDIF»
			);
			«ENDIF»
						
			«ENDFOR»
			
			
		}
		'''
	}
	
	
	def CharSequence generateLineGraph(Graph graph, String sensorType, String endpoint) {
		
		var graphType = graph.graphType
		if(graphType instanceof Line) {
		var lineGraph = graphType as Line
		'''
		let init«sensorType.substring(0, 1).toUpperCase() + sensorType.substring(1)»LineChart = () => {
		        var margin = { top: 10, right: 30, bottom: 30, left: 60 },
		        width = chartWidth - margin.left - margin.right,
		        height = chartHeight - margin.top - margin.bottom;
		
		    // append the svg object to the body of the page
		    var svg = d3.select("#«lineGraph.sensor.name»-«lineGraph.type»-graph")
		        .append("svg")
		        .attr("width", width + margin.left + margin.right)
		        .attr("height", height + margin.top + margin.bottom)
		        .append("g")
		        .attr("transform",
		            "translate(" + margin.left + "," + margin.top + ")");
		
		    //Read the data
		    d3.csv("«endpoint».csv",
		
		        // When reading the csv, I must format variables:
		        
		        function (d) {
		            return {«sensorType»: d.«sensorType»,date: d3.timeParse("%Y-%m-%d %H:%M:%S")(d.date) }
		        },
		
		        // Now I can use this dataset:
		        function (data) {
		            if(data.length > maxElements) {
		                data = data.slice(Math.max(data.length - maxElements, 0))
		            }
		            console.log(data.length)
		            // Add X axis --> it is a date format
		            var x = d3.scaleTime()
		                .domain(d3.extent(data, function (d) { return d.date; }))
		                .range([0, width]);
		            svg.append("g")
		                .attr("transform", "translate(0," + height + ")")
		                .call(d3.axisBottom(x));
		
		            // Add Y axis
		            var y = d3.scaleLinear()
		                .domain([10, d3.max(data, function (d) { return +d.«sensorType»; }) + 5])
		                .range([height, 0]);
		            svg.append("g")
		                .call(d3.axisLeft(y));
		
		
		            svg.append("text")             
		            .attr("transform",
		                "translate(" + (width/2) + " ," + 
		                                (height + margin.top + 20) + ")")
		            .style("text-anchor", "middle")
		            .text("Date");
		
		            svg.append("text")
		            .attr("transform", "rotate(-90)")
		            .attr("y", 0 - margin.left)
		            .attr("x",0 - (height / 2))
		            .attr("dy", "1em")
		            .style("text-anchor", "middle")
		            .text("«sensorType.substring(0, 1).toUpperCase() + sensorType.substring(1)»");  
		
		          
		            svg.append("path")
		                .datum(data)
		                .attr("fill", "none")
		                «IF lineGraph.color !== null && lineGraph.color !== ""»
		                .attr("stroke", "«lineGraph.color»")
		                «ELSE»
		                .attr("stroke", "blue")
		                «ENDIF»
		                «IF  lineGraph.stroke != 0»
		                 .attr("stroke-width", «lineGraph.stroke»)
		                 «ELSE»
		                 .attr("stroke-width", 2)
		                «ENDIF»
		                .attr("d", d3.line()
		                    .x(function (d) { return x(d.date) })
		                    .y(function (d) { return y(d.«sensorType») })
		                )
		
		
		        })
		    }
		'''
		}
		else {
			'''
			'''
		}
	}
	
	def CharSequence generateDataGroupFunction() {
		'''
		let generateDataGroups = (lines, groups, groupObj) => {
		        let groupValues = [0, 0, 0, 0, 0]
		       
		               for (let i = 0; i < lines.length; i++) {
		                   for (let j = 0; j < groups.length; j++) {
		                       if (lines[i] > groups[groups.length - 1]) {
		                           groupValues[groupValues.length - 1]++
		                           break;
		                       }
		                       else if (lines[i] < groups[j]) {
		                           groupValues[j]++
		                           break;
		                       }
		                   }
		               }
		    
		'''
	}
	
	def CharSequence generateValueToObjFunction() {
		'''
		let appendValuesToDictObj = (groupObj, groupValues) => {
			groupObj[Object.keys(groupObj)[0]] = groupValues[0]
			groupObj[Object.keys(groupObj)[1]] = groupValues[1]
			groupObj[Object.keys(groupObj)[2]] = groupValues[2]
			groupObj[Object.keys(groupObj)[3]] = groupValues[3]
			groupObj[Object.keys(groupObj)[4]] = groupValues[4]
			return groupObj
			}
			
			
		'''
	}
	
	def CharSequence generateZeroFilterFunction() {
		'''
		let filterValuesOfZero = (groupObj) => {
			for(attr in groupObj) {
				if(groupObj[attr] == 0) {
					delete groupObj[attr]
					}
				}
		return groupObj
}
		'''
	}
	
	def CharSequence generatePieInitFunction(){
		'''
		 let initPieChart = (filename, groups, groupObj, chartId,scheme) => {
		        $.ajax({
		            type: "GET",
		            url: filename,
		            dataType: "text",
		            success: function(data) {initPie(data);}
		        });
		
		        
		        function initPie(data) {
		            var allTextLines = data.split(/\r\n|\n/);
		            var headers = allTextLines[0].split(',');
		            var lines = [];
		            for (var i=1; i<allTextLines.length; i++) {
		                var data = allTextLines[i].split(',');
		                if (data.length == headers.length) {
		        
		                    for (var j=0; j<headers.length; j++) {
		                        if(j%2 == 0)
		                        lines.push(data[j]);
		                    }
		                }
		            }
		        
		            renderPieChart(lines, groups, chartId, groupObj,scheme)
		            
		            
		        }
		    }
		    «generatePieRenderFunction»
		  '''
	}
	
	def CharSequence generatePieRenderFunction() {
		'''
		let renderPieChart = (lines, groups, chartId, groupObj,scheme) => {
				
				        var width = 450
				        height = 450
				        margin = 40
				
				        var radius = Math.min(width, height) / 2 - margin
				
				
				        var svg = d3.select("#"+chartId)
				        .append("svg")
				            .attr("width", width)
				            .attr("height", height)
				        .append("g")
				            .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");
				
				        let data = generateDataGroups(lines,groups, groupObj)
				    
				
				        var color = d3.scaleOrdinal()
				            .domain(data)
				            .range(scheme);
				
				        var pie = d3.pie()
				            .value(function(d) {return d.value; })
				        var data_ready = pie(d3.entries(data))
				
				        var arcGenerator = d3.arc()
				            .innerRadius(0)
				            .outerRadius(radius)
				        
				        svg
				            .selectAll('mySlices')
				            .data(data_ready)
				            .enter()
				            .append('path')
				                .attr('d', arcGenerator)
				                .attr('fill', function(d){ return(color(d.data.key)) })
				                .attr("stroke", "black")
				                .style("stroke-width", "2px")
				                .style("opacity", 0.7)
				
				        svg
				            .selectAll('mySlices')
				            .data(data_ready)
				            .enter()
				            .append('text')
				            .text(function(d){ return d.data.key})
				            .attr("transform", function(d) { return "translate(" + arcGenerator.centroid(d) + ")";  })
				            .style("text-anchor", "middle")
				            .style("font-size", 17)
				
				
				    }
		'''
	}
	
	def getUniqueSensor(Graph graph) {
		return graph
	}
	
	
	def CharSequence generateCSS(GraphApp app) {
		'''
		
		* {
		    font-family: 'Roboto', sans-serif;
		}
		p{
		    font-size: 20px;
		}
		
		.chart{
		    display:inline-block;
		}
		.chart-group {
		    margin-bottom: 5%;
		}
		
		
		'''
	}
	
	
	
	
}