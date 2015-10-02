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
		valueNA 		= values['nameArticle'].to_i;
		valueR 			= values['rank'].to_i;
		valueConf 		= values['conference'].to_i;
		valueY 			= values['year'].to_i;
		valueDisambiguation 	= values['vd'].to_i;
		valueLevenshtein 	= values['levDist'].to_f;

		estatistica = Array.new
		nivel1 = 0	# Se os perfis são diferentes
		nivel2 = 0	# Verificação da distância
		nivel3 = 0	# Desambiguados
		nivel4 = 0 	# Não desambiguados
		nivel5 = 0	# Valor acima do filtro (sames)
		nivel6 = 0	# artigos iguais
		nivel7 = 0	# artigos muito proximos

		entitiesTemp = entities.dup
		entitySames = Array.new
		entitiesTemp.each do | ent |
			est = Hash.new
			entityA = ent.dup
			entityB = ent.dup
			sames = Array.new
			indexes = Array.new
			indexA = 0
			entityA.each do | a |
				indexB = 0
				Rails.logger.info "===================================================="
				Rails.logger.info "DESAMBIGUANDO ENTIDADE"
				Rails.logger.info " "+a[5]
				Rails.logger.info "===================================================="
				entityB.each do | b |
					if(a[0] != b[0]) then
						nivel1 = nivel1+1
						tempIndex1 = Array.new
						tempIndex1.push(indexA)
						tempIndex1.push(indexB)
						tempIndex2 = Array.new
						tempIndex2.push(indexB)
						tempIndex2.push(indexA)
						if(!( (indexes.include?(tempIndex1)) || (indexes.include?(tempIndex2)) )) then 			# verifica se na tabela de indexes tem a ocorencia da desambiguacao, para evitar duplicacao
							distance = Levenshtein.normalized_distance(a[3],b[3], valueLevenshtein) 		# verifica a distancia do author
							# colocar um cont aqui
							nivel2 = nivel2+1
							if distance != nil then
								Rails.logger.info "======================="
								Rails.logger.info a[3]
								Rails.logger.info b[3]
								Rails.logger.info a[2]
								Rails.logger.info b[2]
								vd = 0
								# name article == name article
								if(a[5] == b[5]) then
									vd += valueNA
									nivel6 = nivel6+1
								else
									distanceArticle = Levenshtein.normalized_distance(a[5],b[5], 0.05) # verifica a distancia do author
									if distanceArticle != nil then
										vd += valueNA-1
										nivel7 = nivel7+1
									end
								end
								# rank == rank
								if (a[4] == b[4]) then
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
								if(vd > valueDisambiguation) then
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
									indexes.push(tempIndex1)
								end
								nivel3 = nivel3+1
								Rails.logger.info "value desambiguation: #{vd}"
								Rails.logger.info "======================="
							else
								nivel4 = nivel4+1
								Rails.logger.info "Não houve Desambiguação entre"
								Rails.logger.info "="
								Rails.logger.info a[3]
								Rails.logger.info b[3]
								Rails.logger.info "======================="
							end

						end
					end
				indexB = indexB+1
				end
			indexA = indexA+1
			end

			# estatistica de cada entidade
			est['nivel1'] = nivel1
			est['nivel2'] = nivel2
			est['nivel3'] = nivel3
			est['nivel4'] = nivel4
			est['nivel5'] = sames.size
			est['nivel6'] = nivel6
			est['nivel7'] = nivel7
			estatistica.push(est);
			## ====

			sames.each do |same|
				Rails.logger.info "===================================="
				Rails.logger.info "LOG DE DISAMBIGUATION"
				Rails.logger.info "===================================="
				Rails.logger.info "AUTHOR 1 ====== AUTHOR 2"
				Rails.logger.info same[0][3] +" <==> "+ same[1][3]
				Rails.logger.info
				Rails.logger.info "COMPARSIONS"
				Rails.logger.info "["+same[0][0] +"] == ["+same[1][0]+"]"
				Rails.logger.info "-----"
				Rails.logger.info same[0][5] +" <==> "+ same[1][5]
				Rails.logger.info same[0][4] +" <==> "+ same[1][4]
				Rails.logger.info same[0][6] +" <==> "+ same[1][6]
				Rails.logger.info same[0][7] +" <==> "+ same[1][7]
				Rails.logger.info "-----"
				Rails.logger.info "[VD] value disambiguation: " + same[2].to_s
				Rails.logger.info " "
				Rails.logger.info "============"
				Rails.logger.info "========"
				Rails.logger.info "==="
			#	Rails.logger.info same[0][4] +" do RDF "+ same[0][0] +" - "+ same[0][3]  +" -- "+ same[0][8]+" == "+ same[1][4] +" do RDF "+ same[1][0] +" - "+ same[1][3] + " -- "+ same[1][8]
			end

			entitySames.push(sames)
		end

		fileEstatistica = FileArray.new
		fileEstatistica.insertLogFile(estatistica, 1)

		return entitySames
	end

#######################################################
# Cria as triplas e exporta elas em formato .nt
# --> Entrada: array of hashes
# --> Saida: file and visualization
#######################################################

	def createTriples (vector, nameGraph)
		graph = RDF::Graph.new
		ufpel = RDF::Vocabulary.new("http://ufpel.edu.br/")
		disambiguation = RDF::Vocabulary.new("http://vivoext.org/")
		cont = 0
		triples = []

		vector.each do | same |

			Rails.logger.info same
			if(same.empty? == false) then
				temp = RDF::Graph.new

				id = "%06d" % cont
				graph << [disambiguation.pair+"#has_dis-"+id, RDF.type, disambiguation.pair]
				graph << [disambiguation.pair+"#has_dis-"+id, RDF.type, RDF::OWL.NamedIndividual]
				graph << [disambiguation.pair+"#has_dis-"+id, RDF::RDFS.label, id.to_s+"@pt"]
				graph << [disambiguation.pair+"#has_dis-"+id, disambiguation.pair+"#value_disambiguation", same[0][2]]
				graph << [ufpel.lattes+same[0][0][8], disambiguation.pair+"#has_dis", disambiguation.pair+"#has_dis-"+id]
				graph << [ufpel.lattes+same[0][1][8], disambiguation.pair+"#has_dis", disambiguation.pair+"#has_dis-"+id]


				temp << [disambiguation.pair+"#has_dis-"+id, RDF.type, disambiguation.pair]
				temp << [disambiguation.pair+"#has_dis-"+id, RDF.type, RDF::OWL.NamedIndividual]
				temp << [disambiguation.pair+"#has_dis-"+id, RDF::RDFS.label, id.to_s+"@pt"]
				temp << [disambiguation.pair+"#has_dis-"+id, disambiguation.pair+"#value_disambiguation", same[0][2]]
				temp << [ufpel.lattes+same[0][0][8], disambiguation.pair+"#has_dis", disambiguation.pair+"#has_dis-"+id]
				temp << [ufpel.lattes+same[0][1][8], disambiguation.pair+"#has_dis", disambiguation.pair+"#has_dis-"+id]


			triples[cont] = temp.dump(:ntriples)
			cont = cont+1
			end
		end
		graph.dump(:ntriples)
		RDF::Writer.open(nameGraph) { |writer| writer << graph }
		return triples
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
						distance = Levenshtein.normalized_distance(row1[2], row2[2], 0.5)
						if distance != nil then
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