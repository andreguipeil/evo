require 'net/http'
require 'cgi'
require 'csv'

class ConnectionSPARQL

	def runQuery(query, format="text/csv")

		baseURL="http://localhost:8890/sparql/"
		prefix01="PREFIX foaf: 		<http://xmlns.com/foaf/0.1/>"
		prefix02="PREFIX rdf: 		<http://www.w3.org/1999/02/22-rdf-syntax-ns#>"
		prefix03="PREFIX bio:  		<http://purl.org/vocab/bio/0.1/>"
		prefix04="PREFIX rdfs: 		<http://www.w3.org/2000/01/rdf-schema#>"
		prefix05="PREFIX xsd:  	<http://www.w3.org/2001/XMLSchema#>"
		prefix06="PREFIX dc:       	<http://purl.org/dc/elements/1.1/> "
		prefix07="PREFIX doac:     	<http://ramonantonio.net/doac/0.1/>"
		prefix08="PREFIX dcterms:  	<http://purl.org/dc/terms/>"
		prefix09="PREFIX skos:     	<http://www.w3.org/2004/02/skos/core#>"
		prefix10="PREFIX ufpelterms: 	<http://ufpel.edu.br/terms/>"
		prefix11="PREFIX event: 	<http://purl.org/NET/c4dm/event.owl#>"
		prefix12="PREFIX gn: 		<http://www.geonames.org/ontology#>"
		prefix13="PREFIX geo: 		<http://www.w3.org/2003/01/geo/wgs84_pos#>"
		prefix14="PREFIX bibo: 	<http://purl.org/ontology/bibo/>"
		prefix15="PREFIX vcard:	<http://www.w3.org/2006/vcard/ns#>"
		prefix16="PREFIX obo: 		<http://purl.obolibrary.org/obo/> "
		prefix17="PREFIX vivo: 	<http://vivoweb.org/ontology/core#>"
		prefix18="PREFIX lattes: 	<http://www.cnpq.br/2001/XSL/Lattes>"
		prefix19="PREFIX pair: 		<http://vivoext.org/pair#>"
		prefixes="#{prefix01}
		                 #{prefix02}
			    #{prefix03}
			    #{prefix04}
			    #{prefix05}
			    #{prefix06}
			    #{prefix07}
			    #{prefix08}
			    #{prefix09}
			    #{prefix10}
			    #{prefix11}
			    #{prefix12}
			    #{prefix13}
			    #{prefix14}
			    #{prefix15}
			    #{prefix16}
			    #{prefix17}
			    #{prefix18}
			    #{prefix19}"

		sparql=prefixes+query
		params={
			"default-graph" => "",
			"should-sponge" => "soft",
			"query" => sparql,
			"debug" => "on",
			"timeout" => "",
			"format" => format,
			"save" => "display",
			"fname" => ""
		}
		querypart=""
		params.each { |k,v|
			querypart+="#{k}=#{CGI.escape(v)}&"
		}
		sparqlURL=baseURL+"?#{querypart}"

		response = Net::HTTP.get_response(URI.parse(sparqlURL))


		data = CSV::parse(response.body)
		return data
	end

	def runInsert(query, format="text/csv")

		baseURL="http://localhost:8890/sparql/"
		prefix01="PREFIX foaf: 		<http://xmlns.com/foaf/0.1/>"
		prefix02="PREFIX rdf: 		<http://www.w3.org/1999/02/22-rdf-syntax-ns#>"
		prefix03="PREFIX bio:  		<http://purl.org/vocab/bio/0.1/>"
		prefix04="PREFIX rdfs: 		<http://www.w3.org/2000/01/rdf-schema#>"
		prefix05="PREFIX xsd:  	<http://www.w3.org/2001/XMLSchema#>"
		prefix06="PREFIX dc:       	<http://purl.org/dc/elements/1.1/> "
		prefix07="PREFIX doac:     	<http://ramonantonio.net/doac/0.1/>"
		prefix08="PREFIX dcterms:  	<http://purl.org/dc/terms/>"
		prefix09="PREFIX skos:     	<http://www.w3.org/2004/02/skos/core#>"
		prefix10="PREFIX ufpelterms: 	<http://ufpel.edu.br/terms/>"
		prefix11="PREFIX event: 	<http://purl.org/NET/c4dm/event.owl#>"
		prefix12="PREFIX gn: 		<http://www.geonames.org/ontology#>"
		prefix13="PREFIX geo: 		<http://www.w3.org/2003/01/geo/wgs84_pos#>"
		prefix14="PREFIX bibo: 	<http://purl.org/ontology/bibo/>"
		prefix15="PREFIX vcard:	<http://www.w3.org/2006/vcard/ns#>"
		prefix16="PREFIX obo: 		<http://purl.obolibrary.org/obo/> "
		prefix17="PREFIX vivo: 	<http://vivoweb.org/ontology/core#>"
		prefix18="PREFIX lattes: 	<http://www.cnpq.br/2001/XSL/Lattes>"
		prefix19="PREFIX pair: 		<http://vivoext.org/pair#>"
		prefixes="#{prefix01}
		                 #{prefix02}
			    #{prefix03}
			    #{prefix04}
			    #{prefix05}
			    #{prefix06}
			    #{prefix07}
			    #{prefix08}
			    #{prefix09}
			    #{prefix10}
			    #{prefix11}
			    #{prefix12}
			    #{prefix13}
			    #{prefix14}
			    #{prefix15}
			    #{prefix16}
			    #{prefix17}
			    #{prefix18}
			    #{prefix19}"

		sparql=prefixes+query

		params={
			"default-graph" => "",
			"should-sponge" => "",
			"query" => sparql,
			"debug" => "on",
			"timeout" => "",
			"format" => format,
			"save" => "display",
			"fname" => ""
		}
		querypart=""
		params.each { |k,v|
			querypart+="#{k}=#{CGI.escape(v)}&"
		}
		sparqlURL=baseURL+"?#{querypart}"

		response = Net::HTTP.get_response(URI.parse(sparqlURL))


		data = CSV::parse(response.body)
		return data
	end

end
