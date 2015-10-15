require 'rdf'
require 'linkeddata'
require 'rdf/ntriples'
require 'rdf/nquads'
require 'set'



class Disambiguation

#######################################################
# La desambiguacion
# --> Entrada: array of entities and config values
# --> Saida: array of desambiguation [element a, element b, value_desambiguation]
#######################################################
	def disambiguationByNameAuthor(entities, values, profiles, articles)
		#Rails.logger.info "Aqui no disambiguation"
		#Rails.logger.info profiles
		#Rails.logger.info entities
		#Rails.logger.info values
		#Rails.logger.info articles


		valueNameAuthor 		= values['name_author'].to_i
		valueNameAuthorLev 		= values['name_author_lev'].to_f
		valueNameArticle 		= values['name_article'].to_i
		valueNameArticleLev		= values['name_article_lev'].to_f
		valueNameConference 		= values['name_conference'].to_i
		valueNameConferenceLev 	= values['name_conference_lev'].to_f
		valueRank 			= values['rank'].to_i
		valueYear 			= values['year'].to_i
		valueDisambiguation 		= values['vd'].to_i

		entitiesTemp = entities.dup
		articlesTemp = articles.dup
		entitySames = Array.new
		Rails.logger.info "Disambiguating"
		entitiesTemp.each do | ent |
			entityA = ent.dup
			sames = Array.new
			profile = Hash.new
			entityA.each do | a |
				if(!a[2].include? 'idp')
					profile[0] = a[0]
					profile[1] = a[2]
				end
			end

			entityA.each do | a |
				if (a[0] != profile[0]) then
					vd = 0				# zera o vd

					articlesTemp.each do | curr |
						if (curr[profile[0]]) then
							artCurr = curr[profile[0]]
							artCurr.each do | art |
								distanceNameArticle = Levenshtein.normalized_distance(a[5], art['articleNormalized'], valueNameArticleLev) 		# verifica a distancia do author
								if(distanceNameArticle != nil) then
									b = Hash.new
									b[0] = art['refBy']
									b[1] = art['refByArticle']
									b[2] = art['refByAuthor']
									b[3] = art['name']
									b[4] = art['rank']
									b[5] = art['articleNormalized']
									b[6] = art['conferenceNormalized']
									b[7] = art['year']

									vd += valueNameAuthor 	# conta o valor do autor
									vd += valueNameArticle

									# rank == rank
									if (a[4] == b[4]) then
										vd += valueRank
									end

									distanceNameConference = Levenshtein.normalized_distance(a[6], b[6], valueNameConferenceLev) # verifica a distancia do author
									if distanceNameConference != nil then
										vd += valueNameConference
									end

									# year == year
									if(a[7] == b[7]) then
										vd += valueYear
									end

									same = Hash.new
									same[0] = a
									same[1] = b
									same[2] = vd
									sames.push(same)
									vd = 0
								end
							end
						end
					end

				end
			end
			Rails.logger.info "..."
			if sames.size > 0 then
				entitySames.push(sames)
			end
		end
		cont = 0
		entitySames.each do | same |
			cont += same.size
		end
		Rails.logger.info cont
		return entitySames
	end

