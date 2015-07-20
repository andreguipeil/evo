require 'net/http'
require 'cgi'
require 'csv'
require 'ConnectionSPARQL'
require 'rubygems'
require 'rubygems'
require 'active_support/all'
require "thread"
require "json"
$KCODE = 'UTF8'



class OficinaController < ApplicationController

respond_to :html, :json, :js


	def index
		query="
			SELECT DISTINCT  ?refBy ?article (xsd:integer(?rank)) as ?rank ?nameReal ?nameRight ?nameArticle ?nameConference ?year
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

		#FILTER regex(lcase(str(?nameArticle)), \"peoplegrid\") .
		c=ConnectionSPARQL.new
		data = c.runQuery(query)

		#FILTER regex(lcase(str(?nameArticle)), \"peoplegrid\")
		#data = data.force_encoding("UTF-8")
		#logger.info data


		first, *rest = query.split(/FROM/) 		# pega os campos dinamicamente
		cont = first.scan("?").count-1 			# faz a contagem do campos
		@triples = csvToArray(data, cont)		# transforma de csv para array para facilitar a manipulacao


		createArq(createEntities(@triples))
		#createCSVFile(createEntities(@triples))
		#readArq
		readArqJSON
		#coAuthors = organizeCoAuthors(triples)		#

	 	#distance = distanceEdition(coAuthors)


 		@ret = Hash.new
 		@ret["triples"] = @triples
 		@ret["cont"] = cont
 		@ret["article"] = @triples
		#@ret["cont"] = 5

		#logger.info @ret
		respond_with(@ret)
	end



	def createArq (entities)
		File.open('laburb3.txt', 'w') do |f2|
 			entities.each do | ent |
 				ent.each do | t |
 					f2.puts t
 				end
 				f2.puts "\n"
 			end
 		end
	end

	def readArq
		entities = Array.new
		entity =  Array.new
		IO.readlines('laburb2.txt').each do | line |
			if (line != "\n")
				if(line != ";")
					logger.info line
					hash = Hash.new
					hash = line
					entity.push(hash)
				end
				logger.info entity
			else
				entities.push(entity)
				entity.clear
			end
		end
		logger.info entities
	end

	def readArqJSON
		entities = Array.new
		entity =  Array.new
		IO.readlines('laburb2.txt').each do | line |
			if (line != "\n")
				if(line != ";")
		#			logger.info line
					hash = eval(line)
					entity.push(hash)
				end
		#		logger.info entity
			else
				e = entity.dup
				entities.push(e)
				entity.clear
			end
		end
		#logger.info entities

	a = entities[0][0]
	logger.info a[5]

	end

	def createEntities (triples)

		sideA 	= triples.dup
		sideB 	= triples.dup
		entities = Array.new
		temp 	= Array.new

		sideA.each do |a|
			logger.info sideB.size
			if(sideB.size > 0) then
				entity 	  = Array.new
				newSide = Array.new

					sideB.each do |b|
						distance = Levenshtein.normalized_distance(a[5],b[5])
						if distance <= 0.2 || distance == 0.0 then
							arr = b
							entity.push(arr)
						else
							newSide.push(b)
						end
					end

				entities.push(entity)
				sideB = newSide
			end
		end
		return entities

	end



#######################################################
# Conta quantos artigos iguais existe no array
# --> Entrada: array of hashes
# --> Saida: object
#######################################################
	def contArticle (triples)
		article = Hash.new(0)
		triples.each do |row|
			article[row[5]] +=1
		end
		return article.sort_by {|article,cont| cont}.reverse
	end


#######################################################
#Distancia de Edicao
# --> Entrada: array of hashes
# --> Saida: object
#######################################################

	def distanceEdition (coAuthors)
		distanceEdition = Array.new
		Thread.new {
			coAuthors.each do |row1|
				Thread.new {
					coAuthors.each do |row2|

						distance = Levenshtein.normalized_distance(row1[2], row2[2])
						if distance < 0.5 && distance != 0.0 then
							line = Hash.new
							line[0] = row1[2]
							line[1] = row1[1]
							line[2] = row2[1]
							line[3] = row2[2]
							line[4] = distance
							distanceEdition.push(line)
						end
					end
				}
		end
		}
		return distanceEdition
	end



#######################################################
# organiza os co-autores por refBy
# --> Entrada: array of hashes
# --> Saida: object
#######################################################
	def organizeCoAuthors (triples)

		profiles = Array.new
		triples.each do |row|
			if !profiles.find { |h| h["refBy"] == row[0]} then
				hashProfile = Hash.new
				hashProfile["name"] = row[3]
				hashProfile["refBy"] = row[0]
				profiles.push(hashProfile)
			end

		end

		articles = Array.new
		triples.each do |row|
			if !articles.find { |h| h["refByArticle"] == row[1]} then
				hashArticle = Hash.new
				hashArticle["refBy"] = row[0]
				hashArticle["refByArticle"] = row[1]
				hashArticle["article"] = row[5]
				hashArticle["conference"] = row[6]
				hashArticle["year"] = row[7]
				articles.push(hashArticle)
			end
		end
		logger.info articles


		coAuthors = Array.new
		triples.each do |row|
			if !coAuthors.find { |h| h["coAuthor"] == row[1]} then
				hashCoAuthors = Hash.new
				hashCoAuthors[0] = row[0]
				hashCoAuthors[1] = row[1]
				hashCoAuthors[2] = row[4]
				hashCoAuthors[3] = row[2]
				coAuthors.push(hashCoAuthors)
			end
		end
		return coAuthors
	end

#######################################################
# Transforma os dados vindos do vituoso do formato CSV para um Array com Hash
# Já parametrizado conforme o esperado
# --> Entrada: Array em CSV
# --> Saida: Array
#######################################################
	def csvToArray (data, contFields)
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
   					line[i] = row[i].encode("ASCII-8BIT").force_encoding("utf-8")
   					i += 1
   				end
   				# collumn 3 = nome do rdf
   				line[3] = line[3].parameterize.to_s
   				line[3] = retireConectivesNames(line[3])
   				# collumn 4 = nome do co-author
   				line[4] = line[4].parameterize.to_s
   				line[4] = retireConectivesNames(line[4])
   				# collumn 5 = nome do artigo
				line[5] = line[5].parameterize.to_s
   				line[5] = retireConectives(line[5])
   				# collumn 6 = nome do congresso
   				line[6] = line[6].parameterize.to_s
   				line[6] = retireConectives(line[6])

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

#######################################################
# retira todos os conectivos(stopwords) do nome da pessoa
# --> Entrada: string
# --> Saida: string
#######################################################
	def retireConectivesNames (name)
			name = name.gsub('-da-', '-')
			name = name.gsub('-de-', '-')
			name = name.gsub('-di-', '-')
			name = name.gsub('-do-', '-')
			name = name.gsub('-das-', '-')
			name = name.gsub('-dos-', '-')
			name = name.gsub('-e-', '-')
			name = name.gsub('-na-', '-')
			name = name.gsub('-nos-', '-')
			name = name.gsub('-van-', '-')
			name = name.gsub('-von-', '-')
			name = name.gsub('-y-', '-')
			name = name.gsub('-del-', '-')

		return name
	end

end