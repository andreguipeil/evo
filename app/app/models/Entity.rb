require 'benchmark'

class Entity

#######################################################
# Cria cluster de artigos
# --> Entrada: array of triples
# --> Saida: array of peoples
#######################################################
	def clusterizationByRefBy(articles, profiles)
		#Rails.logger.info "aqui na clusterização"
		#Rails.logger.info articles
		Rails.logger.info "Clusterization refBy"

		entityRefBy  = Hash.new 											# varre os profiles para pegar todas as pessoas que serao desambiguadas
		profiles.each do | row |
			entityRefBy[row['refBy']] = Array.new
		end

		articles.each do | art |
			entityRefBy.each { | key, value |
				if( key == art['refBy']) then
					entityRefBy[key].push(art)
				end
			}
		end
		return entityRefBy
	end

#######################################################
# Cria cluster de autores
# --> Entrada: array of triples
# --> Saida: array of peoples
#######################################################

	def clusterizationByName(authors, lev, profiles)
		#Rails.logger.info authors
		#Rails.logger.info profiles
		#Rails.logger.info lev
		Rails.logger.info "Clusterization"
		entityName  = Hash.new 											# varre os profiles para pegar todas as pessoas que serao desambiguadas
		profiles.each do | row |
			entityName[row['nameNormalized']] = Array.new
		end

		authors.each do | row |												# clusteriza as pessoas
			entityName.each {  | key, value |
				distance = Levenshtein.normalized_distance(key,row[3], lev)
				if distance != nil then
					if distance <= lev.to_f then								# verifica a distancia se bater adiciona
						#Rails.logger.info distance.to_s+" entre :"+key.to_s+" "+row[3].to_s		# distancia de levenshtein em 0.2 para artigos aproximados
						entityName[key].push(row)
					end
				end
			}
			Rails.logger.info row[3]
		end
		entities = Array.new

		entityName.each {  | key, value |
			entities.push(value)
		}
		return entities
	end


#######################################################
# Cria blocagem somente por aritgos
# --> Entrada: array of triples
# --> Saida: array of articles
#######################################################

	def clusterizationByArticle (triples, levenshtein)
		statistics = Array.new 			# array estatistica possui todos os dados estatisticos que vão para o log
		est = Hash.new				# cria uma hash para declarar os dados estaticos atraves de nome
		temp = []
		triples.each do | t |
			if(!temp.include? t[1]) then
				temp.push(t[1])
			end
		end

		Rails.logger.info temp.size

		Rails.logger.info "Clusterization by Article"
		entities = Array.new
		sideA 	= triples.dup 			# duplica por copia
		sideB 	= triples.dup 			# duplica por copia
		Rails.logger.info triples.size		# faz a conta do numero de triplas que vem do banco
		Benchmark.bm do | x |
			Rails.logger.info x.report("By Article") {

				sideA.each do |a|			# percorre a
					#Rails.logger.info sideB.size
					if(sideB.size > 0) then
						ent 	  = Array.new
						newSide = Array.new
							sideB.each do |b|	# percorre b
								# clusterizando por artigo
								distance = Levenshtein.normalized_distance(a[5],b[5], levenshtein)		# distancia de levenshtein em 0.2 para artigos aproximados
								if distance != nil then								# verifica a distancia se bater adiciona
								#if ( a[5] == b[5] )
									arr = b
									ent.push(arr)
								else
									newSide.push(b)
								end
							end
						entities.push(ent)				# entities faz a clusterização pro artigos
						sideB = newSide				# sideB recebe todos os artigos que nao foram selecionados
					end
				end

			}
		end
		validateClusterization(entities)

		return entities
	end

#######################################################
# Cria blocagem de aritgos
# --> Entrada: array of triples
# --> Saida: array of articles
#######################################################

	def clusterizationByArticleYear(triples, levenshtein)
		entities = Array.new
		estatistica = Array.new 					# array estatistica possui todos os dados estatisticos que vão para o log
		est = Hash.new							# cria uma hash para declarar os dados estaticos atraves de nome
		est['numero_triplas'] = triples.size				# faz a conta do numero de triplas que vem do banco
		Benchmark.bm do | x |
			Rails.logger.info x.report("By Article/Year") {
				entityYear  = Hash.new 					# varre nas triplas a quantidade de anos diferentes para poder clusterizar
				triples.each do | row |
					entityYear[row[7]] = Array.new

				end
				est['numero_entidades_ano'] = entityYear.size			# numero de entidades criadas por ano

				triples.each do | row |						# popula o array de anos com os artigos/autores
					entityYear[row[7]].push(row)
				end

				Rails.logger.info "Clusterization by Article/Year"

				contClusterizacao = 0;
				entityYear.each { | year, array |					# percorre as entidades por ano, cara entidade possui um x de autores
					sideA 	= array.dup 					# duplica por copia
					sideB 	= array.dup      					# duplica por copia
					y = Hash.new
					y[year] = array.size
					estatistica.push(y)
					sideA.each do |a|					# percorre a
						#Rails.logger.info sideB.size
						if(sideB.size > 0) then
							ent 	  = Array.new
							newSide = Array.new

								sideB.each do |b|								# percorre b
									# clusterizando por artigo
									## colocar um cont aqui
									contClusterizacao = contClusterizacao+1
									distance = Levenshtein.normalized_distance(a[5],b[5], levenshtein)		# distancia de levenshtein em 0.2 para artigos aproximados
									if distance != nil then							# verifica a distancia se bater adiciona
										arr = b
										ent.push(arr)
									else
										newSide.push(b)
									end
								end

							entities.push(ent)									# entities faz a clusterização pro artigos
							sideB = newSide									# sideB recebe todos os artigos que nao foram selecionados
						end
					end
				}
			}
		end
		#est['contClusterizacao'] = contClusterizacao
		#estatistica.push(est)
		#fileEstatistica = FileArray.new
		#fileEstatistica.insertLogFile(estatistica, 0)
		validateClusterization(entities)
		return entities
	end

	def validateClusterization(entities)

		total = 0
	           	entities.each do | ent |
			total = total + ent.size
	#		if (ent.size > 0) then
	#			ent.each do | e |
	#				Rails.logger.info "#{e[5]} #{e[1]}"
	#			end
	#			Rails.logger.info "    "
	#		end

		end
		Rails.logger.info "====================="
		Rails.logger.info "====================="
		Rails.logger.info "====================="
		contEnt = 0
		contNoEnt = 0
		entities.each do  | ent |
			if (ent.size > 0) then
				flag = 0
				ent.each do | e |
					ent.each do | d |
						if (e[1] != d[1])
							flag = 1

						end
					end
					if (flag != 1) then
					#	Rails.logger.info "#{e[5]} #{e[1]}"
					end

				end
				if flag == 0 then
					contEnt = contEnt+1
				else
					contNoEnt = contNoEnt+1
				end
				#Rails.logger.info "    "
			end
		end
		vazias = 0
		entities.each do | ent |
			if(ent.size == 0) then
				vazias = vazias + 1
			end

		end

		ents = total-vazias
		Rails.logger.info "Total: #{total}"
		Rails.logger.info "Vazias: #{vazias}"
		Rails.logger.info "Total de Entidades: #{ents}"
		Rails.logger.info "Quantidade de entidades que podem ser desambiguadas: #{contEnt}"
		Rails.logger.info "Quantidade de Entidades que estão sozinhas: #{contNoEnt}"
		Rails.logger.info "cima batendo com o de baixo"


		Rails.logger.info "Entidades Vazias: #{vazias}"

	end


end