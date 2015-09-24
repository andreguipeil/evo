module OficinaHelper

	def table_generate(content, collumn)

		ret = "
				<div class=\"table-responsive\">
				<table id=\"table_main\" class=\"table table-striped\">
				<tr>"
				cont = 0
				collumn.times{
					ret   +=  "<th>collumn #{cont+1}</th>"
					cont += 1
				}
				ret += "</tr>"

				cont = 0
				content.each do |row|
					ret += "<tr>"
					collumn.times{
						ret += "<td>#{row[cont]}</td>"
						cont += 1
					}
					cont = 0
					ret += "</tr>"
				 end
			ret += "</table>
				</div>"
		 ret.html_safe
	end

	def generate_table_authors( profiles )
		ret = "
			<table id='listProfiles' class='table table-striped table-hover'>

		      	<thead>
		        		<tr>
	          				<th id='col1' class='text-left'> Indice </th>
	          				<th id='col2' class='text-left'> Pesquisadores </th>
	        			</tr>
	      		</thead>
	      		<tbody>
		"
		      	cont = 0
			profiles.each do | pro |
				ret += "<tr>"
		      		ret +=	"<td  id='id' class='text-left'>#{cont+1}</td>"
		      		ret +=	"<td  id='name' class='text-left'>#{pro['name']}</td>"
		      		ret +=	"<td  id='refBy' class='text-left' style='display:none;'>#{pro['refBy']}</td>"
		      		ret += "</tr>"
		      		cont = cont+1
		      	end

		ret+="
			</tbody>
		</table>
		"
		ret.html_safe
	end

end
