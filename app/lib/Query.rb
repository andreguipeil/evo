class Query

	def selectArticles(graph)
		graph = graph.gsub(' ', '')
		query = "
			SELECT DISTINCT ?refBy ?article ?nameArticle ?nameConference ?year
			FROM <"+graph+">
			WHERE {
			    ?article a bibo:AcademicArticle .
			    ?article dcterms:issued ?year .
			    ?article dc:title ?nameArticle .
			    ?article bibo:presentedAt ?conference .
			    ?article dcterms:isReferencedBy ?refBy .
			    ?conference dc:title ?nameConference .

			} ORDER BY ?refBy ?article"
		return query
	end

	def selectAuthors (graph)
		graph = graph.gsub(' ', '')
		query = "
			SELECT ?refBy ?article ?nodeAuthor2 ?name (xsd:integer(?rank)) as ?rank ?nameArticle ?nameConference ?year
			FROM <"+graph+">
			WHERE {
			    ?article a bibo:AcademicArticle .
			    ?article dcterms:issued ?year .
			    ?article dc:title ?nameArticle .
			    ?article vivo:relatedBy ?nodeAuthor .
			    ?article bibo:presentedAt ?conference .
			    ?article dcterms:isReferencedBy ?refBy .
			    ?conference dc:title ?nameConference .
			    ?nodeAuthor vivo:relates ?nodeAuthor2 .
			    ?nodeAuthor vivo:rank ?rank .
			    ?nodeAuthor2 rdfs:label ?name .

			} ORDER BY ?refBy ?article ?rank"

		first, *rest = query.split(/FROM/) 		# pega os campos dinamicamente
		cont = first.scan("?").count-1
		authors = Hash.new
		authors["query"] = query
		authors["cont"] = cont
		return authors
	end

	def selectProfiles (graph)
		graph = graph.gsub(' ', '')
		queryGivenName = "
			SELECT DISTINCT ?refBy ?givenName
				FROM <"+graph+">
				WHERE {
				    ?refBy bibo:identifier ?id .
				    ?refBy dc:creator ?personCreator .
				    ?personCreator obo:ARG_2000028 ?nodeName .
				    ?nodeName vcard:hasName ?nameName .
				    ?nameName vcard:givenName ?givenName .

				    FILTER (regex(str(?nodeName), str(\"#i\"))).
				}"

		queryFamilyName = "
			SELECT DISTINCT ?refBy ?familyName
			FROM <"+graph+">
			WHERE {
			    ?refBy bibo:identifier ?id .
			    ?refBy dc:creator ?personCreator .
			    ?personCreator obo:ARG_2000028 ?nodeName .
			    ?nodeName vcard:hasName ?nameName .
			    ?nameName vcard:familyName ?familyName .

			    FILTER (regex(str(?nodeName), str(\"#i\"))).
			}"

		queryProfileName = "
			SELECT DISTINCT ?refBy ?realName
			FROM <"+graph+">
			WHERE {
			    ?refBy bibo:identifier ?id .
			    ?refBy dc:creator ?personCreator .
			    ?personCreator obo:ARG_2000028 ?nodeName .
			    ?nodeName vcard:hasName ?nameName .
			    ?nameName vcard:fn ?realName .
			}"

		profiles = Hash.new
		profiles["queryGivenName"] = queryGivenName
		profiles["queryFamilyName"] = queryFamilyName
		profiles["queryProfileName"] = queryProfileName

		return profiles
	end

	def getProfiles(graph, name)
		queryProfileName = "
			SELECT DISTINCT ?refBy ?realName
			FROM <"+graph+">
			WHERE {
			    ?refBy bibo:identifier ?id .
			    ?refBy dc:creator ?personCreator .
			    ?personCreator obo:ARG_2000028 ?nodeName .
			    ?nodeName vcard:hasName ?nameName .
			    ?nameName vcard:fn ?realName .
			    FILTER (regex(str(?realName), str(\"#{name}\"))).
			}"

		return queryProfileName
	end

	def insert (graph, triples)
		ins = '
		 INSERT DATA INTO GRAPH <'+graph+'> { '+triples+' }'
		return ins
	end

	def delete (graph)
	end

	def navigation (graph)
		graph = graph.gsub(' ', '')
		nav = "
		SELECT DISTINCT ?dis ?o ?name ?vd
		FROM <"+graph+">
		WHERE {

		   ?dis pair:has_dis ?o .
		   ?o pair:value_disambiguation ?vd .
		   ?dis rdfs:label ?name .


		   FILTER (str(?dis) != str(\"http://ufpel.edu.br/lattes/6927803856702261#author-6927803856702261\"))
		   FILTER (?vd > 3).
		} order by ?o"
		return nav
	end

end