require 'net/http'
require 'cgi'
require 'csv'
require 'ConnectionSPARQL'

class OficinaController < ApplicationController

respond_to :html, :json, :js

	def index
		query="
			SELECT Distinct ?nameArticle ?year ?nodeAuthor ?nodeAuthor2 ?name
			FROM <http://laburb.com>
			WHERE {
			    ?article a bibo:AcademicArticle .
			    ?article dcterms:issued ?year .
			    ?article dc:title ?nameArticle .
			    ?article vivo:relatedBy ?nodeAuthor.
			    ?nodeAuthor vivo:relates ?nodeAuthor2.
			    ?nodeAuthor2 rdfs:label ?name.
			    FILTER (!langMatches(lang(?nameArticle), \"en\")).
			    FILTER regex(str(?name), \"Andr\")

			} order by ?year"
		c=ConnectionSPARQL.new
		data = c.runQuery(query)


		#data = data.force_encoding("UTF-8")
		#logger.info data

		@triples = csvToArray(data)
		#logger.info @triples
		respond_with(@triples)
	end

#######################################################
# Transforma os dados vindos do vituoso do formato CSV para um Array com Hash
# --> Entrada: Array em CSV
# --> Saida: Array
#######################################################
	def csvToArray (data)

		triples = Array.new
		cont = false
		data.each do |row|
			if cont == false
				row.pop
				cont = true
			else
				line = Hash.new
				line["nameArticle"] = row[0]
				line["year"] = row[1]
				line["nodeAuthor"] = row[2]
				line["nodeAuthor2"] = row[3]
				line["name"] = row[4]
				triples.push(line)
			end
		end
		return triples
	end
end