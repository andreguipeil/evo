class Desambiguation

#######################################################
# La desambiguacion
# --> Entrada: array of entities
# --> Saida: array of desambiguation [element a, element b, value_desambiguation]
#######################################################

	def desambiguationEntities (entities)
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
									vd += 2
								end
								# rank == rank
								if (a[2] == b[2]) then
									vd += 2
								end
								# conference == conference
								if (a[6] == b[6]) then
									vd += 3
								end
								# year == year
								if(a[7] == b[7]) then
									vd += 1
								end
								# value_desambiguation is greater than 3
								if(vd > 3) then
									same = Hash.new
									same[0] = a
									same[1] = b
									same[2] = vd
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
			Rails.logger.info "LOG DE DESAMBIGUAÇÃO"
			Rails.logger.info "===================================="

			sames.each do |same|
				Rails.logger.info same[0][4] +" do RDF "+ same[0][0] +" -"+ same[0][3]  +" == "+ same[1][4] +" do RDF "+ same[1][0] +" -"+ same[1][3]
			end
			entitySames.push(sames)
		end
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