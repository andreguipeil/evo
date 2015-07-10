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


end
