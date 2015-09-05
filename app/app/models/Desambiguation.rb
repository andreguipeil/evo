require 'rdf'
require 'linkeddata'
require 'rdf/ntriples'
require 'rdf/nquads'
require 'set'



class Desambiguation

#######################################################
# La desambiguacion
# --> Entrada: array of entities
# --> Saida: array of desambiguation [element a, element b, value_desambiguation]
#######################################################

	def desambiguationEntities (entities, values)
		valueNA 	= values['nameArticle'].to_i;
		valueR 		= values['rank'].to_i;
		valueConf 	= values['conference'].to_i;
		valueY 		= values['year'].to_i;
		Rails.logger.info values

		entitiesTemp = entities.dup
		entitySames = Array.new
		entitiesTemp.each do | ent |
			entityA = ent.dup
			entityB = ent.dup
			sames = Array.new

			entityA.each do | a |
				if(entityB.size > 0) then
					newEntity = Array.new
					entityB.each do | b |
						if(a[0] != b[0]) then
							distance = Levenshtein.normalized_distance(a[4],b[4])
							if distance <= 0.5 || distance == 0.0 then
								Rails.logger.info "======================="
								Rails.logger.info a
								Rails.logger.info b

								vd = 0
								# name article == name article
								if(a[5] == b[5]) then
									vd += valueNA
								else
									if distance <= 0.2 || distance == 0.0 then
										vd += valueNA-1
									end
								end
								# rank == rank
								if (a[2] == b[2]) then
									vd += valueR
								end
								# conference == conference
								if (a[6] == b[6]) then
									vd += valueConf
								end
								# year == year
								if(a[7] == b[7]) then
									vd += valueY
								end
								# value_desambiguation is greater than 3
								if(vd > 3) then
									same = Hash.new
									same[0] = a
									same[1] = b
									same[2] = vd
									#troca de idp para o id verdadeiro
									#if(a[8].include? 'idp')
									#	if(!b[8].include? 'idp')
									#		a[8] = b[8]
									#		a[4] = b[4]
									#	end
									#else
									#	if(b[8].include? 'idp')
									#		b[8] = a[8]
									#		b[4] = a[4]
									#	end
									#end
									sames.push(same)
								end
								Rails.logger.info "value desambiguation: #{vd}"
								Rails.logger.info "======================="
							else
								newEntity.push(b)
							end
						else
							newEntity.push(b)
						end
					end
					entityB = newEntity
				end
			end

			Rails.logger.info "===================================="
			Rails.logger.info "LOG DE DISAMBIGUATION"
			Rails.logger.info "===================================="

			sames.each do |same|
				Rails.logger.info "COAUTHOR 1 ====== COAUTHOR 2"
				Rails.logger.info same[0][4] +" <==> "+ same[1][4]
				Rails.logger.info
				Rails.logger.info "COMPARSIONS"
				Rails.logger.info "["+same[0][0] +"] == ["+same[1][0]+"]"
				Rails.logger.info "-----"
				Rails.logger.info same[0][5] +" <==> "+ same[1][5]
				Rails.logger.info same[0][2] +" <==> "+ same[1][2]
				Rails.logger.info same[0][6] +" <==> "+ same[1][6]
				Rails.logger.info same[0][7] +" <==> "+ same[1][7]
				Rails.logger.info "-----"
				Rails.logger.info "ID CHANGE"
				Rails.logger.info same[0][8] +" <==> "+ same[1][8]
				Rails.logger.info "+++"
				Rails.logger.info "[VD] value disambiguation: " + same[2].to_s
				Rails.logger.info " "
				Rails.logger.info "============"
				Rails.logger.info "========"
				Rails.logger.info "==="
			#	Rails.logger.info same[0][4] +" do RDF "+ same[0][0] +" - "+ same[0][3]  +" -- "+ same[0][8]+" == "+ same[1][4] +" do RDF "+ same[1][0] +" - "+ same[1][3] + " -- "+ same[1][8]
			end
			entitySames.push(sames)
		end
		createTriples(entitySames)
	end

#######################################################
# Cria as triplas e exporta elas em formato .nt
# --> Entrada: array of hashes
# --> Saida: file and visualization
#######################################################

	def createTriples (vector)

		Rails.logger.info vector
		graph = RDF::Graph.new

		Rails.logger.info RDF.type
		Rails.logger.info RDF::RDFS.label
		Rails.logger.info RDF::OWL.NamedIndividual
		ufpel = RDF::Vocabulary.new("http://ufpel.edu.br/")
		disambiguation = RDF::Vocabulary.new("http://vivoext.org/")
		Rails.logger.info disambiguation.pair+"#value_disambiguation"
		sames1 = []
		sames2 = []
		sames3 = []

		sames1.push("http://ufpel.edu.br/lattes/0702035357125121#author-idp5985904")
		sames1.push("http://ufpel.edu.br/lattes/2809172806147764#author-idp21609248")
		sames2.push("http://ufpel.edu.br/lattes/6927803856702261#author-6927803856702261")
		sames2.push("http://ufpel.edu.br/lattes/0702035357125121#author-idp6009760")
		sames3.push("http://ufpel.edu.br/lattes/0702035357125121#author-idp6000096")
		sames3.push("http://ufpel.edu.br/lattes/0741704260227015#author-idp12601472")

		Rails.logger.info disambiguation.pair


		cont = 0
		Rails.logger.info cont
		Rails.logger.info vector.size


		vector.each do | same |
			if(same.empty? == false) then
				Rails.logger.info cont
				graph << [disambiguation.pair+"#has_dis-"+cont, RDF.type, disambiguation.pair]
				graph << [disambiguation.pair+"#has_dis-"+cont, RDF.type, RDF::OWL.NamedIndividual]
				graph << [disambiguation.pair+"#has_dis-"+cont, RDF::RDFS.label, '"#{cont}"@pt']
				graph << [disambiguation.pair+"#has_dis-"+cont, disambiguation.pair+"#value_disambiguation", same[0][2]]
				graph << [ufpel.lattes+same[0][0][8], disambiguation.pair+"#has_dis", disambiguation.pair+"#has_dis-"+cont]
				graph << [ufpel.lattes+same[0][1][8], disambiguation.pair+"#has_dis", disambiguation.pair+"#has_dis-"+cont]
				cont = cont+1
			end
		end
		graph.dump(:ntriples)
		RDF::Writer.open("hellou.nt") { |writer| writer << graph }
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
		Rails.logger.info articles


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


end