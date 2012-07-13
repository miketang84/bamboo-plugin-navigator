module(..., package.seeall)

bamboo.plugindata.navigator = {}

------------------------------------------------------------------------
local function parse(tbl)
	checkType(tbl, 'table')
	
	for _, v in ipairs(tbl) do
		assert(not tbl[v.name], '[Error] duplicated name string in Site Map')
		tbl[v.name] = v
		v.title  = v.title or v.name or ''
	end
	
	-- push to URLs
	for i, v in ipairs(tbl) do
		-- v.pathkey is the generated url path for each site map element
		-- v.rank indicate the rank of current element item
		local k = v.name
		if v.parent then
			assert(tbl[v.parent], ('[Error] No this parent in registerSiteMap at %s %s.'):format(k, v.parent))
			v.pathkey = v.url or (tbl[v.parent].pathkey or '/') + k + '/'
			v.rank = (tbl[v.parent].rank  or 1) + 1 
		else
			v.pathkey = v.url or '/' + k + '/'
			v.rank = 1
		end
		
	end

	return tbl
end


-- to return a html fragment, which was constructed with ul and li
-- with specified id name and class name, for page rendering
-- This algorithm only supports closest arrange method.
function makeNavigator(site_map)
	local navi_htmls = '<ul class="bamboo_navigator">'
	
	if #site_map > 0 then
		navi_htmls = navi_htmls + ([[<li class="%s cur_navi"><a href="%s">%s</a>]]):format(site_map[1].name, site_map[1].pathkey, site_map[1].title)
	end
	i = 2
	while i <= #site_map do
		local cur_item = site_map[i]
		local prev_item = site_map[i-1]
		if cur_item.rank == prev_item.rank then
			navi_htmls = navi_htmls + ([[</li><li class="%s"><a href="%s">%s</a>]]):format(cur_item.name, cur_item.pathkey, cur_item.title)
		elseif cur_item.rank > prev_item.rank then
			navi_htmls = navi_htmls + ([[<ul class="%s_rank%s"><li class="%s"><a href="%s">%s</a>]]):format(cur_item.parent, cur_item.rank, cur_item.name, cur_item.pathkey, cur_item.title)
		elseif cur_item.rank < prev_item.rank then
			navi_htmls = navi_htmls + '</li>'
			delta = prev_item.rank - cur_item.rank
			for n = 1, delta do
				navi_htmls = navi_htmls + '</ul></li>'
			end
			navi_htmls = navi_htmls + ([[<li class="%s"><a href="%s">%s</a>]]):format(cur_item.name, cur_item.pathkey, cur_item.title)
		end
		
		i = i + 1
	end
	
	if site_map[#site_map].rank > 1 then
		local delta = site_map[#site_map].rank - 1
		navi_htmls = navi_htmls + string.rep('</li></ul>',  delta)
	end
	
	if navi_htmls then navi_htmls = navi_htmls + '</li>' end
	navi_htmls = navi_htmls + '</ul>'
	
	-- print(navi_htmls)
	return navi_htmls
end

local function fixCurNavi(tmpl, cur_navi)
	local ostarti, oendi, starti, endi, old_nav
	ostarti, oendi, old_nav = tmpl:find('class="([%w_]+) cur_navi"')
	starti, endi = tmpl:find(format('class="%s"', cur_navi))
	if not starti then
		return tmpl
	else
		return tmpl:sub(1, ostarti-1)..format('class="%s"', old_nav)..tmpl:sub(oendi+1, starti-1)..
				format('class="%s cur_navi"', cur_navi)..tmpl:sub(endi+1, -1)
	end
	
	return tmpl
end


--[[

{^ navigator datasource = {
	{ name="", title="", url='', },
	{ parent="", name="", title="", url='', },
	

}, cur_navi = cur_navi

^}


--]]

function main(args, env)
	assert(args._tag, '[Error] @plugin navigator - missing _tag.')
	assert(args.datasource, '[Error] @plugin navigator - missing datasource.')
	assert(args.cur_navi, '[Error] @plugin navigator - missing cur_navi.')

	local tmpl = ''
	if bamboo.config.PRODUCTION and bamboo.plugindata.navigator[args._tag] then
		tmpl = bamboo.plugindata.navigator[args._tag]
	else
		tmpl = makeNavigator(parse(args.datasource))
		bamboo.plugindata.navigator[args._tag] = tmpl
	end

	return fixCurNavi(tmpl, args.cur_navi)
end