#######################################################
# La desambiguacion
# --> Entrada: array of entities
# --> Saida: array of desambiguation [element a, element b, value_desambiguation]
#######################################################

	def disambiguationByArticleYear (entities, values)
		valueNameAuthor 		= values['name_author'].to_i
		valueNameAuthorLev 		= values['name_author_lev'].to_f
		valueNameArticle 		= values['name_article'].to_i
		valueNameArticleLev		= values['name_article_lev'].to_f
		valueNameConference 		= values['name_conference'].to_i
		valueNameConferenceLev 	= values['name_conference_lev'].to_f
		valueRank 			= values['rank'].to_i
		valueYear 			= values['year'].to_i
		valueDisambiguation 		= values['vd'].to_i

		entitiesTemp = entities.dup
		entitySames = Array.new
		Rails.logger.info "Disambiguating"
		entitiesTemp.each do | ent |
			entityA = ent.dup
			sames = Array.new
			indexes = Array.new
			profilesOriginals = Array.new

			entityA.each do | a |
				#Rails.logger.info "===================================================="
				#Rails.logger.info "DESAMBIGUANDO ENTIDADE"
				#Rails.logger.info " "+a[5]
				#Rails.logger.info "===================================================="


				if(!a[2].include? 'idp')
					profilesOriginals.push(a)
				end
				# Rails.logger.info "PROFILES ORIGINALS"
				# profilesOriginals.each do | ori |
				#	Rails.logger.info ori[2]
				# end
			end
			#Rails.logger.info "PROFILES ORIGINALS"
			#profilesOriginals.each do | ori |
			#	Rails.logger.info ori[2]
			#end

			entityA.each do | a |
				indexA = 0
				if(profilesOriginals.size > 1) then
					profilesOriginals.each do | b |
						indexB = 0
						#Rails.logger.info "COMPARACAO"
						#Rails.logger.info a[3]+" - "+ a[0]
						#Rails.logger.info b[3]+" - "+ b[0]

						if(a[0] != b[0]) then				# verifica se é do perfil dele mesmo, se for nao precisa comparar pq ou vai ser ele mesmo, ou outros autores
							distanceName = Levenshtein.normalized_distance(a[3], b[3], valueNameAuthorLev) 		# verifica a distancia do author
							#Rails.logger.info distanceName
							#Rails.logger.info "Rolando disambiguação"
							#Rails.logger.info "="
							#Rails.logger.info a[3]
							#Rails.logger.info b[3]
							#Rails.logger.info "======================="
							if distanceName != nil then
								vd = 0				# zera o vd
								vd += valueNameArticle 	# adiciona o valor do artigo
								vd += valueNameAuthor 	# conta o valor do autor

								# rank == rank
								if (a[4] == b[4]) then
									vd += valueRank
								end
								# conference == conference
								if(a[6] == b[6]) then
									vd += valueNameConference
								else
									distanceConference = Levenshtein.normalized_distance(a[6], b[6], valueNameConferenceLev) # verifica a distancia do author
									if distanceConference != nil then
										vd += valueNameConference
									end
								end

								# year == year
								if(a[7] == b[7]) then
									vd += valueYear
								end

								same = Hash.new
								same[0] = a
								same[1] = b
								same[2] = vd
								sames.push(same)
							#	indexes.push(tempIndex1)
							else
								#Rails.logger.info "Não houve Desambiguação entre"
								#Rails.logger.info "="
								#Rails.logger.info a[3]
								#Rails.logger.info b[3]
								#Rails.logger.info "======================="
							end
						end
					end
				end
			end

		#	sames.each do |same|
		#		Rails.logger.info "===================================="
		#		Rails.logger.info "LOG DE DISAMBIGUATION"
		#		Rails.logger.info "===================================="
		#		Rails.logger.info "AUTHOR 1 ====== AUTHOR 2"
		#		Rails.logger.info same[0][3] +" <==> "+ same[1][3]
		#		Rails.logger.info
		#		Rails.logger.info "COMPARSIONS"
		#		Rails.logger.info "["+same[0][0] +"] == ["+same[1][0]+"]"
		#		Rails.logger.info "-----"
		#		Rails.logger.info same[0][5] +" <==> "+ same[1][5]
		#		Rails.logger.info same[0][4] +" <==> "+ same[1][4]
		#		Rails.logger.info same[0][6] +" <==> "+ same[1][6]
		#		Rails.logger.info same[0][7] +" <==> "+ same[1][7]
		#		Rails.logger.info "-----"
		#		Rails.logger.info "[VD] value disambiguation: " + same[2].to_s
		#		Rails.logger.info " "
		#		Rails.logger.info "============"
		#		Rails.logger.info "========"
		#		Rails.logger.info "==="
		#	#	Rails.logger.info same[0][4] +" do RDF "+ same[0][0] +" - "+ same[0][3]  +" -- "+ same[0][8]+" == "+ same[1][4] +" do RDF "+ same[1][0] +" - "+ same[1][3] + " -- "+ same[1][8]
		#	end
			Rails.logger.info "..."
			if sames.size > 0 then
				entitySames.push(sames)
			end
		end
		cont = 0
		entitySames.each do | same |
			cont += same.size
		end
		Rails.logger.info cont
		return entitySames
	end


