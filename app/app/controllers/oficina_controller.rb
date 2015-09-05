require 'net/http'
require 'cgi'
require 'csv'
require 'rubygems'
require 'active_support/all'
require "thread"
require "json"

require "Query"
require "ConnectionSPARQL"
require "Desambiguation"
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

		graph = RDF::Graph.new

		logger.info RDF.type
		logger.info RDF::RDFS.label
		logger.info RDF::OWL.NamedIndividual

		disambiguation = RDF::Vocabulary.new("http://vivoext.org/")
		logger.info disambiguation.pair+"#value_disambiguation"
		sames1 = []
		sames2 = []
		sames3 = []

		sames1.push("http://ufpel.edu.br/lattes/0702035357125121#author-idp5985904")
		sames1.push("http://ufpel.edu.br/lattes/2809172806147764#author-idp21609248")
		sames2.push("http://ufpel.edu.br/lattes/6927803856702261#author-6927803856702261")
		sames2.push("http://ufpel.edu.br/lattes/0702035357125121#author-idp6009760")
		sames3.push("http://ufpel.edu.br/lattes/0702035357125121#author-idp6000096")
		sames3.push("http://ufpel.edu.br/lattes/0741704260227015#author-idp12601472")

		logger.info disambiguation.pair
		cont = 0
		graph << [disambiguation.pair+"#has_dis-00"+cont, RDF.type, disambiguation.pair]
		sames1.each do | same |
			cont=+1
		end





		foaf = RDF::Vocabulary.new("http://xmlns.com/foaf/0.1/")
		logger.info foaf.knows    #=> RDF::URI("http://xmlns.com/foaf/0.1/knows")
		logger.info foaf[:name]   #=> RDF::URI("http://xmlns.com/foaf/0.1/name")
		logger.info foaf['mbox']  #=> RDF::URI("http://xmlns.com/foaf/0.1/mbox")


		RDF::Writer.for(:ntriples)     #=> RDF::NTriples::Writer
		RDF::Writer.for("output.nt")
		RDF::Writer.for(:file_name      => "output.nt")
		RDF::Writer.for(:file_extension => "nt")
		RDF::Writer.for(:content_type   => "text/plain")

		#graph = RDF::Graph.new << [:hello, RDF::DC.title, "Hello, world!"]
		graph.dump(:ntriples)

		RDF::Writer.open("hellou.nt") { |writer| writer << graph }

		RDF::Writer.open("hello.nq", :format => :nquads) do |writer|
		  writer << RDF::Repository.new do |repo|
		    repo << RDF::Statement.new(:hello, RDF::DC.title, "Hello, world!", :context => RDF::URI("context"))
		  end
		end



		repo = RDF::Repository.new << RDF::Statement.new(:hello, RDF::DC.title, "Hello, world!", :context => RDF::URI("context"))
		File.open("hello.nq", "w") {|f| f << repo.dump(:nquads)}

		# =========
		# STEP 1 - importing RDF data information
		# =========
		#query = Query.new
		#q1 = query.selectCoauthors("http://laropa.com")
		#q2 = query.selectAuthors("http://laropa.com")

		#c = ConnectionSPARQL.new
		#data = c.runQuery(q1["query"])		# recebe os dados vindos do virtuoso coauthores
	       	#data2 = c.runQuery(q2["query"])		# recebe os dados vindos do virtuoso authores

		# =========
		# STEP 2 - normalization of names and articles
		# =========

		# faz a contagem do campos
		#parse =  Normalize.new
		#tempData1 = parse.csvToArray(data, q1["cont"])	# transforma de csv para array para facilitar a manipulacao
		#tempData2 = parse.csvToArray(data2, q2["cont"])	# transforma de csv para array para facilitar a manipulacao

		#@triples = tempData1 + tempData2 			# merge coAutores e Autores

		# =========
		# STEP 3 - create similar articles block's
		# =========

		#entities = Entity.new					#
		#semanticBlock = entities.createEntities(@triples)	# cria os blocos semânticos com a distancia de leivinstein

		# =========
		# STEP 4 - load info quickly
		# =========
		#arq = FileArray.new
		#arq.createArq(semanticBlock, "laropa.txt")		# cria arquivo e insere os blocos semanticos
		#entitiesTemp = arq.readArq("laropa.txt")		# carrega os blocos semanticos

		# =========
		# STEP 5 - Desambiguation
		# =========
		#des = Desambiguation.new
		#des.desambiguationEntities(entitiesTemp)


 		#@ret = Hash.new
 		#@ret["triples"] = @triples
 		#@ret["cont"] = cont
 		#@ret["article"] = @triples
		#@ret["cont"] = 5

		#logger.info @ret
		respond_with(@ret)
	end


	def desambiguar
		values = Hash.new
		graph = params[:graph]
		values['vd'] = params[:vd]
		values['nameArticle'] = params[:nameArticle]
		values['rank'] = params[:rank]
		values['conference'] = params[:conference]
		values['year'] = params[:year]


		graphArq = graph.gsub('.com', '')
		graphArq = graphArq.gsub('http://', '')
		graphArq = graphArq.gsub('www.', '')
		graphArq = graphArq.gsub('.br', '')
		graphArq = graphArq.gsub('.org', '')
		graphArq = graphArq.gsub('.net', '')
		graphArq = graphArq.gsub('.edu', '')
		graphArq+='.txt'

		if(File.exist?(graphArq) != true) then
			# =========
			# STEP 1 - importing RDF data information
			# =========
			query = Query.new
			q1 = query.selectCoauthors(graph)
			q2 = query.selectAuthors(graph)

			c = ConnectionSPARQL.new
			data = c.runQuery(q1["query"])				# recebe os dados vindos do virtuoso coauthores
		       	data2 = c.runQuery(q2["query"])			# recebe os dados vindos do virtuoso authores

			# =========
			# STEP 2 - normalization of names and articles
			# =========

			# faz a contagem do campos
			parse =  Normalize.new
			tempData1 = parse.csvToArray(data, q1["cont"])	# transforma de csv para array para facilitar a manipulacao
			tempData2 = parse.csvToArray(data2, q2["cont"])	# transforma de csv para array para facilitar a manipulacao

			triples = tempData1 + tempData2 			# merge coAutores e Autores

			# =========
			# STEP 3 - create similar articles block's
			# =========

			entities = Entity.new					#
			semanticBlock = entities.createEntities(triples)		# cria os blocos semânticos com a distancia de leivinstein

			# =========
			# STEP 4 - load info quickly
			# =========
			arq = FileArray.new

			arq.createArq(semanticBlock, graphArq)		# cria arquivo e insere os blocos semanticos
			entitiesTemp = arq.readArq(graphArq)			# carrega os blocos semanticos

		else
			# =========
			# STEP 4 - load info quickly
			# =========
			arq = FileArray.new
			entitiesTemp = arq.readArq(graphArq)			# carrega os blocos semanticos

		end
		# =========
		# STEP 5 - Desambiguation
		# =========
		des = Desambiguation.new
		des.desambiguationEntities(entitiesTemp, values)

		respond_with(@ret)
	end
end