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
				graphArq = graphArq+values['rules']+values['name_article_lev'].to_s.gsub('.', '')
			when '3' then
				graphArq = graphArq+values['rules']+values['name_article_lev'].to_s.gsub('.', '')
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
			entitySames = dis.disambiguationByNameAuthor(authorsTemp, values, profilesTemp, articlesTemp)
		when '2' then
			# entitySames = dis.disambiguationByArticleYear(authorsTemp, values)
			entitySamesNoGap = dis.disambiguationByArticleNoGap(authorsTemp, values)
			entitySamesWithGap = dis.disambiguationByArticleWithGap(authorsTemp, values)
			#etiquetation = dis.etiquetationByArticle(authorsTemp)
		when '3' then
			entitySamesNoGap = dis.disambiguationByArticleNoGap(authorsTemp, values)
			entitySamesWithGap = dis.disambiguationByArticleWithGap(authorsTemp, values)
			#etiquetation = dis.etiquetationByArticle(authorsTemp)
			# entitySames = dis.disambiguationByArticleYear(authorsTemp, values)
		end
		#triples = dis.createTriples(entitySames, graphArq+'.nt')			#cria as triplas em um arquivo .nt
		#tri = arq.readArqTriples(graphArq+'.nt')
		#arq.createArq(etiquetation, graphArq+"-etiquetation.txt")
		arq.createArq(entitySamesNoGap, graphArq+"nogap-result.txt")
		arq.createArq(entitySamesWithGap, graphArq+"withgap-result.txt")


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
				graphArq = graphArq+params[:rules]+params[:name_article_lev].to_s.gsub('.', '')
			when '3' then
				graphArq = graphArq+params[:rules]+params[:name_article_lev].to_s.gsub('.', '')
		end

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
				graphArq = graphArq+params[:rules]+params[:name_article_lev].to_s.gsub('.', '')
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
				graphArq = graphArq+values['rules']+values['name_article_lev'].to_s.gsub('.', '')
			when '3' then
				graphArq = graphArq+values['rules']+values['name_article_lev'].to_s.gsub('.', '')
		end


		#logger.info graphArq+"-etiquetation.txt"
		#if(File.exist?(graphArq+"-etiquetation.txt") == true) then
			etiquetation = arq.readArq("laburb-etiquetation.txt")
			resultnogap = arq.readArq(graphArq+"nogap-result.txt")
			resultwithgap = arq.readArq(graphArq+"withgap-result.txt")
		#else
			#logger.info "aqui no etiquetation false"
			#return respond_with(false);
		#end


		logger.info " NO GAP"
		logger.info " ==============================="
		acertos_total = 0
		erros_total = 0
		etiquetation.zip(resultnogap).each do | et, res |
			acertos = 0
			erros = 0
			et.zip(res).each do | a, b |
				if(a['et'] == b[3]) then
					acertos = acertos+1
				else
					erros = erros+1
				end
			end
			logger.info acertos
			logger.info erros
			logger.info " -- "
			acertos_total = acertos_total+acertos
			erros_total = erros_total+erros
		end
		logger.info acertos_total
		logger.info erros_total

		logger.info " ==============================="


		logger.info " WITH GAP"
		logger.info " ==============================="
		acertos_total = 0
		erros_total = 0
		etiquetation.zip(resultwithgap).each do | et, res |
			acertos = 0
			erros = 0
			et.zip(res).each do | a, b |
				if(a['et'] == b[3]) then
					acertos = acertos+1
				else
					erros = erros+1
				end
			end
			logger.info acertos
			logger.info erros
			logger.info " -- "
			acertos_total = acertos_total+acertos
			erros_total = erros_total+erros
		end
		logger.info acertos_total
		logger.info erros_total

		logger.info " ==============================="


		#result.each do | res |
		#	logger.info res.size
		#end


		#@ret['etiquetation'] = etiquetation
		#@ret['result'] = result
		respond_with (@ret = true)
	end









	def navigation
		graph = params[:graph0]+":"+params[:graph1]
		q = Query.new
		query = q.navigation(graph)
		c = ConnectionSPARQL.new
		data = c.runQuery(query)

		arq = FileArray.new

		logger.info graph

		graphArq = graph.gsub('.com', '')
		graphArq = graphArq.gsub('http://', '')
		graphArq = graphArq.gsub('www.', '')
		graphArq = graphArq.gsub('.br', '')
		graphArq = graphArq.gsub('.org', '')
		graphArq = graphArq.gsub('.net', '')
		graphArq = graphArq.gsub('.edu', '')
		profilesTemp = arq.readArqProfiles(graphArq+'-profiles.txt')
		contPesquisadores = profilesTemp.size
		config = arq.readArqConfig(graphArq+"-config.txt")
		logger.info config


		@send = Hash.new
		@send['graph'] = graph
		@send['researchers'] = contPesquisadores
		if(contPesquisadores < 20) then
			@send['profiles'] = profilesTemp.sort{|a,b| a['name']<=>b['name']}
		end

		respond_with(@send)


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