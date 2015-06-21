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
			SELECT DISTINCT  ?refBy ?nameReal ?nameRight (xsd:integer(?rank)) as ?rank ?article ?nameArticle ?nameConference
				FROM <http://laburb.com>
				WHERE{
				 ?article a bibo:AcademicArticle .
				 ?article dc:title ?nameArticle .
				 ?article dcterms:isReferencedBy ?refBy .
				 ?article vivo:relatedBy ?nodeAuthor .
				 ?article dcterms:issued ?year .
				 ?article bibo:presentedAt ?conference .
				 ?conference dc:title ?nameConference .

				 ?nodeAuthor vivo:relates ?nodeAuthor2 .
				 ?nodeAuthor vivo:rank ?rank .
				 ?nodeAuthor2 rdfs:label ?nameRight .

				 ?refBy bibo:identifier ?id .
				 ?refBy dc:creator ?personCreator .
				 ?personCreator rdfs:label ?nameWrong .
				 ?personCreator obo:ARG_2000028 ?nodeName .
				 ?nodeName vcard:hasName ?nameName .
				 ?nameName vcard:fn ?nameReal .
				 FILTER (!regex(str(?nodeAuthor2), concat(\"#author-\",str(?id)))).
				 FILTER (str(?nameReal) = str(?nameWrong))
			} ORDER BY ?refBy ?nameArticle ?rank"
		c=ConnectionSPARQL.new
		data = c.runQuery(query)

		#FILTER regex(lcase(str(?nameArticle)), \"peoplegrid\")
		#data = data.force_encoding("UTF-8")
		#logger.info data
		first, *rest = query.split(/FROM/)
		cont = first.scan("?").count-1
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

#######################################################
# retira todos os conectivos(stopwords) do título do artigo
# --> Entrada: string
# --> Saida: string
#######################################################
	def retireConetives (article)
		article.sub('a', '')
		article.sub('as', '')
		article.sub('às', '')
		article.sub('ás', '')
		article.sub('aos', '')
		article.sub('com', '')
		article.sub('como', '')
		article.sub('cada', '')
		article.sub('da', '')
		article.sub('de', '')
		article.sub('do', '')
		article.sub('das', '')
		article.sub('dos', '')
		article.sub('e', '')
		article.sub('é', '')
		article.sub('este', '')
		article.sub('esta', '')
		article.sub('em', '')
		article.sub('faz', '')
		article.sub('fez', '')
		article.sub('foi', '')
		article.sub('fui', '')
		article.sub('isto', '')
		article.sub('mesmo', '')
		article.sub('nós', '')
		article.sub('não', '')

		article.sub('há', '')
		article.sub('já', '')
		article.sub('ja', '')

		article.sub('mas', '')
		article.sub('muito', '')
		article.sub('muitos', '')
		article.sub('mais', '')

		article.sub('ou', '')
		article.sub('uma', '')
		article.sub('um', '')
		article.sub('sao', '')

		article.sub('os', '')
		article.sub('se', '')
		article.sub('so', '')
		article.sub('sua', '')

	end

end