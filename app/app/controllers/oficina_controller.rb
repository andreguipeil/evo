require 'net/http'
require 'cgi'
require 'csv'
require 'ConnectionSPARQL'
require 'rubygems'
require 'rubygems'
require 'active_support/all'
$KCODE = 'UTF8'



class OficinaController < ApplicationController


respond_to :html, :json, :js




	def index
		query="
			SELECT distinct ?refBy ?id ?nameArticle
			FROM <http://gaci.edu.br>
			WHERE{
			   ?article a bibo:AcademicArticle .
			   ?article dc:title ?nameArticle .
			   ?article dcterms:isReferencedBy ?refBy .
			   ?article vivo:relatedBy ?nodeAuthor.
			   ?article dcterms:issued ?year .
			   ?nodeAuthor vivo:relates ?nodeAuthor2.
			   ?nodeAuthor vivo:rank ?rank .
			   ?nodeAuthor2 rdfs:label ?name .
			   ?refBy dc:creator ?personCreator.
			   ?personCreator rdfs:label ?nome.
			   ?article bibo:presentedAt ?conference.
			   ?conference dc:title ?nameConference .
                           ?refBy bibo:identifier ?id.
                                  FILTER (!regex(str(?nodeAuthor2), concat(\"#author-\",str(?id))))
			} ORDER BY ?refBy"
		c=ConnectionSPARQL.new
		data = c.runQuery(query)

		#FILTER regex(lcase(str(?nameArticle)), \"peoplegrid\")
		#data = data.force_encoding("UTF-8")
		#logger.info data
		first, *rest = query.split(/FROM/)
		cont = first.scan("?").count
		triples = csvToArray2(data, cont)
 		@ret = Hash.new
 		#@ret["triples"] = @triples
 		#@ret["cont"] = cont
 		@ret["article"] = contArticle(triples)
		@ret["cont"] = 2
		respond_with(@ret)
	end
#######################################################
# Conta quantos artigos iguais existe no array
# --> Entrada: array of hashes
# --> Saida: object
#######################################################
	def contArticle (triples)
		article = Hash.new(0)
		triples.each do |row|
			article[row[2]] +=1
		end


		return article.sort_by {|article,cont| cont}.reverse
	end

#######################################################
# Transforma os dados vindos do vituoso do formato CSV para um Array com Hash
# --> Entrada: Array em CSV
# --> Saida: Array
#######################################################
	def csvToArray2 (data, contFields)
		i = 0;
		triples = Array.new
		cont = false
		data.each do |row|
			if cont == false
				row.pop
				cont = true
			else
				line = Hash.new
				while i < contFields do
   					line[i] = row[i].encode("ASCII-8BIT").force_encoding("utf-8").parameterize.to_s
   					i += 1
   				end
				triples.push(line)
				i = 0
			end
		end
	return triples
	end








end