#######################################################
# Cria as triplas e exporta elas em formato .nt
# --> Entrada: array of hashes
# --> Saida: file and visualization
#######################################################

	def createTriples (entitiesSames, nameGraph)
		graph = RDF::Graph.new
		ufpel = RDF::Vocabulary.new("http://ufpel.edu.br/")
		disambiguation = RDF::Vocabulary.new("http://vivoext.org/")
		cont = 0
		triples = []

		entitiesSames.each do | entity |
			#Rails.logger.info entity
			entity.each do | same |
				#Rails.logger.info same
				if(same.empty? == false) then
					temp = RDF::Graph.new

					id = "%06d" % cont
					graph << [disambiguation.pair+"#has_dis-"+id, RDF.type, disambiguation.pair]
					graph << [disambiguation.pair+"#has_dis-"+id, RDF.type, RDF::OWL.NamedIndividual]
					graph << [disambiguation.pair+"#has_dis-"+id, RDF::RDFS.label, id.to_s+"@pt"]
					graph << [disambiguation.pair+"#has_dis-"+id, disambiguation.pair+"#value_disambiguation", same[2]]
					graph << [ufpel.lattes+same[0][2].gsub("http://ufpel.edu.br/lattes", ""), disambiguation.pair+"#has_dis", disambiguation.pair+"#has_dis-"+id]
					#graph << [ufpel.lattes+same[0][2].gsub("http://ufpel.edu.br/lattes", ""), RDF::RDFS.label, same[0][3]]
					graph << [ufpel.lattes+same[1][2].gsub("http://ufpel.edu.br/lattes", ""), disambiguation.pair+"#has_dis", disambiguation.pair+"#has_dis-"+id]
					#graph << [ufpel.lattes+same[1][2].gsub("http://ufpel.edu.br/lattes", ""), RDF::RDFS.label, same[1][3]]


					temp << [disambiguation.pair+"#has_dis-"+id, RDF.type, disambiguation.pair]
					temp << [disambiguation.pair+"#has_dis-"+id, RDF.type, RDF::OWL.NamedIndividual]
					temp << [disambiguation.pair+"#has_dis-"+id, RDF::RDFS.label, id.to_s+"@pt"]
					temp << [disambiguation.pair+"#has_dis-"+id, disambiguation.pair+"#value_disambiguation", same[2]]
					temp << [ufpel.lattes+same[0][2].gsub("http://ufpel.edu.br/lattes", ""), disambiguation.pair+"#has_dis", disambiguation.pair+"#has_dis-"+id]
					#temp << [ufpel.lattes+same[0][2].gsub("http://ufpel.edu.br/lattes", ""), RDF::RDFS.label, same[0][3]]
					temp << [ufpel.lattes+same[1][2].gsub("http://ufpel.edu.br/lattes", ""), disambiguation.pair+"#has_dis", disambiguation.pair+"#has_dis-"+id]
					#temp << [ufpel.lattes+same[1][2].gsub("http://ufpel.edu.br/lattes", ""), RDF::RDFS.label, same[1][3]]

				triples[cont] = temp.dump(:ntriples)
				cont = cont+1
				end
			end
		end
		Rails.logger.info "Quantidade de triplas criadas: "+ cont.to_s
		graph.dump(:ntriples)
		RDF::Writer.open(nameGraph) { |writer| writer << graph }
		return triples
	end


#######################################################
# La desambiguacion
# --> Entrada: array of entities
# --> Saida: array of desambiguation [element a, element b, value_desambiguation]
#######################################################

	def disambiguationByArticleYearWithOthers (entities, values)
		valueNameAuthor 		= values['name_author'].to_i
		valueNameAuthorLev 		= values['name_author_lev'].to_f
		valueNameArticle 		= values['name_article'].to_i
		valueNameArticleLev		= values['name_article_lev'].to_f
		valueNameConference 		= values['name_conference'].to_i
		valueNameConferenceLev 	= values['name_conference_lev'].to_f
		valueRank 			= values['rank'].to_i
		valueYear 			= values['year'].to_i
		valueDisambiguation 		= values['vd'].to_i

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
				#Rails.logger.info "===================================================="
				#Rails.logger.info "DESAMBIGUANDO ENTIDADE"
				#Rails.logger.info " "+a[5]
				#Rails.logger.info "===================================================="
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
							distance = Levenshtein.normalized_distance(a[3],b[3], valueNameAuthorLev) 		# verifica a distancia do author
							# colocar um cont aqui
							nivel2 = nivel2+1
							vd = 0
							if distance != nil then
								vd += valueNameAuthor 	# conta o valor do autor
								#Rails.logger.info "======================="
								#Rails.logger.info a[3]
								#Rails.logger.info b[3]
								#Rails.logger.info a[2]
								#Rails.logger.info b[2]
								# name article == name article
								if(a[5] == b[5]) then
									vd += valueNameArticle
									nivel6 = nivel6+1
								else
									distanceArticle = Levenshtein.normalized_distance(a[5], b[5], valueNameArticleLev) # verifica a distancia do author
									if distanceArticle != nil then
										vd += valueNameArticle-1
										nivel7 = nivel7+1
									end
								end
								# rank == rank
								if (a[4] == b[4]) then
									vd += valueRank
								end
								# conference == conference
								if(a[6] == b[6]) then
									vd += valueNameConference
								else
									distanceConference = Levenshtein.normalized_distance(a[6], b[6], valueNameConferenceLev) # verifica a distancia do author
									if distanceConference != nil then
										vd += valueNameConference
									end
								end

								# year == year
								if(a[7] == b[7]) then
									vd += valueYear
								end





								nivel3 = nivel3+1
								#Rails.logger.info "value desambiguation: #{vd}"
								#Rails.logger.info "======================="
							else
								nivel4 = nivel4+1
								#Rails.logger.info "Não houve Desambiguação entre"
								#Rails.logger.info "="
								#Rails.logger.info a[3]
								#Rails.logger.info b[3]
								#Rails.logger.info "======================="
							end
							same = Hash.new
							same[0] = a
							same[1] = b
							same[2] = vd
							sames.push(same)
							indexes.push(tempIndex1)
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

			if sames.size > 0 then
				entitySames.push(sames)
			end
		end


		#cont = 0
		#entitySames.each do | same |
		#	cont += same.size
		#end
		#Rails.logger.info cont
		#fileEstatistica = FileArray.new
		#fileEstatistica.insertLogFile(estatistica, 1)

		return entitySames
	end



end