require 'net/http'
require 'cgi'
require 'csv'
require 'ConnectionSPARQL'


class OficinaController < ApplicationController


respond_to :html, :json, :js


	def index
		query="
			SELECT ?article ?year ?nameArticle
			FROM <http://gaci.edu.br>
			WHERE {
			    ?article a bibo:AcademicArticle .
			    ?article dcterms:issued ?year .
			    ?article dc:title ?nameArticle .
			    FILTER (!langMatches(lang(?nameArticle), \"en\")).
			}"
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
				line["article"] = row[0]
				line["year"] = row[1]
				str = row[2].encode("ASCII-8BIT").force_encoding("utf-8")
				line["nameArticle"] = str
				logger.info str
				triples.push(line)
			end

		end
		return triples
	end
end