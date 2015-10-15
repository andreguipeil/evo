class Query

	def selectArticles(graph)
		graph = graph.gsub(' ', '')
		query = "
			SELECT DISTINCT ?refBy ?article ?nameArticle ?nameConference ?year ?nodeAuthor2 (xsd:integer(?rank)) as ?rank ?name
			FROM <"+graph+">
			WHERE {
			    ?article a bibo:AcademicArticle .
			    ?article dcterms:issued ?year .
			    ?article dc:title ?nameArticle .
			    ?article bibo:presentedAt ?conference .
			    ?article dcterms:isReferencedBy ?refBy .
			    ?conference dc:title ?nameConference .
                            	    ?article vivo:relatedBy ?nodeAuthor .
                            	    ?nodeAuthor vivo:relates ?nodeAuthor2 .
                            	    ?nodeAuthor vivo:rank ?rank .
                            	    ?nodeAuthor2 rdfs:label ?name .
                            	FILTER (!regex(str(?nodeAuthor2), str(\"-i\"))).

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

	def delete (graph, triples)
		del = '
			DELETE FROM <'+graph+'> {'+triples+'}'
		return del
	end


end