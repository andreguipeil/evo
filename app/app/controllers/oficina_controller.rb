require 'net/http'
require 'cgi'
require 'csv'
require 'ConnectionSPARQL'

class OficinaController < ApplicationController

	def index
		dsn="http://laburb.com"
		prefix1="PREFIX dc: <http://purl.org/dc/elements/1.1/>"
		prefix2="PREFIX bibo: <http://purl.org/ontology/bibo/>"
		query="
			SELECT DISTINCT ?name ?person ?id
			FROM <#{dsn}>
			WHERE {
				?person bibo:identifier ?id .
				?person dc:title ?name
			}"
		c=ConnectionSPARQL.new
		@data1= c.runQuery(query)
		#@data1 = c.teste
	end

	def sparqlQuery(query, baseURL, format="text/csv")
		params={
			"default-graph" => "",
			"should-sponge" => "soft",
			"query" => query,
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
		return CSV::parse(response.body)
	end
end
