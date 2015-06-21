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
 		@ret["article"] = triples
		@ret["cont"] = cont
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
   				line[5] = retireConectives(line[5])
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
	def retireConectives (article)
			article = article.gsub('-a-', '-')
			article = article.gsub('-as-', '-')
			article = article.gsub('-aos-', '-')
			article = article.gsub('-com-', '-')
			article = article.gsub('-como-', '-')
			article = article.gsub('-cada-', '-')
			article = article.gsub('-da-', '-')
			article = article.gsub('-de-', '-')
			article = article.gsub('-do-', '-')
			article = article.gsub('-das-', '-')
			article = article.gsub('-dos-', '-')
			article = article.gsub('-e-', '-')
			article = article.gsub('-este-', '-')
			article = article.gsub('-esta-', '-')
			article = article.gsub('-em-', '-')
			article = article.gsub('-faz-', '-')
			article = article.gsub('-fez-', '-')
			article = article.gsub('-foi-', '-')
			article = article.gsub('-fui-', '-')
			article = article.gsub('-isto-', '-')
			article = article.gsub('-isso-', '-')
			article = article.gsub('-mesmo-', '-')
			article = article.gsub('-nao-', '-')
			article = article.gsub('-no-', '-')
			article = article.gsub('-nos-', '-')
			article = article.gsub('-na-', '-')
			article = article.gsub('-nas-', '-')
			article = article.gsub('-nem-', '-')
			article = article.gsub('-ha-', '-')
			article = article.gsub('-ja-', '-')
			article = article.gsub('-mas-', '-')
			article = article.gsub('-muito-', '-')
			article = article.gsub('-muitos-', '-')
			article = article.gsub('-mais-', '-')
			article = article.gsub('-ou-', '-')
			article = article.gsub('-uma-', '-')
			article = article.gsub('-um-', '-')
			article = article.gsub('-uns-', '-')
			article = article.gsub('-sao-', '-')
			article = article.gsub('-os-', '-')
			article = article.gsub('-o-', '-')
			article = article.gsub('-se-', '-')
			article = article.gsub('-so-', '-')
			article = article.gsub('-sua-', '-')
			article = article.gsub('-seus-', '-')
			article = article.gsub('-seu-', '-')

			if  article[0].chr == 'a' and article[1].chr == '-'
				article = article.gsub("a-", '')
			end
			if article[0].chr == 'o' and article[1].chr == '-'
				article = article.gsub("o-", '')
			end

			if article[0].chr == 'o' and article[1].chr == 's' and article[2].chr == '-'
				article = article.gsub("os-", '')
			end
			if article[0].chr == 'a' and article[1].chr == 's' and article[2].chr == '-'
				article = article.gsub("as-", '')
			end
		return article
	end

end