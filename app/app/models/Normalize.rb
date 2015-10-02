class Normalize

$KCODE = 'UTF8'
#######################################################
# Transforma os dados vindos do vituoso do formato CSV para um Array com Hash
# Já parametrizado conforme o esperado
# --> Entrada: Array em CSV
# --> Saida: Array
#######################################################
	def csvToArray (data, contFields)
		i = 0;
		triples = Array.new
		data.shift
		data.each do |row|
			line = Hash.new
			while i < contFields do
				line[i] = row[i].encode("ASCII-8BIT").force_encoding("utf-8")
				i += 1
			end
			# collumn 3 = nome autor
			line[3] = line[3].parameterize.to_s
			line[3] = retireConectivesNames(line[3])
			# collumn 5 = nome do artigo
			line[5] = line[5].parameterize.to_s
			line[5] = retireConectives(line[5])
			# collumn 6 = conferencia
			line[6] = line[6].parameterize.to_s
			line[6] = retireConectives(line[6])

			#Rails.logger.info line[8]
			#line[8] = line[8].split("lattes").last
			#Rails.logger.info line[8]
			triples.push(line)
			i = 0
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

			#if  article[0].chr == 'a' and article[1].chr == '-'
			#	article = article.gsub("a-", '')
			#end
			#if article[0].chr == 'o' and article[1].chr == '-'
			#	article = article.gsub("o-", '')
			#end

			#if article[0].chr == 'o' and article[1].chr == 's' and article[2].chr == '-'
			#	article = article.gsub("os-", '')
			#end
			#if article[0].chr == 'a' and article[1].chr == 's' and article[2].chr == '-'
			#	article = article.gsub("as-", '')
			# end
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

#######################################################
# organiza todos os perfis do grafo
# --> Entrada: Array em CSV
# --> Saida: Array
#######################################################
	def normalizeProfiles (dataName, dataFamilyName, dataGivenName, type)
		profiles  = Array.new
		dataName.shift			# retira o primeiro elemento que é o cabecalho
		case type
		when 0
			dataFamilyName.shift		# retira o primeiro elemento que é o cabecalho
			dataGivenName.shift		# retira o primeiro elemento que é o cabecalho


			dataName.each do | row |
				profile = Hash.new
				profile['refBy'] = row[0].encode("ASCII-8BIT").force_encoding("utf-8")
				profile['name'] = row[1].encode("ASCII-8BIT").force_encoding("utf-8")
				profile['nameNormalized'] = row[1].encode("ASCII-8BIT").force_encoding("utf-8").parameterize.to_s
				profile['givenName'] = Array.new
				dataGivenName.each do | a |
					if a[0] == profile['refBy'] then
						profile["givenName"].push(a[1].encode("ASCII-8BIT").force_encoding("utf-8"))
					end
				end
				profile['familyName'] = Array.new
				dataFamilyName.each do | b |
					if b[0] == profile['refBy'] then
						profile["familyName"].push(b[1].encode("ASCII-8BIT").force_encoding("utf-8"))
					end
				end
				profiles.push(profile)
			end
		when 1
			dataName.each do | row |
				profile = Hash.new
				profile['refBy'] = row[0].encode("ASCII-8BIT").force_encoding("utf-8")
				profile['name'] = row[1].encode("ASCII-8BIT").force_encoding("utf-8")
				profiles.push(profile)
			end
		else
			Rails.logger.info "Erro no case"
		end
		return profiles
	end

#######################################################
# organiza todos os perfis do grafo
# --> Entrada: Array em CSV
# --> Saida: Array
#######################################################
	def normalizeArticles (dataArticles)

		articles  = Array.new
		dataArticles.shift			# retira o primeiro elemento que é o cabecalho

		Rails.logger.info dataArticles
		dataArticles.each do | art |
			article = Hash.new
			article['refBy'] = art[0].encode("ASCII-8BIT").force_encoding("utf-8")
			article['refByArticle'] = art[1].encode("ASCII-8BIT").force_encoding("utf-8")
			art[2] = art[2].encode("ASCII-8BIT").force_encoding("utf-8").parameterize.to_s
			art[2] = retireConectives(art[2])
			article['articleNormalized'] = art[2]
			article['conference'] = art[3].encode("ASCII-8BIT").force_encoding("utf-8")
			article['year'] = art[4].encode("ASCII-8BIT").force_encoding("utf-8")
			articles.push(article)
		end

		return articles
	end

end