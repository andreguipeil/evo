class Entity


#######################################################
# Cria blocagem de aritgos
# --> Entrada: array of triples
# --> Saida: array of articles
#######################################################

	def createEntities (triples)

		estatistica = Array.new 					# array estatistica possui todos os dados estatisticos que vão para o log
		est = Hash.new						# cria uma hash para declarar os dados estaticos atraves de nome
		est['numero_triplas'] = triples.size				# faz a conta do numero de triplas que vem do banco

		entityYear  = Hash.new 					# varre nas triplas a quantidade de anos diferentes para poder clusterizar
		triples.each do | row |
			entityYear[row[7]] = Array.new

		end
		est['numero_entidades_ano'] = entityYear.size		# numero de entidades criadas por ano

		triples.each do | row |						# popula o array de anos com os artigos/autores
			entityYear[row[7]].push(row)
		end

		entities = Array.new
		contClusterizacao = 0;
		entityYear.each { | year, array |				# percorre as entidades por ano, cara entidade possui um x de autores
			sideA 	= array.dup 					# duplica por copia
			sideB 	= array.dup      				# duplica por copia
			y = Hash.new
			y[year] = array.size
			estatistica.push(y)
			sideA.each do |a|					# percorre a
				# Rails.logger.info sideB.size
				if(sideB.size > 0) then
					ent 	  = Array.new
					newSide = Array.new

						sideB.each do |b|								# percorre b
							# clusterizando por artigo
							## colocar um cont aqui
							contClusterizacao = contClusterizacao+1
							distance = Levenshtein.normalized_distance(a[5],b[5], 0.2)		# distancia de levenshtein em 0.2 para artigos aproximados
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
		est['contClusterizacao'] = contClusterizacao
		estatistica.push(est)
		fileEstatistica = FileArray.new
		fileEstatistica.insertLogFile(estatistica, 0)

		return entities
	end


#######################################################
# Cria cluster de autores
# --> Entrada: array of triples
# --> Saida: array of peoples
#######################################################

	def clusterizationByName(authors, profiles)
		Rails.logger.info authors
		Rails.logger.info profiles

		entityName  = Hash.new 										# varre os profiles para pegar todas as pessoas que serao desambiguadas
		profiles.each do | row |
			entityName[row['nameNormalized']] = Array.new
		end

		authors.each do | row |										# clusteriza as pessoas
			entityName.each {  | key, value |
				distance = Levenshtein.normalized_distance(key,row[3], 0.2)
				if distance != nil then									# verifica a distancia se bater adiciona
					Rails.logger.info distance.to_s+" entre :"+key.to_s+" "+row[3].to_s		# distancia de levenshtein em 0.2 para artigos aproximados
					entityName[key].push(row)
				end
			}
		end

		entityName.each {  | key, value |
			Rails.logger.info key.to_s+" "+value.size.to_s
		}

	end

#######################################################
# Cria cluster de artigos
# --> Entrada: array of triples
# --> Saida: array of peoples
#######################################################

	def clusterizationByArticle(authors, articles)
		Rails.logger.info authors
		Rails.logger.info articles

		entityArticles  = Hash.new 										# varre os profiles para pegar todas as pessoas que serao desambiguadas
		articles.each do | row |
			entityArticles[row['articleNormalized']] = Array.new
		end

		authors.each do | row |										# clusteriza as pessoas
			entityArticles.each {  | key, value |
				distance = Levenshtein.normalized_distance(key,row[5], 0.2)
				if distance != nil then									# verifica a distancia se bater adiciona
					Rails.logger.info distance.to_s+" entre :"+key.to_s+" "+row[5].to_s		# distancia de levenshtein em 0.2 para artigos aproximados
					entityArticles[key].push(row)
				end
			}
		end
		Rails.logger.info entityArticles.size
		entityArticles.each {  | key, value |
			Rails.logger.info key.to_s+" "+value.size.to_s
		}

	end
end