require 'net/http'
require 'cgi'
require 'csv'
require 'rubygems'
require 'active_support/all'
require "thread"
require "json"
require "Query"
require "ConnectionSPARQL"
require "Disambiguation"
require "Entity"
require "FileArray"
require "Normalize"
require 'rdf'
require 'linkeddata'
require 'rdf/ntriples'
require 'rdf/nquads'
require 'set'
require 'trigram'
require 'amatch'
require 'benchmark'

$KCODE = 'UTF8'


class OficinaController < ApplicationController


respond_to :html, :json, :js

	def index
		respond_with(@ret)
	end


	def desambiguar
		graph = params[:graph]

		values = Hash.new
		values['graph'] = params[:graph]
		values['vd'] = params[:vd]
		values['name_author'] = params[:name_author]
		values['name_author_lev'] = params[:name_author_lev]
		values['name_author_tri'] = params[:name_author_tri]
		values['name_article'] = params[:name_article]
		values['name_article_lev'] = params[:name_article_lev]
		values['name_conference'] = params[:name_conference]
		values['name_conference_lev'] = params[:name_conference_lev]
		values['rank'] = params[:rank]
		values['year'] = params[:year]
		values['rules'] = params[:rules]

		arq = FileArray.new
		graphArq = graph.gsub('.com', '')
		graphArq = graphArq.gsub('http://', '')
		graphArq = graphArq.gsub('www.', '')
		graphArq = graphArq.gsub('.br', '')
		graphArq = graphArq.gsub('.org', '')
		graphArq = graphArq.gsub('.net', '')
		graphArq = graphArq.gsub('.edu', '')

		# nome do arquivo ==> grafo+criterio+leveinstein.txt
		# criterio: 1 -> nome do autor
		# criterio: 2 -> nome do artigo
		# criterio: 3 -> nome do artigo + ano
		case values['rules']
			when '1' then
				graphArq = graphArq+values['rules']+values['name_author_lev'].to_s.gsub('.', '')+values['name_author_tri'].to_s.gsub('.', '')
			when '2' then
				graphArq = graphArq+values['rules']+(values['name_article_lev'].to_s.gsub('.', ''))
				graphArq2 = graphArq+values['rules']+(values['name_author_lev'].to_s.gsub('.', ''))+(values['name_author_tri'].to_s.gsub('.', ''))
			when '3' then
				graphArq = graphArq+values['rules']+(values['name_article_lev'].to_s.gsub('.', ''))
				graphArq2 = graphArq+values['rules']+(values['name_author_lev'].to_s.gsub('.', ''))+(values['name_author_tri'].to_s.gsub('.', ''))
		end

		if(File.exist?(graphArq+".txt") != true) then

			# =========
			# STEP 1 - importing RDF data information
			# =========
			query = Query.new
			c = ConnectionSPARQL.new

			dataArticles = query.selectArticles(graph)
			tempArticles = c.runQuery(dataArticles)

			# tras todos os autores existentes no grafo
			dataAuthors = query.selectAuthors(graph)
			tempAuthors = c.runQuery(dataAuthors['query'])

			# tras todos os perfis existentes no grafo
			dataProfiles  = query.selectProfiles(graph)
			# monta os profiles existentes na base
			dataName  = c.runQuery(dataProfiles["queryProfileName"])
			dataGiven  = c.runQuery(dataProfiles["queryGivenName"])
			dataFamily = c.runQuery(dataProfiles["queryFamilyName"])

			# =========
			# STEP 2 - normalization of names and articles
			# =========
			parse =  Normalize.new
			logger.info "Normalizing..."
			articles = parse.normalizeArticles(tempArticles)
			profiles = parse.normalizeProfiles(dataName, dataGiven, dataFamily, 0)
			authors = parse.csvToArray(tempAuthors, dataAuthors['cont'])
			# =========
			# STEP 3 - create similar articles block's
			# =========
			logger.info "#{authors.size}"
			entities = Entity.new
			clustersArt = Hash.new						#
			case values['rules']
			when '1' then
				clusters = entities.clusterizationByName(authors, values['name_author_lev'].to_f, profiles)
				clustersArt = entities.clusterizationByRefBy(articles, profiles)
			when '2' then
				clusters = entities.clusterizationByArticle(authors, values['name_article_lev'].to_f)
			when '3' then
				clusters = entities.clusterizationByArticleYear(authors, values['name_article_lev'].to_f)
			end
			# =========
			# STEP 4 - load info quickly
			# =========
			arq.createArq(clusters, graphArq+'.txt')						# cria arquivo e insere os blocos semanticos
			arq.createArqProfiles(profiles, graphArq+'-profiles.txt')
			#arq.createArqArticles(clustersArt, graphArq+'-articles.txt')
		end
		authorsTemp = arq.readArq(graphArq+'.txt')					# carrega os blocos semanticos
		profilesTemp = arq.readArqProfiles(graphArq+'-profiles.txt')
		#articlesTemp = arq.readArqArticles(graphArq+'-articles.txt')
		arq.createArqConfig(values, graphArq+"-config.txt")
		#logger.info articlesTemp

		# =========
		# STEP 5 - Desambiguation
		# =========
		dis = Disambiguation.new
		case values['rules']
		when '1' then
			#entitySames = dis.disambiguationByNameAuthor(authorsTemp, values, profilesTemp, articlesTemp)
		when '2' then
			#entitySames = dis.disambiguationByArticleYear(authorsTemp, values)
			entitySames = dis.disambiguationByArticle(authorsTemp, values)
			#entitySamesWithGap = dis.disambiguationByArticleWithGap(authorsTemp, values)
			#etiquetation = dis.etiquetationByArticle(authorsTemp)
		when '3' then
			entitySames = dis.disambiguationByArticle(authorsTemp, values)
			#entitySamesWithGap = dis.disambiguationByArticleWithGap(authorsTemp, values)
			#etiquetation = dis.etiquetationByArticle(authorsTemp)
			#entitySames = dis.disambiguationByArticleYear(authorsTemp, values)
		end
		triples = dis.createTriples(entitySames, graphArq+'.nt')			#cria as triplas em um arquivo .nt
		tri = arq.readArqTriples(graphArq+'.nt')
		#arq.createArq(etiquetation, graphArq+"-etiquetation.txt")
		arq.createArq(entitySames, graphArq2+"-result.txt")
		#arq.createArq(entitySamesWithGap, graphArq+"withgap-result.txt")


		#etiquetation.each do | sames |
		#	logger.info " "
		#	logger.info "ENTIDADE ======"
		#	logger.info " "
		#	logger.info "ERRADOS"
		#	logger.info "====================================="
		#	sames.each do | s |
		#		if (s[3] == 1) then
		#		    logger.info  "#{s[0][3]} <=> #{s[1][3]}  vd: #{s[2]} == [ #{s[0][4]} #{s[0][6]}  #{s[0][7]} #{s[0][5]} ] == #{s[1][4]} #{s[1][6]}  #{s[1][7]} #{s[1][5]}"
		#		end
		#	end

		#	logger.info " "
		#	logger.info "CERTOS"
		#	logger.info "====================================="
		#	sames.each do | s |
		#		if (s[3] == 0) then
		#		    logger.info  "#{s[0][3]} <=> #{s[1][3]}  vd: #{s[2]} == [ #{s[0][4]} #{s[0][6]}  #{s[0][7]} #{s[0][5]} ] == #{s[1][4]} #{s[1][6]}  #{s[1][7]} #{s[1][5]}"
		#		end
		#	end

		#end


		# =========
		# STEP 6 - Store Triples
		# =========
		#query = Query.new
		#conn = ConnectionSPARQL.new
		#triples.each do | trip |
		#	logger.info trip
		#	q = query.insert(graph, trip)
		#	data = conn.runInsert(q)
		#end

		# =========
		# STEP 6 - Store Triples
		# =========
		#query = Query.new
		#conn = ConnectionSPARQL.new
		#tri.each do | t |
		#	logger.info t
		#	q = query.delete(graph, t)
		#	data = conn.runDelete(q)
		#end


		respond_with(@ret)
	end

	def insertTriples
		graph = params[:graph]
		arq = FileArray.new
		graphArq = graph.gsub('.com', '')
		graphArq = graphArq.gsub('http://', '')
		graphArq = graphArq.gsub('www.', '')
		graphArq = graphArq.gsub('.br', '')
		graphArq = graphArq.gsub('.org', '')
		graphArq = graphArq.gsub('.net', '')
		graphArq = graphArq.gsub('.edu', '')

		# nome do arquivo ==> grafo+criterio+leveinstein.txt
		# criterio: 1 -> nome do autor
		# criterio: 2 -> nome do artigo
		# criterio: 3 -> nome do artigo + ano
		case params[:rules]
			when '1' then
				graphArq = graphArq+params[:rules]+params[:name_author_lev].to_s.gsub('.', '')
			when '2' then
				graphArq = graphArq+params[:rules]+(params[:name_article_lev].to_s.gsub('.', ''))+(values[:name_author_tri].to_s.gsub('.', ''))
			when '3' then
				graphArq =  graphArq+params[:rules]+(params[:name_article_lev].to_s.gsub('.', ''))
		end

		logger.info graphArq

		tri = arq.readArqTriples(graphArq+'.nt')

		# =========
		# STEP 6 - Store Triples
		# =========
		query = Query.new
		conn = ConnectionSPARQL.new
		tri.each do | trip |
			logger.info "inserindo "+trip
			q = query.insert(graph, trip)
			data = conn.runInsert(q)
		end

		respond_with(ret = true)
	end

	def deleteTriples
		graph = params[:graph]
		arq = FileArray.new
		graphArq = graph.gsub('.com', '')
		graphArq = graphArq.gsub('http://', '')
		graphArq = graphArq.gsub('www.', '')
		graphArq = graphArq.gsub('.br', '')
		graphArq = graphArq.gsub('.org', '')
		graphArq = graphArq.gsub('.net', '')
		graphArq = graphArq.gsub('.edu', '')

		# nome do arquivo ==> grafo+criterio+leveinstein.txt
		# criterio: 1 -> nome do autor
		# criterio: 2 -> nome do artigo
		# criterio: 3 -> nome do artigo + ano
		case params[:rules]
			when '1' then
				graphArq = graphArq+params[:rules]+params[:name_author_lev].to_s.gsub('.', '')
			when '2' then
				graphArq = graphArq+params[:rules]+params[:name_article_lev].to_s.gsub('.', '')
			when '3' then
				graphArq =  graphArq+params[:rules]+(params[:name_article_lev].to_s.gsub('.', ''))
		end

		tri = arq.readArqTriples(graphArq+'.nt')


		# =========
		# STEP 6 - Store Triples
		# =========
		query = Query.new
		conn = ConnectionSPARQL.new
		tri.each do | t |
			logger.info "deletando "+t
			q = query.delete(graph, t)
			data = conn.runDelete(q)
		end

		respond_with(ret = true)
	end

	def validateResult
		graph = params[:graph]

		values = Hash.new
		values['graph'] = params[:graph]
		values['vd'] = params[:vd]
		values['name_author'] = params[:name_author]
		values['name_author_lev'] = params[:name_author_lev]
		values['name_author_tri'] = params[:name_author_tri]
		values['name_article'] = params[:name_article]
		values['name_article_lev'] = params[:name_article_lev]
		values['name_conference'] = params[:name_conference]
		values['name_conference_lev'] = params[:name_conference_lev]
		values['rank'] = params[:rank]
		values['year'] = params[:year]
		values['rules'] = params[:rules]


		arq = FileArray.new
		graphArq = graph.gsub('.com', '')
		graphArq = graphArq.gsub('http://', '')
		graphArq = graphArq.gsub('www.', '')
		graphArq = graphArq.gsub('.br', '')
		graphArq = graphArq.gsub('.org', '')
		graphArq = graphArq.gsub('.net', '')
		graphArq = graphArq.gsub('.edu', '')

		# nome do arquivo ==> grafo+criterio+leveinstein.txt
		# criterio: 1 -> nome do autor
		# criterio: 2 -> nome do artigo
		# criterio: 3 -> nome do artigo + ano
		case values['rules']
			when '1' then
				graphArq = graphArq+values['rules']+values['name_author_lev'].to_s.gsub('.', '')
			when '2' then
				graphArq = graphArq+values['rules']+(values['name_article_lev'].to_s.gsub('.', ''))+values['rules']+(values['name_article_lev'].to_s.gsub('.', ''))+(values['name_author_lev'].to_s.gsub('.', ''))+(values['name_author_tri'].to_s.gsub('.', ''))
			when '3' then
				graphArq = graphArq+values['rules']+(values['name_article_lev'].to_s.gsub('.', ''))+values['rules']+(values['name_author_lev'].to_s.gsub('.', ''))+(values['name_author_tri'].to_s.gsub('.', ''))
		end

		situacao1 = 0			# IGUAL
		situacao2 = 0			# TRIGRAM E RANK
		situacao3 = 0			# TRIGRAM
		situacao4 = 0			# RANK
		situacao5 = 0			# NADA

		situacao1erros = 0
		situacao2erros = 0
		situacao3erros = 0
		situacao4erros = 0
		situacao5erros = 0

		media = Hash.new
		media['geral'] = []
		media['situacao1'] = []
		media['situacao2'] = []
		media['situacao3'] = []
		media['situacao4'] = []
		media['situacao5'] = []

		total 	= 0			# TOTAL = CERTOS+ERRADOS (TOTAL DE PAREAMENTOS)
		certos 	= 0			# QUANTIDADE DE CASAMENTOS CERTOS QUE TEM NA BASE
		errados = 0			# QUANTIDADE DE CASAMENTOS ERRADOS QUE TEM NA BASE
		acertou	= 0			# ACERTOS BASEADO NA ETIQUETAGEM
		errou 	= 0			# ERROS BASEADO NA ETIQUETAGEM
		logger.info graphArq
		result = arq.readArq(graphArq+"-result.txt")
		result.each do | res |
			total = total+res.size
		end

		if(File.exist?("gaci3004-etiquetation.txt") == true) then
			etiquetation = arq.readArq("gaci3004-etiquetation.txt")

			etiquetation.zip(result).each do | et, res |

				et.zip(res).each do | a, b |

					media['geral'].push(b[2])
					#logger.info "#{b[0][3] } <==> #{b[1][3]}"
					#logger.info "#{b[2]}"
					# verifica valor real entre certos e errados
					# ou seja quantos casamentos certos eu tenho e quantos errados
					if(a['et'] == 1) then
						certos = certos+1
					else
						errados = errados+1
					end

					if(a['et'] == b[3]) then
						acertou = acertou+1
					else
						errou = errou+1
					end

					#SITUACAO 1
					if( b[3] == 1 and b[4] == 1 ) then
						media['situacao1'].push(b[2])
						situacao1 = situacao1+1
						if( b[3] != a['et']) then
							situacao1erros=situacao1erros+1
							#tri = Trigram.compare(a[0][3], a[1][3])
							#logger.info "#{tri}"
							#logger.info "SITUACAO 4"
							#logger.info "#{b[0][3] } <==> #{b[1][3]}"
							#logger.info "SITUACAO 4 ERRADA"
							#logger.info "#{b[0][3] } <==> #{b[1][3]}"
							#logger.info "#{b[0][2] } <==> #{b[1][2]}"

						end
					end
					#SITUACAO 2
					if( b[3] == 1 and b[4] == 2 ) then
						media['situacao2'].push(b[2])
						situacao2 = situacao2+1
						if( b[3] != a['et']) then
							#logger.info "SITUACAO 2"
							#logger.info "#{b[3]} #{a['et']}"
							logger.info "#{b[0][3] } <==> #{b[1][3]}"
							tri = Trigram.compare(a[0][3], a[1][3])
							logger.info "#{tri}"
							#logger.info "#{b[0][2] } <==> #{b[1][2]}"
							situacao2erros=situacao2erros+1
						end
					end
					#SITUACAO 3
					if( b[3] == 1 and b[4] == 3 ) then
						media['situacao3'].push(b[2])
						situacao3 = situacao3+1

						if( b[3] != a['et']) then
							situacao3erros=situacao3erros+1
							#logger.info "SITUACAO 3 ERRADA"
							#logger.info "#{b[3]} #{a['et']}"
							logger.info "#{b[0][3] } <==> #{b[1][3]}"
							#logger.info "#{b[0][2] } <==> #{b[1][2]}"
							#tri = Trigram.compare(a[0][3], a[1][3])
							#logger.info "#{tri}"
							tri = Trigram.compare(a[0][3], a[1][3])
							logger.info "#{tri}"
							#logger.info "SITUACAO 3"
							#logger.info "#{b[0][3] } <==> #{b[1][3]}"
							#logger.info "#{b[0][2] } <==> #{b[1][2]}"
						end
					end
					#SITUACAO 4
					if( b[3] == 0 and b[4] == 4 ) then
						media['situacao4'].push(b[2])
						situacao4 = situacao4+1
						if( b[3] != a['et']) then
							situacao4erros=situacao4erros+1
							#tri = Trigram.compare(a[0][3], a[1][3])
							#logger.info "#{tri}"
							#logger.info "SITUACAO 4"
							#logger.info "#{b[0][3] } <==> #{b[1][3]}"
							#logger.info "SITUACAO 4 ERRADA"
							#logger.info "#{b[0][3] } <==> #{b[1][3]}"
							#logger.info "#{b[0][2] } <==> #{b[1][2]}"

						end
						#logger.info "SITUACAO 4"
						#logger.info "#{b[0][3] } <==> #{b[1][3]}"
					end
					#SITUACAO 5
					if( b[3] == 0 and b[4] == 5 ) then
						media['situacao5'].push(b[2])
						if( b[3] != a['et']) then
							situacao5erros = situacao5erros+1
							#tri = Trigram.compare(a[0][3], a[1][3])
							#logger.info "#{tri}"
							#logger.info "SITUACAO 5"
							#logger.info "#{b[0][3] } <==> #{b[1][3]}"
						end
						situacao5 = situacao5+1
					end
				end


			end

		else
			result.each do | res |
				res.each do | b |
					media['geral'].push(b[2])
					#SITUACAO 1
					if( b[3] == 1 and b[4] == 1 ) then
						media['situacao1'].push(b[2])
						situacao1 = situacao1+1
					end
					#SITUACAO 2
					if( b[3] == 1 and b[4] == 2 ) then
						media['situacao2'].push(b[2])
						situacao2 = situacao2+1
					end
					#SITUACAO 3
					if( b[3] == 1 and b[4] == 3 ) then
						media['situacao3'].push(b[2])
						situacao3 = situacao3+1
						#logger.info "#{b[0][2] } <==> #{b[1][2]}"
					end
					#SITUACAO 4
					if( b[3] == 0 and b[4] == 4 ) then
						media['situacao4'].push(b[2])
						situacao4 = situacao4+1
						#tri = Trigram.compare(b[0][3], b[1][3])
						#if(tri < 0.5 and tri > 0.3)
						#	logger.info "SITUACAO 4 ERRADA"
						#	logger.info "#{tri}"
						#	logger.info "#{b[0][3] } <==> #{b[1][3]}"
						#end
						#logger.info "SITUACAO 4"
						#logger.info "#{b[0][3] } <==> #{b[1][3]}"
					end
					#SITUACAO 5
					if( b[3] == 0 and b[4] == 5 ) then
						media['situacao5'].push(b[2])
						#logger.info "SITUACAO 5"
						#logger.info "#{b[0][3] } <==> #{b[1][3]}"
						situacao5 = situacao5+1

					end
				end
			end
		end

		logger.info " LOG DE DESAMBIGUAÇÃO"
		logger.info "============================"
		logger.info " Nivel de Levenshtein: #{values['name_author_lev']}"
		logger.info " Total de Trigram: #{values['name_author_tri']}"
		logger.info " Total de Casamentos: #{total}"
		logger.info " Total de certos: #{certos}"
		logger.info " Total de Errados: #{errados}"
		logger.info " Total de Acertos: #{acertou}"
		logger.info " Total de Erros: #{errou}"
		logger.info " --- SITUAÇÕES"
		logger.info "================"
		logger.info "SITUAÇÃO 1 - IGUAL		= #{situacao1} ERROS: #{situacao1erros}"
		logger.info "SITUAÇÃO 2 - TRIGRA  + RANK	= #{situacao2} ERROS: #{situacao2erros}"
		logger.info "SITUAÇÃO 3 - TRIGRA		= #{situacao3} ERROS: #{situacao3erros}"
		logger.info "SITUAÇÃO 4 - RANK 		= #{situacao4} ERROS: #{situacao4erros}"
		logger.info "SITUAÇÃO 5 - ERRADOS		= #{situacao5} ERROS: #{situacao5erros}"
		logger.info "========================================================="
		logger.info "========================================================="
		logger.info "========================================================="

		mg = 0

		logger.info "================"
		media['geral'].each do | m |
			mg = mg+m
			#logger.info "#{m}"
		end
		logger.info "================"
		mediageral = mg/media['geral'].size
		logger.info "MEDIA GERAL 	= #{mediageral}	=== 	Tam: #{media['geral'].size}"
		#logger.info "#{media['geral'].minmax}"

		## ============

		st1 = 0
		media['situacao1'].each do | s |
			st1 = st1+s
			#logger.info "#{s}"
		end
		logger.info "================"
		sit1 = st1/media['situacao1'].size
		logger.info "SITUACAO 1 	= #{sit1}		=== 	Tam: #{media['situacao1'].size}"
		logger.info "#{media['situacao1'].minmax}"
		#=============

		st2 = 0
		media['situacao2'].each do | s |
			st2 = st2+s
			#logger.info "#{s}"
		end
		logger.info "================"
		sit2 = st2/media['situacao2'].size
		logger.info "SITUACAO 2 	= #{sit2}		=== 	Tam: #{media['situacao2'].size}"
		logger.info "#{media['situacao2'].minmax}"
		#=============

		st3 = 0
		media['situacao3'].each do | s |
			st3 = st3+s
			#logger.info "#{s}"
		end
		sit3 = st3/media['situacao3'].size


		logger.info "================"
		logger.info "SITUACAO 3 	= #{sit3} 	=== 	Tam: #{media['situacao3'].size}"
		logger.info "#{media['situacao3'].minmax}"


		#=============

		st4 = 0
		media['situacao4'].each do | s |
			st4 = st4+s
			#logger.info "#{s}"
		end
		logger.info "================"
		sit4 = st4/media['situacao4'].size
		logger.info "SITUACAO 4 	= #{sit4}		=== 	Tam: #{media['situacao4'].size}"
		logger.info "#{media['situacao4'].minmax}"
		#==============


		st5 = 0
		media['situacao5'].each do | s |
			st5 = st5+s
			#logger.info "#{s}"
		end
		logger.info "================"
		sit5 = st5/media['situacao5'].size
		logger.info "SITUACAO 5 	= #{sit5} 	=== 	Tam: #{media['situacao5'].size}"
		logger.info "#{media['situacao5'].minmax}"
		#==============
		logger.info "========================================================="



		respond_with (@ret = true)
	end


	def navigation
		 lev = Trigram.compare("vinicius-n-possani", "vinicius-callegaro")
		 logger.info lev

		 tri = Trigram.compare("juliano-lucas-goncalve", "robson-goncalves")
		 logger.info tri

		 tri = Trigram.compare("ivan-saraiva", "ivan-silva")
		 logger.info tri
	end

	def getProfiles
		graph = params[:graph]
		nameProfile = params[:nameProfile]
		logger.info graph
		logger.info nameProfile

		query = Query.new
		queryProfiles  = query.getProfiles(graph, nameProfile)
		c = ConnectionSPARQL.new
		data = c.runQuery(queryProfiles)

		parse =  Normalize.new
		profiles = parse.normalizeProfiles(data, 0, 0, 1)
		respond_with(profiles)
	end
end